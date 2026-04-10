from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Request, status
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_current_active_user
from app.db.deps import get_db
from app.models.user import User
from app.models.document import Document
from app.schemas.document import DocumentResponse
from app.utils import storage_service

router = APIRouter()

MAX_FILE_SIZE = 50 * 1024 * 1024  # 50 MB


def _build_response(request: Request, doc: Document) -> DocumentResponse:
    """Convert a DB Document row into a DocumentResponse with a full download URL."""
    from app.core.config import settings
    
    if settings.SUPABASE_URL:
        bucket = "lexinote-documents"
        download_url = f"{settings.SUPABASE_URL.rstrip('/')}/storage/v1/object/public/{bucket}/{doc.file_path}"
    else:
        base_url = str(request.base_url).rstrip("/")
        download_url = f"{base_url}/files/{doc.file_path}"
        
    return DocumentResponse(
        id=doc.id,
        user_id=doc.user_id,
        title=doc.title,
        original_filename=doc.original_filename,
        file_size=doc.file_size,
        upload_date=doc.upload_date,
        download_url=download_url,
    )


@router.post(
    "/upload", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED
)
async def upload_document(
    request: Request,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Upload a PDF document for the current user."""
    # Validate file type
    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Only PDF files are accepted.",
        )

    data = await file.read()

    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File exceeds the 50 MB limit.",
        )

    file_path, _ = storage_service.save_file(
        user_id=current_user.id,
        original_filename=file.filename,
        data=data,
    )

    doc = Document(
        user_id=current_user.id,
        title=file.filename.rsplit(".", 1)[0],  # strip .pdf from title
        file_path=file_path,
        original_filename=file.filename,
        file_size=len(data),
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)

    return _build_response(request, doc)


@router.get("/", response_model=List[DocumentResponse])
def list_documents(
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Return all documents belonging to the current user."""
    docs = (
        db.query(Document)
        .filter(Document.user_id == current_user.id)
        .order_by(Document.upload_date.desc())
        .all()
    )
    return [_build_response(request, d) for d in docs]


@router.get("/{document_id}", response_model=DocumentResponse)
def get_document(
    document_id: int,
    request: Request,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Return metadata for a single document."""
    doc = (
        db.query(Document)
        .filter(Document.id == document_id, Document.user_id == current_user.id)
        .first()
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found.")
    return _build_response(request, doc)


@router.delete("/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    document_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Delete a document and its file from storage."""
    doc = (
        db.query(Document)
        .filter(Document.id == document_id, Document.user_id == current_user.id)
        .first()
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found.")

    storage_service.delete_file(doc.file_path)
    db.delete(doc)
    db.commit()


@router.put("/{document_id}/file", response_model=DocumentResponse)
async def replace_document_file(
    document_id: int,
    request: Request,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Replace an existing document's PDF with an annotated version."""
    doc = (
        db.query(Document)
        .filter(Document.id == document_id, Document.user_id == current_user.id)
        .first()
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found.")

    if not file.filename or not file.filename.lower().endswith(".pdf"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Only PDF files are accepted.",
        )

    data = await file.read()
    if len(data) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="File exceeds the 50 MB limit.",
        )

    # Delete old file and save new annotated version
    storage_service.delete_file(doc.file_path)
    new_file_path, _ = storage_service.save_file(
        user_id=current_user.id,
        original_filename=doc.original_filename,
        data=data,
    )

    doc.file_path = new_file_path
    doc.file_size = len(data)
    db.commit()
    db.refresh(doc)

    return _build_response(request, doc)
