"""
Tests for document endpoints:
  POST   /api/v1/documents/upload
  GET    /api/v1/documents/
  GET    /api/v1/documents/{id}
  DELETE /api/v1/documents/{id}
"""

import io
import os
import pytest
from pathlib import Path


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────


def _upload_pdf(
    client, auth_headers, filename: str = "test.pdf", content: bytes = b"%PDF-1.4 test"
) -> dict:
    """Helper: upload a PDF and return the response JSON."""
    resp = client.post(
        "/api/v1/documents/upload",
        files={"file": (filename, io.BytesIO(content), "application/pdf")},
        headers=auth_headers,
    )
    return resp


# ─────────────────────────────────────────────────────────────────────────────
# auth guard
# ─────────────────────────────────────────────────────────────────────────────


def test_upload_requires_auth(client):
    resp = client.post(
        "/api/v1/documents/upload",
        files={"file": ("test.pdf", io.BytesIO(b"%PDF test"), "application/pdf")},
    )
    assert resp.status_code == 401


def test_list_requires_auth(client):
    assert client.get("/api/v1/documents/").status_code == 401


# ─────────────────────────────────────────────────────────────────────────────
# Upload
# ─────────────────────────────────────────────────────────────────────────────


def test_upload_pdf_success(client, auth_headers, tmp_path):
    resp = _upload_pdf(client, auth_headers)
    assert resp.status_code == 201
    data = resp.json()
    assert data["title"] == "test"
    assert data["original_filename"] == "test.pdf"
    assert data["file_size"] > 0
    assert "download_url" in data
    assert "id" in data


def test_upload_non_pdf_rejected(client, auth_headers):
    resp = client.post(
        "/api/v1/documents/upload",
        files={"file": ("notes.txt", io.BytesIO(b"hello"), "text/plain")},
        headers=auth_headers,
    )
    assert resp.status_code == 422


def test_upload_file_saved_to_disk(client, auth_headers, monkeypatch, tmp_path):
    """Verify the file actually lands on disk."""
    monkeypatch.setenv("UPLOAD_DIR", str(tmp_path))
    # Re-import settings after env change (simpler: just check counts)
    from app.core.config import settings

    settings.UPLOAD_DIR = str(tmp_path)

    resp = _upload_pdf(client, auth_headers)
    assert resp.status_code == 201
    # After upload, at least one file should exist under tmp_path
    files = list(tmp_path.rglob("*.pdf"))
    assert len(files) >= 1


# ─────────────────────────────────────────────────────────────────────────────
# List
# ─────────────────────────────────────────────────────────────────────────────


def test_list_documents_empty(client, auth_headers):
    resp = client.get("/api/v1/documents/", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


def test_list_documents_returns_uploads(client, auth_headers):
    _upload_pdf(client, auth_headers, "doc1.pdf")
    _upload_pdf(client, auth_headers, "doc2.pdf")
    resp = client.get("/api/v1/documents/", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


def test_list_documents_isolated_per_user(client):
    """User A's documents must not appear in User B's list."""
    from tests.conftest import get_token

    # User A
    client.post("/api/v1/users/", json={"email": "a@test.com", "password": "Pass123!"})
    token_a = (
        get_token.__wrapped__(client) if hasattr(get_token, "__wrapped__") else None
    )
    resp = client.post(
        "/api/v1/login/access-token",
        data={"username": "a@test.com", "password": "Pass123!"},
    )
    headers_a = {"Authorization": f"Bearer {resp.json()['access_token']}"}

    # User B
    client.post("/api/v1/users/", json={"email": "b@test.com", "password": "Pass123!"})
    resp = client.post(
        "/api/v1/login/access-token",
        data={"username": "b@test.com", "password": "Pass123!"},
    )
    headers_b = {"Authorization": f"Bearer {resp.json()['access_token']}"}

    # Upload under A
    _upload_pdf(client, headers_a, "a_doc.pdf")

    # B should see zero documents
    resp = client.get("/api/v1/documents/", headers=headers_b)
    assert resp.status_code == 200
    assert resp.json() == []


# ─────────────────────────────────────────────────────────────────────────────
# Get single
# ─────────────────────────────────────────────────────────────────────────────


def test_get_document_success(client, auth_headers):
    doc_id = _upload_pdf(client, auth_headers).json()["id"]
    resp = client.get(f"/api/v1/documents/{doc_id}", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["id"] == doc_id


def test_get_document_not_found(client, auth_headers):
    resp = client.get("/api/v1/documents/99999", headers=auth_headers)
    assert resp.status_code == 404


# ─────────────────────────────────────────────────────────────────────────────
# Delete
# ─────────────────────────────────────────────────────────────────────────────


def test_delete_document_success(client, auth_headers):
    doc_id = _upload_pdf(client, auth_headers).json()["id"]
    resp = client.delete(f"/api/v1/documents/{doc_id}", headers=auth_headers)
    assert resp.status_code == 204
    # Should be gone
    assert (
        client.get(f"/api/v1/documents/{doc_id}", headers=auth_headers).status_code
        == 404
    )


def test_delete_document_not_found(client, auth_headers):
    resp = client.delete("/api/v1/documents/99999", headers=auth_headers)
    assert resp.status_code == 404


def test_delete_requires_auth(client):
    assert client.delete("/api/v1/documents/1").status_code == 401
