"""
Pytest configuration and shared fixtures.

Strategy
--------
* Uses a named in-memory SQLite database with shared cache so that ALL
  connections within a single Python process share the same in-memory DB.
  This is required because TestClient opens connections independently.
* The app's psycopg (Postgres) engine is patched at sys.modules level
  BEFORE any app module is imported.
* Tables are created before each test and dropped after.
"""

import os
import sys
import types
from typing import Generator

# ── 1. Set env vars before any app imports ───────────────────────────────────
os.environ.setdefault("SECRET_KEY", "test-secret-key-for-unit-tests")
os.environ.setdefault("DB_HOST", "localhost")
os.environ.setdefault("DB_PORT", "5432")
os.environ.setdefault("DB_NAME", "testdb")
os.environ.setdefault("DB_USER", "testuser")
os.environ.setdefault("DB_PASSWORD", "testpass")

# ── 2. Build SQLite engine using a NAMED in-memory DB with shared cache ───────
#    This lets multiple connections (TestClient + fixtures) share the same DB.
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker, Session

SQLITE_URL = "sqlite:///file:memdb1?mode=memory&cache=shared&uri=true"
test_engine = create_engine(
    SQLITE_URL,
    connect_args={"check_same_thread": False},
)

TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

# ── 3. Patch app.db.session before app.main imports it ───────────────────────
_session_mod = types.ModuleType("app.db.session")
_session_mod.engine = test_engine
_session_mod.SessionLocal = TestingSessionLocal
_session_mod.DATABASE_URL = SQLITE_URL
sys.modules["app.db.session"] = _session_mod

# ── 4. Now import app internals ───────────────────────────────────────────────
import pytest
from fastapi.testclient import TestClient

from app.db.base import Base
from app.db.deps import get_db
from app.main import app

# ── 5. Fixtures ───────────────────────────────────────────────────────────────


@pytest.fixture(autouse=True)
def reset_db():
    """Create all tables before each test, drop after."""
    Base.metadata.create_all(bind=test_engine)
    yield
    Base.metadata.drop_all(bind=test_engine)


def _get_test_db() -> Generator[Session, None, None]:
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture()
def client() -> Generator[TestClient, None, None]:
    """TestClient with get_db overridden to use SQLite."""
    app.dependency_overrides[get_db] = _get_test_db
    with TestClient(app, raise_server_exceptions=True) as c:
        yield c
    app.dependency_overrides.clear()


# ── 6. Helpers ────────────────────────────────────────────────────────────────

TEST_EMAIL = "test@lexinote.app"
TEST_PASSWORD = "TestPass123"


def register_user(client: TestClient) -> dict:
    resp = client.post(
        "/api/v1/users/",
        json={"email": TEST_EMAIL, "password": TEST_PASSWORD},
    )
    assert resp.status_code == 200, f"Register failed: {resp.text}"
    return resp.json()


def get_token(client: TestClient) -> str:
    register_user(client)
    resp = client.post(
        "/api/v1/login/access-token",
        data={"username": TEST_EMAIL, "password": TEST_PASSWORD},
    )
    assert resp.status_code == 200, f"Login failed: {resp.text}"
    return resp.json()["access_token"]


@pytest.fixture()
def auth_headers(client: TestClient) -> dict:
    token = get_token(client)
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture()
def tmp_pdf(tmp_path):
    """A minimal PDF-like file for upload tests."""
    pdf = tmp_path / "sample.pdf"
    pdf.write_bytes(b"%PDF-1.4 minimal test pdf content")
    return pdf
