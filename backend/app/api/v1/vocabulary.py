from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_current_active_user
from app.db.deps import get_db
from app.models.user import User
from app.models.vocabulary import Vocabulary
from app.models.document import Document
from app.schemas.vocabulary import VocabularyCreate, VocabularyResponse

router = APIRouter()


@router.post(
    "/", response_model=VocabularyResponse, status_code=status.HTTP_201_CREATED
)
def add_word(
    payload: VocabularyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Save a selected word/phrase to the user's personal dictionary."""
    # Ensure document belongs to this user
    doc = (
        db.query(Document)
        .filter(Document.id == payload.document_id, Document.user_id == current_user.id)
        .first()
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found.")

    entry = Vocabulary(
        user_id=current_user.id,
        document_id=payload.document_id,
        word=payload.word,
        context_sentence=payload.context_sentence,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/", response_model=List[VocabularyResponse])
def list_words(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Return all dictionary words saved by the current user."""
    return (
        db.query(Vocabulary)
        .filter(Vocabulary.user_id == current_user.id)
        .order_by(Vocabulary.created_at.desc())
        .all()
    )


@router.delete("/{word_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_word(
    word_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Remove a word from the user's dictionary."""
    entry = (
        db.query(Vocabulary)
        .filter(Vocabulary.id == word_id, Vocabulary.user_id == current_user.id)
        .first()
    )
    if not entry:
        raise HTTPException(status_code=404, detail="Word not found.")
    db.delete(entry)
    db.commit()
