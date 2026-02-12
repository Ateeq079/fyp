from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.schemas.user import UserCreate, UserResponse
from app.models.user import User
from app.core.security import get_password_hash

router = APIRouter()


@router.post("/", response_model=UserResponse)
def create_user(
    user_in: UserCreate,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Create new user.
    """
    user = db.query(User).filter(User.email == user_in.email).first()
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )

    user = User(
        email=user_in.email,
        password=get_password_hash(user_in.password),
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
