from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class Flashcard(Base):
    __tablename__ = "flashcards"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    highlight_id = Column(Integer, ForeignKey("highlights.id"), nullable=True)
    question = Column(String, nullable=False)
    answer = Column(String, nullable=False)
    
    # Spaced Repetition Fields
    next_review_date = Column(DateTime(timezone=True), server_default=func.now())
    ease_factor = Column(Integer, default=250) # multiplied by 100, so 2.5 is 250
    interval = Column(Integer, default=0) # in days
    repetitions = Column(Integer, default=0)

    user = relationship("User", back_populates="flashcards")
    highlight = relationship("Highlight", back_populates="flashcards")
