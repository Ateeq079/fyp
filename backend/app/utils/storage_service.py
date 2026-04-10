"""
Storage Service — Supabase Storage backend.

All files are stored in the `lexinote-documents` bucket.
Set SUPABASE_URL and SUPABASE_KEY in .env before running.
"""

import uuid
import httpx
from pathlib import Path
from app.core.config import settings

_BUCKET = "lexinote-documents"


def _storage_url(file_path: str) -> str:
    if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
        raise RuntimeError(
            "SUPABASE_URL and SUPABASE_KEY must be set in .env to use storage."
        )
    return f"{settings.SUPABASE_URL.rstrip('/')}/storage/v1/object/{_BUCKET}/{file_path}"


def _headers() -> dict:
    return {"Authorization": f"Bearer {settings.SUPABASE_KEY}"}


def save_file(user_id: str, original_filename: str, data: bytes) -> tuple[str, str]:
    """
    Upload *data* to Supabase Storage under `lexinote-documents/<user_id>/<uuid>.pdf`.

    Returns
    -------
    (file_path, stored_filename)
        file_path       – relative path stored in the DB (e.g. "3/a1b2c3.pdf")
        stored_filename – the UUID-based filename
    """
    ext = Path(original_filename).suffix.lower() or ".pdf"
    stored_filename = f"{uuid.uuid4().hex}{ext}"
    file_path = f"{user_id}/{stored_filename}"

    url = _storage_url(file_path)
    res = httpx.post(
        url,
        headers={**_headers(), "Content-Type": "application/pdf"},
        content=data,
    )
    res.raise_for_status()

    return file_path, stored_filename


def delete_file(file_path: str) -> None:
    """
    Delete a file from Supabase Storage.
    *file_path* is the relative path returned by save_file(), e.g. "3/abc.pdf".
    Silently ignores 404s (file already gone).
    """
    url = _storage_url(file_path)
    res = httpx.delete(url, headers=_headers())
    if res.status_code not in (200, 204, 404):
        res.raise_for_status()

