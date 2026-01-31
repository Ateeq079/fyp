from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

DATABASE_URL = (
    f"postgresql+psycopg://{settings.DB_USER}:"
    f"{settings.DB_PASSWORD}@{settings.DB_HOST}:"
    f"{settings.DB_PORT}/{settings.DB_NAME}"
)


engine = create_engine(DATABASE_URL, echo=True)


SessionLocal = sessionmaker(
    autocommit = False,
    autoflush=False,
    bind = engine
)