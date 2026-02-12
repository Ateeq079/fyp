from pydantic import BaseModel
from datetime import datetime
from typing import List, Dict, Any, Optional

class QuestionBase(BaseModel):
    question: str
    options: List[str]
    correct_answer: str

class QuizBase(BaseModel):
    title: str
    total_questions: int

class QuizCreate(QuizBase):
    questions_data: List[QuestionBase]

class Quiz(QuizBase):
    id: int
    user_id: int
    score: Optional[int] = None
    created_at: datetime
    questions_data: List[QuestionBase] # This will map to the JSON column

    class Config:
        from_attributes = True
