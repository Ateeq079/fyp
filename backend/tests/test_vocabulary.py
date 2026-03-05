"""
Tests for vocabulary (dictionary) endpoints:
  POST   /api/v1/vocabulary/
  GET    /api/v1/vocabulary/
  DELETE /api/v1/vocabulary/{id}
"""

import io


def _upload_pdf(client, auth_headers, filename="test.pdf"):
    return client.post(
        "/api/v1/documents/upload",
        files={"file": (filename, io.BytesIO(b"%PDF-1.4 test"), "application/pdf")},
        headers=auth_headers,
    )


def _add_word(
    client, auth_headers, document_id, word="serendipity", context="Found in text"
):
    return client.post(
        "/api/v1/vocabulary/",
        json={"word": word, "context_sentence": context, "document_id": document_id},
        headers=auth_headers,
    )


# ─────────────────────────────────────────────────────────────────────────────
# Auth guards
# ─────────────────────────────────────────────────────────────────────────────


def test_add_word_requires_auth(client):
    resp = client.post("/api/v1/vocabulary/", json={"word": "test", "document_id": 1})
    assert resp.status_code == 401


def test_list_words_requires_auth(client):
    assert client.get("/api/v1/vocabulary/").status_code == 401


# ─────────────────────────────────────────────────────────────────────────────
# Add word (POST)
# ─────────────────────────────────────────────────────────────────────────────


def test_add_word_success(client, auth_headers):
    doc_id = _upload_pdf(client, auth_headers).json()["id"]
    resp = _add_word(client, auth_headers, doc_id)
    assert resp.status_code == 201
    data = resp.json()
    assert data["word"] == "serendipity"
    assert data["context_sentence"] == "Found in text"
    assert data["document_id"] == doc_id
    assert "id" in data
    assert "created_at" in data


def test_add_word_invalid_document(client, auth_headers):
    """Should 404 when document doesn't exist or belongs to another user."""
    resp = _add_word(client, auth_headers, document_id=99999)
    assert resp.status_code == 404


def test_add_word_no_context(client, auth_headers):
    """context_sentence is optional."""
    doc_id = _upload_pdf(client, auth_headers).json()["id"]
    resp = client.post(
        "/api/v1/vocabulary/",
        json={"word": "ephemeral", "document_id": doc_id},
        headers=auth_headers,
    )
    assert resp.status_code == 201
    assert resp.json()["context_sentence"] is None


# ─────────────────────────────────────────────────────────────────────────────
# List words (GET)
# ─────────────────────────────────────────────────────────────────────────────


def test_list_words_empty(client, auth_headers):
    resp = client.get("/api/v1/vocabulary/", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


def test_list_words_returns_saved(client, auth_headers):
    doc_id = _upload_pdf(client, auth_headers).json()["id"]
    _add_word(client, auth_headers, doc_id, "ephemeral")
    _add_word(client, auth_headers, doc_id, "perspicacious")
    resp = client.get("/api/v1/vocabulary/", headers=auth_headers)
    assert resp.status_code == 200
    words = [w["word"] for w in resp.json()]
    assert "ephemeral" in words
    assert "perspicacious" in words


def test_vocabulary_isolated_per_user(client):
    """User A's words must not appear in User B's list."""
    # User A
    client.post("/api/v1/users/", json={"email": "a@v.com", "password": "Pass123!"})
    token_a = client.post(
        "/api/v1/login/access-token",
        data={"username": "a@v.com", "password": "Pass123!"},
    ).json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # User B
    client.post("/api/v1/users/", json={"email": "b@v.com", "password": "Pass123!"})
    token_b = client.post(
        "/api/v1/login/access-token",
        data={"username": "b@v.com", "password": "Pass123!"},
    ).json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    doc_id = _upload_pdf(client, headers_a).json()["id"]
    _add_word(client, headers_a, doc_id, "ubiquitous")

    resp = client.get("/api/v1/vocabulary/", headers=headers_b)
    assert resp.status_code == 200
    assert resp.json() == []


# ─────────────────────────────────────────────────────────────────────────────
# Delete word (DELETE)
# ─────────────────────────────────────────────────────────────────────────────


def test_delete_word_success(client, auth_headers):
    doc_id = _upload_pdf(client, auth_headers).json()["id"]
    word_id = _add_word(client, auth_headers, doc_id).json()["id"]
    resp = client.delete(f"/api/v1/vocabulary/{word_id}", headers=auth_headers)
    assert resp.status_code == 204
    # Should be gone from list
    remaining = client.get("/api/v1/vocabulary/", headers=auth_headers).json()
    assert all(w["id"] != word_id for w in remaining)


def test_delete_word_not_found(client, auth_headers):
    resp = client.delete("/api/v1/vocabulary/99999", headers=auth_headers)
    assert resp.status_code == 404


def test_delete_word_requires_auth(client):
    assert client.delete("/api/v1/vocabulary/1").status_code == 401
