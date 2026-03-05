"""Tests for POST /api/v1/login/access-token (email/password login)"""

from tests.conftest import TEST_EMAIL, TEST_PASSWORD, register_user


def test_login_success(client):
    register_user(client)
    resp = client.post(
        "/api/v1/login/access-token",
        data={"username": TEST_EMAIL, "password": TEST_PASSWORD},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_wrong_password(client):
    register_user(client)
    resp = client.post(
        "/api/v1/login/access-token",
        data={"username": TEST_EMAIL, "password": "wrong-password"},
    )
    assert resp.status_code == 401
    assert "Incorrect" in resp.json()["detail"]


def test_login_nonexistent_user(client):
    resp = client.post(
        "/api/v1/login/access-token",
        data={"username": "ghost@lexinote.app", "password": TEST_PASSWORD},
    )
    assert resp.status_code == 401


def test_login_returns_usable_token(client, auth_headers):
    """The returned token should work for a protected endpoint."""
    resp = client.get("/api/v1/documents/", headers=auth_headers)
    assert resp.status_code == 200


def test_login_missing_credentials(client):
    resp = client.post("/api/v1/login/access-token", data={})
    assert resp.status_code == 422


def test_protected_endpoint_without_token(client):
    resp = client.get("/api/v1/documents/")
    assert resp.status_code == 401
