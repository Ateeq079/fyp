from typing import Any
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from app.api import deps
from app.core import security
from app.core.config import settings
from app.models.user import User
from app.schemas.social import SocialLoginRequest, SocialLoginResponse
from datetime import timedelta

router = APIRouter()


@router.post("/google", response_model=SocialLoginResponse)
def login_google(
    login_request: SocialLoginRequest,
    db: Session = Depends(deps.get_db),
) -> Any:
    """
    Login or Register with Google.
    """
    token = login_request.token

    try:
        # Verify the token
        # specific audience is optional but recommended
        id_info = id_token.verify_oauth2_token(token, google_requests.Request())

        # Get info
        google_id = id_info.get("sub")
        email = id_info.get("email")
        # name = id_info.get("name")
        picture = id_info.get("picture")

        if not email:
            raise HTTPException(
                status_code=400, detail="Invalid Google Token: No email found"
            )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Invalid Google Token: {str(e)}")

    # Check if user exists
    user = db.query(User).filter(User.email == email).first()

    if not user:
        # Create new user
        user = User(
            email=email,
            password=None,  # No password for social users
            google_id=google_id,
            image_url=picture,
            is_active=True,
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    else:
        # Update existing user with google_id if missing
        if not user.google_id:
            user.google_id = google_id
            if picture and not user.image_url:
                user.image_url = picture
            db.add(user)
            db.commit()
            db.refresh(user)

    # Create JWT
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    return {
        "access_token": security.create_access_token(
            user.id, expires_delta=access_token_expires
        ),
        "token_type": "bearer",
    }
