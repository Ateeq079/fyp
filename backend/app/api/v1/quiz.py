from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.quiz import Quiz
from app.models.user import User
from app.models.vocabulary import Vocabulary
from app.schemas.quiz import QuizCreate, Quiz as QuizSchema
from app.services.llm_service import llm_service

router = APIRouter()


@router.post("/generate/{document_id}", response_model=QuizSchema)
def generate_quiz(
    *,
    db: Session = Depends(deps.get_db),
    document_id: int,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    AI-generate a multiple-choice quiz from a document's vocabulary and highlights.
    """
    vocab_entries = (
        db.query(Vocabulary)
        .filter(
            Vocabulary.document_id == document_id,
            Vocabulary.user_id == current_user.id,
        )
        .all()
    )

    if not vocab_entries:
        raise HTTPException(
            status_code=400,
            detail="No vocabulary found for this document to generate a quiz.",
        )

    # Compile context
    context_lines = []
    context_lines.append("--- Vocabulary ---")
    for v in vocab_entries:
        line = f"Word: {v.word}"
        if v.context_sentence:
            line += f" | Context: {v.context_sentence}"
        context_lines.append(line)

    context_text = "\n".join(context_lines)

    # Generate via LLM
    try:
        generated = llm_service.generate_quiz_questions(context_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM generation failed: {str(e)}")

    if not generated:
        raise HTTPException(status_code=500, detail="LLM returned no questions. Try again.")

    # Convert LLM output to a canonical list-of-options format
    questions_data = []
    for q in generated:
        questions_data.append({
            "question": q.get("question", ""),
            "options": [
                q.get("option_a", ""),
                q.get("option_b", ""),
                q.get("option_c", ""),
                q.get("option_d", ""),
            ],
            "correct_answer": q.get("correct_answer", "A"),
        })

    quiz = Quiz(
        user_id=current_user.id,
        title=f"Auto-generated Quiz (Doc #{document_id})",
        total_questions=len(questions_data),
        questions_data=questions_data,
    )
    db.add(quiz)
    db.commit()
    db.refresh(quiz)
    return quiz




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
