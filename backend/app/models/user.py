from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import DeclarativeBase, relationship
from app.db.base import Base


class User(Base):
    __tablename__ = "users"

    id  = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    documents = relationship("Document", back_populates="user", cascade="all, delete-orphan")
    highlights = relationship("Highlight", back_populates="user", cascade="all, delete-orphan")
    flashcards = relationship("Flashcard", back_populates="user", cascade="all, delete-orphan")
    quizzes = relationship("Quiz", back_populates="user", cascade="all, delete-orphan")


