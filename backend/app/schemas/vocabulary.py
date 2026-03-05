from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class VocabularyCreate(BaseModel):
    word: str
    context_sentence: Optional[str] = None
    document_id: int


class VocabularyResponse(BaseModel):
    id: int
    word: str
    context_sentence: Optional[str] = None
    document_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
