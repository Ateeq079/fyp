from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class DocumentBase(BaseModel):
    title: str
    file_path: str

class DocumentCreate(DocumentBase):
    pass

class DocumentUpdate(BaseModel):
    title: Optional[str] = None

class Document(DocumentBase):
    id: int
    user_id: int
    upload_date: datetime

    class Config:
        from_attributes = True
