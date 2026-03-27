from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base


class Vocabulary(Base):
    __tablename__ = "vocabularies"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    document_id = Column(Integer, ForeignKey("documents.id"), nullable=False)
    word = Column(String, index=True, nullable=False)
    definition = Column(String, nullable=True)
    context_sentence = Column(String, nullable=True)
    source_name = Column(String, nullable=True)
    source_url = Column(String, nullable=True)
    related_links = Column(JSON, nullable=True) # List of {"title": "...", "url": "..."}
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="vocabulary")
    document = relationship("Document", back_populates="vocabulary")
