from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class FlashcardBase(BaseModel):
    question: str
    answer: str

class FlashcardCreate(FlashcardBase):
    highlight_id: Optional[int] = None

class FlashcardUpdate(BaseModel):
    question: Optional[str] = None
    answer: Optional[str] = None

class FlashcardReview(BaseModel):
    quality: int # 0-5 scale usually, or simplified 1-3

class Flashcard(FlashcardBase):
    id: int
    user_id: int
    highlight_id: Optional[int] = None
    next_review_date: datetime
    ease_factor: int
    interval: int
    repetitions: int

    class Config:
        from_attributes = True
