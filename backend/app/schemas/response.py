from pydantic import BaseModel
from typing import Any, Optional

class ResponseSchema(BaseModel):
    succes: bool
    message:Optional[str] = None
    data: Optional[Any] = None


