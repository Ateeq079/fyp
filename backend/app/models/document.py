from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base

class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    upload_date = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="documents")
    highlights = relationship("Highlight", back_populates="document", cascade="all, delete-orphan")
