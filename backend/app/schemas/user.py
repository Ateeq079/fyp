from pydantic import BaseModel, EmailStr, Field
from datetime import datetime


class UserBase(BaseModel):
    email: EmailStr


class UserCreate(UserBase):
    password: str = Field(..., max_length=64)
    is_active: bool = True


class UserUpdate(UserBase):
    pass


class UserDelete(UserBase):
    pass


class UserResponse(UserBase):
    id: str  # Change to str since we use UUIDs (String(36))
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True


class UserStatsResponse(BaseModel):
    total_documents: int
    total_vocabulary: int
    total_quizzes: int
    average_quiz_score: float
    flashcards_due: int
    mastered_words: int
    study_streak_days: int
