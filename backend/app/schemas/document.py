from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class DocumentBase(BaseModel):
    title: str
    file_path: str


class DocumentCreate(BaseModel):
    title: str
    file_path: str
    original_filename: str
    file_size: int


class DocumentUpdate(BaseModel):
    title: Optional[str] = None


class DocumentResponse(BaseModel):
    id: int
    user_id: str
    title: str
    original_filename: str
    file_size: int
    upload_date: datetime
    download_url: str  # Populated by the endpoint with the full URL

    class Config:
        from_attributes = True
