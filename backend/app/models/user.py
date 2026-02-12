from sqlalchemy import Column, Integer, String, DateTime, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password = Column(String, nullable=True)  # Start nullable for social auth
    google_id = Column(String, unique=True, nullable=True)
    apple_id = Column(String, unique=True, nullable=True)
    image_url = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    documents = relationship(
        "Document", back_populates="user", cascade="all, delete-orphan"
    )
    highlights = relationship(
        "Highlight", back_populates="user", cascade="all, delete-orphan"
    )
    flashcards = relationship(
        "Flashcard", back_populates="user", cascade="all, delete-orphan"
    )
    quizzes = relationship("Quiz", back_populates="user", cascade="all, delete-orphan")
