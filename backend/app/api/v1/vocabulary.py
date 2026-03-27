from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.api.deps import get_current_active_user
from app.db.deps import get_db
from app.models.user import User
from app.models.vocabulary import Vocabulary
from app.models.document import Document
from app.schemas.vocabulary import VocabularyCreate, VocabularyResponse
from app.services.llm_service import llm_service

router = APIRouter()


@router.post(
    "/", response_model=VocabularyResponse, status_code=status.HTTP_201_CREATED
)
def add_word(
    payload: VocabularyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Save a word to the user's dictionary and enrich it with an AI-generated definition."""
    doc = (
        db.query(Document)
        .filter(Document.id == payload.document_id, Document.user_id == current_user.id)
        .first()
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found.")

    # Use Gemini to generate definition + context sentence
    ai_result = llm_service.generate_word_definition(payload.word)

    entry = Vocabulary(
        user_id=current_user.id,
        document_id=payload.document_id,
        word=payload.word,
        definition=ai_result.get("definition") if ai_result else payload.definition,
        context_sentence=ai_result.get("context_sentence") if ai_result else payload.context_sentence,
        source_name=ai_result.get("source_name") if ai_result else None,
        source_url=ai_result.get("source_url") if ai_result else None,
        related_links=ai_result.get("related_links") if ai_result else None,
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
