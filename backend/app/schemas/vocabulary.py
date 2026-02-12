from pydantic import BaseModel
from typing import Optional

class VocabularyBase(BaseModel):
    word: str
    definition: Optional[str] = None
    context_sentence: Optional[str] = None

class VocabularyCreate(VocabularyBase):
    highlight_id: int

class Vocabulary(VocabularyBase):
    id: int
    highlight_id: int

    class Config:
        from_attributes = True
