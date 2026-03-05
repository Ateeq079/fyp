"""Tests for GET /api/v1/health"""


def test_health_check(client):
    resp = client.get("/api/v1/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    assert data["message"] == "API is healthy."
    assert data["data"]["database"] == "connected"
