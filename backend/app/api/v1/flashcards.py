import datetime
from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.models.flashcard import Flashcard
from app.models.vocabulary import Vocabulary
from app.models.user import User
from app.schemas.flashcard import (
    FlashcardReview,
    Flashcard as FlashcardSchema,
)
from app.services.llm_service import llm_service

router = APIRouter()


@router.post("/generate/{document_id}", response_model=List[FlashcardSchema])
def generate_flashcards(
    *,
    db: Session = Depends(deps.get_db),
    document_id: int,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Generate flashcards from a document's highlights and vocabulary.
    """
    # 1. Fetch vocabulary for this document
    vocab_entries = (
        db.query(Vocabulary)
        .filter(
            Vocabulary.document_id == document_id, Vocabulary.user_id == current_user.id
        )
        .all()
    )

    if not vocab_entries:
        raise HTTPException(
            status_code=400,
            detail="No vocabulary found for this document to generate flashcards.",
        )

    # 2. Compile context
    context_lines = []
    context_lines.append("--- Saved Vocabulary Words ---")
    for v in vocab_entries:
        line = f"Word: {v.word}"
        if v.context_sentence:
            line += f" | Context: {v.context_sentence}"
        context_lines.append(line)

    context_text = "\n".join(context_lines)

    # 4. Generate via LLM
    try:
        generated_data = llm_service.generate_flashcards(context_text)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"LLM Generation failed: {str(e)}")

    created_cards = []

    # 5. Save to database
    for item in generated_data:
        flashcard = Flashcard(
            user_id=current_user.id,
            question=item.get("question", ""),
            answer=item.get("answer", ""),
            # SuperMemo-2 defaults
            ease_factor=250,  # 2.5
            interval=0,
            repetitions=0,
            next_review_date=datetime.datetime.now(datetime.timezone.utc),
        )
        db.add(flashcard)
        created_cards.append(flashcard)

    db.commit()

    for card in created_cards:
        db.refresh(card)

    return created_cards


@router.get("/", response_model=List[FlashcardSchema])
def read_flashcards(
    db: Session = Depends(deps.get_db),
    due_only: bool = False,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Retrieve user flashcards. If due_only is True, returns only cards ready for review.
    """
    query = db.query(Flashcard).filter(Flashcard.user_id == current_user.id)

    if due_only:
        now = datetime.datetime.now(datetime.timezone.utc)
        query = query.filter(Flashcard.next_review_date <= now)

    # Order by next review date so most overdue are first
    return query.order_by(Flashcard.next_review_date.asc()).all()


@router.post("/{id}/review", response_model=FlashcardSchema)
def review_flashcard(
    *,
    db: Session = Depends(deps.get_db),
    id: int,
    review_in: FlashcardReview,
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """
    Review a flashcard and update its spaced repetition intervals using SuperMemo-2 algorithm.
    Quality should be between 0 and 5.
    0: complete blackout
    1: incorrect response, remembered upon seeing answer
    2: incorrect response, answer seemed easy to remember
    3: correct response recalled with serious difficulty
    4: correct response after a hesitation
    5: perfect response
    """
    flashcard = (
        db.query(Flashcard)
        .filter(Flashcard.id == id, Flashcard.user_id == current_user.id)
        .first()
    )
    if not flashcard:
        raise HTTPException(status_code=404, detail="Flashcard not found")

    quality = review_in.quality
    if quality < 0 or quality > 5:
        raise HTTPException(status_code=400, detail="Quality must be between 0 and 5")

    # SuperMemo-2 Algorithm
    if quality >= 3:
        if flashcard.repetitions == 0:
            flashcard.interval = 1
        elif flashcard.repetitions == 1:
            flashcard.interval = 6
        else:
            flashcard.interval = int(
                round(flashcard.interval * (flashcard.ease_factor / 100.0))
            )

        flashcard.repetitions += 1
    else:
        # User failed to recall
        flashcard.repetitions = 0
        flashcard.interval = 1

    # Update Ease Factor
    # EF':=EF+(0.1-(5-q)*(0.08+(5-q)*0.02))
    new_ef = (flashcard.ease_factor / 100.0) + (
        0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)
    )
    if new_ef < 1.3:
        new_ef = 1.3

    flashcard.ease_factor = int(new_ef * 100)  # Store as integer

    # Calculate next review date
    now = datetime.datetime.now(datetime.timezone.utc)
    flashcard.next_review_date = now + datetime.timedelta(days=flashcard.interval)

    db.commit()
    db.refresh(flashcard)
    return flashcard
