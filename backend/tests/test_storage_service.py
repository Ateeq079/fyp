"""Unit tests for app/utils/storage_service.py (pure filesystem logic)."""

import pytest
from pathlib import Path
from app.utils import storage_service
from app.core.config import settings


@pytest.fixture(autouse=True)
def override_upload_dir(tmp_path, monkeypatch):
    """Redirect all file I/O to a temp directory for every test."""
    monkeypatch.setattr(
        storage_service, "settings", type("S", (), {"UPLOAD_DIR": str(tmp_path)})()
    )


def test_save_file_creates_file(tmp_path):
    file_path, stored_name = storage_service.save_file(
        user_id=1, original_filename="report.pdf", data=b"PDF content here"
    )
    full = Path(tmp_path) / file_path
    assert full.exists()
    assert full.read_bytes() == b"PDF content here"


def test_save_file_returns_relative_path(tmp_path):
    file_path, stored_name = storage_service.save_file(
        user_id=42, original_filename="essay.pdf", data=b"data"
    )
    assert file_path.startswith("42/")
    assert file_path.endswith(".pdf")


def test_save_file_generates_unique_names(tmp_path):
    p1, _ = storage_service.save_file(1, "a.pdf", b"aaa")
    p2, _ = storage_service.save_file(1, "a.pdf", b"bbb")
    assert p1 != p2


def test_save_file_creates_user_dir(tmp_path):
    storage_service.save_file(user_id=99, original_filename="x.pdf", data=b"x")
    assert (Path(tmp_path) / "99").is_dir()


def test_delete_file_removes_it(tmp_path):
    file_path, _ = storage_service.save_file(1, "del.pdf", b"bye")
    full = Path(tmp_path) / file_path
    assert full.exists()
    storage_service.delete_file(file_path)
    assert not full.exists()


def test_delete_file_nonexistent_does_not_raise(tmp_path):
    # Should be silently ignored
    storage_service.delete_file("99/nonexistent.pdf")


def test_save_file_preserves_extension(tmp_path):
    file_path, stored_name = storage_service.save_file(1, "notes.pdf", b"data")
    assert stored_name.endswith(".pdf")
