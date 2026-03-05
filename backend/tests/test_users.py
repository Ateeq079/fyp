"""Tests for POST /api/v1/users/ (user registration)"""

from tests.conftest import TEST_EMAIL, TEST_PASSWORD, register_user


def test_register_user_success(client):
    resp = client.post(
        "/api/v1/users/",
        json={"email": TEST_EMAIL, "password": TEST_PASSWORD},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == TEST_EMAIL
    assert "id" in data
    # Password must never be returned
    assert "password" not in data


def test_register_user_duplicate_email(client):
    register_user(client)
    resp = client.post(
        "/api/v1/users/",
        json={"email": TEST_EMAIL, "password": "AnotherPass!"},
    )
    assert resp.status_code == 400
    assert "already exists" in resp.json()["detail"]


def test_register_user_missing_fields(client):
    resp = client.post("/api/v1/users/", json={"email": TEST_EMAIL})
    assert resp.status_code == 422


def test_register_user_invalid_email(client):
    resp = client.post(
        "/api/v1/users/",
        json={"email": "not-an-email", "password": TEST_PASSWORD},
    )
    assert resp.status_code == 422
