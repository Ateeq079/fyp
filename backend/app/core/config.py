from typing import List, Optional
from pydantic_settings import BaseSettings ,SettingsConfigDict

class Settings(BaseSettings):
    DB_HOST : str
    DB_PORT: int
    DB_NAME: str
    DB_USER: str
    DB_PASSWORD: str

    APP_NAME: str = "Smart PDF Reader API"
    DEBUG: bool = False
    API_V1_STR: str = "/api/v1"
    UPLOAD_DIR: str = "uploads"  # Relative to app root

    ALLOWED_ORIGINS: List[str] = []

    # LLM API keys (optional — only needed for AI generation features)
    GEMINI_API_KEY: Optional[str] = None
    GOOGLE_API_KEY: Optional[str] = None
    OPENAI_API_KEY: Optional[str] = None

    # Database Configuration (supports individual fields or a full URL)
    DATABASE_URL: Optional[str] = None
    DB_HOST: Optional[str] = None
    DB_PORT: Optional[int] = 5432
    DB_NAME: Optional[str] = None
    DB_USER: Optional[str] = None
    DB_PASSWORD: Optional[str] = None

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    SECRET_KEY: str = "KEY HERE"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

settings = Settings()

