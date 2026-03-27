"""
Tests for flashcard endpoints:
  GET    /api/v1/flashcards/
  GET    /api/v1/flashcards/?due_only=true
  POST   /api/v1/flashcards/{id}/review  (SM-2 algorithm)
"""

import datetime
import pytest
from fastapi.testclient import TestClient


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

def _seed_flashcard(client: TestClient, headers: dict, next_review_days_offset: int = 0):
    """
    Directly insert a flashcard via DB manipulations.
    Since there's no public "create" endpoint (only AI generate), we insert
    via the quiz endpoint to get a user, then use the DB session fixture.
    Instead, we call the private seed endpoint pattern used in other test files:
    we rely on the fact that the DB is shared within a test via conftest.
    We insert using SQLAlchemy model directly.
    """
    pass  # filled below via fixture approach


# ─────────────────────────────────────────────────────────────────────────────
# Fixtures
# ─────────────────────────────────────────────────────────────────────────────

@pytest.fixture()
def seeded_flashcards(client, auth_headers):
    """Seed two flashcards — one due now, one due in the future."""
    from app.db.base import Base  # noqa — ensures tables exist
    from app.models.flashcard import Flashcard
    from app.models.user import User

    # Re-use the same test DB engine (conftest already patched app.db.session)
    from app.db import session as _session_mod

    db = _session_mod.SessionLocal()
    try:
        user = db.query(User).first()
        assert user is not None, "No user found; auth_headers fixture should have created one"

        now = datetime.datetime.now(datetime.timezone.utc)

        card_due = Flashcard(
            user_id=user.id,
            question="What is spaced repetition?",
            answer="A learning technique that spaces reviews over time.",
            ease_factor=250,
            interval=0,
            repetitions=0,
            next_review_date=now - datetime.timedelta(days=1),  # overdue
        )
        card_future = Flashcard(
            user_id=user.id,
            question="What is the SM-2 algorithm?",
            answer="An algorithm for computing optimal review intervals.",
            ease_factor=250,
            interval=7,
            repetitions=2,
            next_review_date=now + datetime.timedelta(days=7),  # not due yet
        )
        db.add_all([card_due, card_future])
        db.commit()
        db.refresh(card_due)
        db.refresh(card_future)
        return card_due.id, card_future.id
    finally:
        db.close()


# ─────────────────────────────────────────────────────────────────────────────
# Auth guards
# ─────────────────────────────────────────────────────────────────────────────

def test_list_flashcards_requires_auth(client):
    assert client.get("/api/v1/flashcards/").status_code == 401


def test_review_flashcard_requires_auth(client):
    assert client.post("/api/v1/flashcards/1/review", json={"quality": 3}).status_code == 401


# ─────────────────────────────────────────────────────────────────────────────
# GET /flashcards/
# ─────────────────────────────────────────────────────────────────────────────

def test_list_flashcards_empty(client, auth_headers):
    resp = client.get("/api/v1/flashcards/", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json() == []


def test_list_flashcards_returns_all(client, auth_headers, seeded_flashcards):
    resp = client.get("/api/v1/flashcards/", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


def test_list_flashcards_due_only_filters_correctly(client, auth_headers, seeded_flashcards):
    due_card_id, future_card_id = seeded_flashcards
    resp = client.get("/api/v1/flashcards/?due_only=true", headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["id"] == due_card_id


def test_list_flashcards_due_only_false_returns_all(client, auth_headers, seeded_flashcards):
    resp = client.get("/api/v1/flashcards/?due_only=false", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()) == 2


# ─────────────────────────────────────────────────────────────────────────────
# POST /flashcards/{id}/review  — SM-2 algorithm
# ─────────────────────────────────────────────────────────────────────────────

def test_review_flashcard_not_found(client, auth_headers):
    resp = client.post("/api/v1/flashcards/99999/review", json={"quality": 3}, headers=auth_headers)
    assert resp.status_code == 404


def test_review_flashcard_invalid_quality(client, auth_headers, seeded_flashcards):
    due_id, _ = seeded_flashcards
    resp = client.post(f"/api/v1/flashcards/{due_id}/review", json={"quality": 6}, headers=auth_headers)
    assert resp.status_code == 400


def test_review_quality_5_increments_interval(client, auth_headers, seeded_flashcards):
    """SM-2: first review with quality=5 → repetitions=1, interval=1."""
    due_id, _ = seeded_flashcards
    resp = client.post(f"/api/v1/flashcards/{due_id}/review", json={"quality": 5}, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["repetitions"] == 1
    assert data["interval"] == 1
    assert data["ease_factor"] > 250  # EF improves on perfect recall


def test_review_quality_3_correct_recall(client, auth_headers, seeded_flashcards):
    """SM-2: quality=3 → correct recall, repetitions increments, interval=1."""
    due_id, _ = seeded_flashcards
    resp = client.post(f"/api/v1/flashcards/{due_id}/review", json={"quality": 3}, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["repetitions"] == 1
    assert data["interval"] == 1


def test_review_quality_0_resets_repetitions(client, auth_headers, seeded_flashcards):
    """SM-2: quality=0 (blackout) → repetitions reset to 0, interval reset to 1."""
    _, future_id = seeded_flashcards  # future card has repetitions=2
    resp = client.post(f"/api/v1/flashcards/{future_id}/review", json={"quality": 0}, headers=auth_headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["repetitions"] == 0
    assert data["interval"] == 1
    assert data["ease_factor"] < 250  # EF decreases on failed recall


def test_review_updates_next_review_date(client, auth_headers, seeded_flashcards):
    """After review, next_review_date should be in the future."""
    due_id, _ = seeded_flashcards
    resp = client.post(f"/api/v1/flashcards/{due_id}/review", json={"quality": 4}, headers=auth_headers)
    assert resp.status_code == 200
    next_date_str = resp.json()["next_review_date"]
    # Parse and normalise to naive UTC for comparison (SQLite returns naive datetimes)
    next_date = datetime.datetime.fromisoformat(next_date_str)
    if next_date.tzinfo is not None:
        next_date = next_date.replace(tzinfo=None)
    now = datetime.datetime.utcnow()
    assert next_date > now
