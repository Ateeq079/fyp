from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class Highlight(Base):
    __tablename__ = "highlights"

    id = Column(Integer, primary_key=True, index=True)
    document_id = Column(Integer, ForeignKey("documents.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(String, nullable=False)
    color = Column(String, default="yellow")
    page_number = Column(Integer, nullable=False)
    rect_coordinates = Column(JSON, nullable=True) # Storing coordinates as JSON
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    document = relationship("Document", back_populates="highlights")
    user = relationship("User", back_populates="highlights")
    vocabulary = relationship("Vocabulary", back_populates="highlight", uselist=False, cascade="all, delete-orphan")
    flashcards = relationship("Flashcard", back_populates="highlight", cascade="all, delete-orphan")
