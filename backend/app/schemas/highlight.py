from pydantic import BaseModel, ConfigDict
from datetime import datetime
from typing import Optional, List, Dict, Any
from .vocabulary import Vocabulary

class HighlightBase(BaseModel):
    content: str
    color: str = "yellow"
    page_number: int
    rect_coordinates: Optional[List[Any]] = None

class HighlightCreate(HighlightBase):
    document_id: int

class Highlight(HighlightBase):
    id: int
    document_id: int
    user_id: int
    created_at: datetime
    vocabulary: Optional[Vocabulary] = None

    model_config = ConfigDict(from_attributes=True)
