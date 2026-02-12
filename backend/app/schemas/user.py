from pydantic import BaseModel, EmailStr
from datetime import datetime


class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str


class UserUpdate(UserBase):
    pass


class UserDelete(UserBase):
    pass


class UserResponse(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True