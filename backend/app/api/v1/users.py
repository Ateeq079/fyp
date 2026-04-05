from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.core.security import get_password_hash
from app.models.document import Document
from app.models.vocabulary import Vocabulary
from app.models.quiz import Quiz
from app.models.flashcard import Flashcard
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse, UserStatsResponse
import datetime

router = APIRouter()


@router.post("/", response_model=UserResponse)
def create_user(
    user_in: UserCreate,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Create new user.
    """
    user = db.query(User).filter(User.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )

    user = User(
        email=user_in.email,
        password=get_password_hash(user_in.password),
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.get("/me/stats", response_model=UserStatsResponse)
def get_user_stats(
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get study statistics for the current user.
    """
    # 1. Basics
    total_docs = db.query(Document).filter(Document.user_id == current_user.id).count()
    total_vocab = db.query(Vocabulary).filter(Vocabulary.user_id == current_user.id).count()
    
    # 2. Quiz Performance
    quizzes = db.query(Quiz).filter(Quiz.user_id == current_user.id).all()
    total_quizzes = len(quizzes)
    avg_score = 0.0
    if total_quizzes > 0:
        avg_score = sum([q.score for q in quizzes if q.score is not None]) / total_quizzes

    # 3. Flashcards
    now = datetime.datetime.now(datetime.timezone.utc)
    cards_due = (
        db.query(Flashcard)
        .filter(Flashcard.user_id == current_user.id, Flashcard.next_review_date <= now)
        .count()
    )
    
    mastered = (
        db.query(Flashcard)
        .filter(Flashcard.user_id == current_user.id, Flashcard.ease_factor >= 250, Flashcard.repetitions >= 3)
        .count()
    )

    # 4. Streak (calculated based on recent vocabulary or flashcard additions)
    # This is a simplified version: check how many days in a row the user has been 'active'
    # For now, let's return a static placeholder or a simple count of activity days
    streak = 1 # We can make this more complex later

    return UserStatsResponse(
        total_documents=total_docs,
        total_vocabulary=total_vocab,
        total_quizzes=total_quizzes,
        average_quiz_score=avg_score,
        flashcards_due=cards_due,
        mastered_words=mastered,
        study_streak_days=streak
    )
