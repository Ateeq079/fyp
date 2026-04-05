from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from pydantic import ValidationError
from sqlalchemy.orm import Session
import requests

from app.core.config import settings
from app.db.deps import get_db
from app.models.user import User

# Since we don't handle login in FastAPI anymore, this is just to extract the Bearer token from the header securely
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="dummy_token_url_for_swagger", auto_error=False)

_JWKS_CACHE = {}

def get_jwks(jwks_url: str):
    if jwks_url not in _JWKS_CACHE:
        response = requests.get(jwks_url, timeout=10)
        response.raise_for_status()
        _JWKS_CACHE[jwks_url] = response.json()
    return _JWKS_CACHE[jwks_url]


def get_current_user(
    db: Session = Depends(get_db), token: str = Depends(oauth2_scheme)
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if not token:
        raise credentials_exception
        
    try:
        header = jwt.get_unverified_header(token)
        alg = header.get("alg", "HS256")
        
        if alg in ["RS256", "ES256"]:
            # Asymmetric verification via JWKS
            unverified_claims = jwt.get_unverified_claims(token)
            iss = unverified_claims.get("iss")
            if not iss:
                print("Missing 'iss' in JWT claims")
                raise credentials_exception
                
            jwks_url = f"{iss.rstrip('/')}/.well-known/jwks.json"
            try:
                secret = get_jwks(jwks_url)
            except Exception as e:
                print(f"Failed to fetch JWKS from {jwks_url}: {e}")
                raise credentials_exception
        else:
            # Symmetric verification (Legacy GoTrue setup)
            secret = settings.SUPABASE_JWT_SECRET or settings.SECRET_KEY
            if not secret or secret == "KEY HERE":
                print("WARNING: SUPABASE_JWT_SECRET is not set. Auth will fail.")

        payload = jwt.decode(
            token, 
            secret, 
            algorithms=["HS256", "HS384", "HS512", "RS256", "ES256"], 
            options={"verify_aud": False}
        )
        user_uuid: str = payload.get("sub")
        user_email: str = payload.get("email")
        
        if user_uuid is None:
            raise credentials_exception
            
    except (JWTError, ValidationError) as e:
        print(f"JWT Validation Error [{type(e).__name__}]: {e}")
        # Try to peak at the token header and claims to see the 'alg' and 'iss'
        try:
            header = jwt.get_unverified_header(token)
            claims = jwt.get_unverified_claims(token)
            print(f"Token Header: {header}")
            print(f"Token Claims: {claims}")
        except Exception:
            pass
        raise credentials_exception

    user = db.query(User).filter(User.id == user_uuid).first()
    
    # Auto-Sync User from Supabase
    if user is None:
        if not user_email:
            raise credentials_exception
            
        user = User(
            id=user_uuid,
            email=user_email,
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return user


def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    if not current_user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    return current_user
