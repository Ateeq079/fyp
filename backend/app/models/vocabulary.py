from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from app.db.base import Base

class Vocabulary(Base):
    __tablename__ = "vocabularies"

    id = Column(Integer, primary_key=True, index=True)
    highlight_id = Column(Integer, ForeignKey("highlights.id"), unique=True, nullable=False)
    word = Column(String, index=True, nullable=False)
    definition = Column(String, nullable=True)
    context_sentence = Column(String, nullable=True)

    highlight = relationship("Highlight", back_populates="vocabulary")
