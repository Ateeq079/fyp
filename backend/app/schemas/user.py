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
    id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
