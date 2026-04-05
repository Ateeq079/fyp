"""
Storage Service — handles file persistence.

CURRENT IMPLEMENTATION: Local filesystem under settings.UPLOAD_DIR.

# ─────────────────────────────────────────────
# TODO: CLOUD STORAGE — Future S3/GCS Integration
# ─────────────────────────────────────────────
# When ready to move to cloud, replace the local methods below with the
# cloud implementations stubbed at the bottom of this file.
#
# Required packages:  boto3 (S3)  |  google-cloud-storage (GCS)
#
# S3 stub:
#   import boto3
#   s3 = boto3.client("s3")
#   BUCKET = "lexinote-documents"
#
#   async def _upload_to_s3(key: str, data: bytes) -> str:
#       s3.put_object(Bucket=BUCKET, Key=key, Body=data, ContentType="application/pdf")
#       return f"https://{BUCKET}.s3.amazonaws.com/{key}"
#
#   async def _delete_from_s3(key: str) -> None:
#       s3.delete_object(Bucket=BUCKET, Key=key)
#
# GCS stub:
#   from google.cloud import storage as gcs_storage
#   gcs = gcs_storage.Client()
#   BUCKET = "lexinote-documents"
#
#   async def _upload_to_gcs(key: str, data: bytes) -> str:
#       bucket = gcs.bucket(BUCKET)
#       blob = bucket.blob(key)
#       blob.upload_from_string(data, content_type="application/pdf")
#       return blob.public_url
#
#   async def _delete_from_gcs(key: str) -> None:
#       gcs.bucket(BUCKET).blob(key).delete()
# ─────────────────────────────────────────────
"""

import os
import uuid
from pathlib import Path
from app.core.config import settings


def _user_dir(user_id: str) -> Path:
    """Return (and create if needed) the per-user upload directory."""
    path = Path(settings.UPLOAD_DIR) / str(user_id)
    path.mkdir(parents=True, exist_ok=True)
    return path


def save_file(user_id: str, original_filename: str, data: bytes) -> tuple[str, str]:
    """
    Save *data* to local disk.

    Returns
    -------
    (file_path, stored_filename)
        file_path      – relative path stored in the DB  (e.g. "3/a1b2c3.pdf")
        stored_filename – the UUID-based filename on disk
    """
    ext = Path(original_filename).suffix.lower() or ".pdf"
    stored_filename = f"{uuid.uuid4().hex}{ext}"
    dest = _user_dir(user_id) / stored_filename
    dest.write_bytes(data)
    # Store relative path so it's portable
    return f"{user_id}/{stored_filename}", stored_filename


def delete_file(file_path: str) -> None:
    """
    Remove a file from local storage.

    *file_path* is the relative path returned by save_file(), e.g. "3/abc.pdf".
    Silently ignores missing files.
    """
    full_path = Path(settings.UPLOAD_DIR) / file_path
    try:
        full_path.unlink()
    except FileNotFoundError:
        pass
