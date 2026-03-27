from pydantic import BaseModel, ConfigDict
from typing import Optional, List
from datetime import datetime


class RelatedLink(BaseModel):
    title: str
    url: str


class VocabularyCreate(BaseModel):
    word: str
    definition: Optional[str] = None
    context_sentence: Optional[str] = None
    source_name: Optional[str] = None
    source_url: Optional[str] = None
    related_links: Optional[List[RelatedLink]] = None
    document_id: int


class VocabularyResponse(BaseModel):
    id: int
    word: str
    definition: Optional[str] = None
    context_sentence: Optional[str] = None
    source_name: Optional[str] = None
    source_url: Optional[str] = None
    related_links: Optional[List[RelatedLink]] = None
    document_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

