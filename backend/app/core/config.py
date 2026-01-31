from typing import List
from pydantic_settings import BaseSettings ,SettingsConfigDict

class Settings(BaseSettings):
    DB_HOST : str
    DB_PORT: int
    DB_NAME: str
    DB_USER: str
    DB_PASSWORD: str

    APP_NAME: str = "Smart PDF Reader API"
    DEBUG: bool = False

    ALLOWED_ORIGINS: List[str] = []
  
  
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
    )

settings = Settings()

