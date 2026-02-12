from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.quiz import Quiz
from app.models.user import User
from app.schemas.quiz import QuizCreate, Quiz as QuizSchema

router = APIRouter()


@router.post("/", response_model=QuizSchema)
def create_quiz(
    quiz_in: QuizCreate,
    db: Session = Depends(deps.get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Create new quiz.
    """
    # Convert Pydantic models to dict for JSON storage
    # Pydantic v2 use model_dump(), v1 use dict()
    # Assuming v2 based on previous context, but let's be safe or strict
    questions_json = [
        q.model_dump() if hasattr(q, "model_dump") else q.dict()
        for q in quiz_in.questions_data
    ]

    quiz = Quiz(
        title=quiz_in.title,
        total_questions=quiz_in.total_questions,
        questions_data=questions_json,
        user_id=current_user.id,
    )
    db.add(quiz)
    db.commit()
    db.refresh(quiz)
    return quiz


@router.get("/", response_model=List[QuizSchema])
def read_quizzes(
    db: Session = Depends(deps.get_db),
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve quizzes.
    """
    quizzes = (
        db.query(Quiz)
        .filter(Quiz.user_id == current_user.id)
        .offset(skip)
        .limit(limit)
        .all()
    )
    return quizzes


@router.get("/{id}", response_model=QuizSchema)
def read_quiz(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Get quiz by ID.
    """
    quiz = db.query(Quiz).filter(Quiz.id == id, Quiz.user_id == current_user.id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    return quiz


@router.delete("/{id}", response_model=QuizSchema)
def delete_quiz(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Delete quiz.
    """
    quiz = db.query(Quiz).filter(Quiz.id == id, Quiz.user_id == current_user.id).first()
    if not quiz:
        raise HTTPException(status_code=404, detail="Quiz not found")
    db.delete(quiz)
    db.commit()
    return quiz
