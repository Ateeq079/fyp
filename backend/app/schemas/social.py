from pydantic import BaseModel
from typing import Optional


class SocialLoginRequest(BaseModel):
    token: str  # The ID token from Google/Apple


class SocialLoginResponse(BaseModel):
    access_token: str
    token_type: str
