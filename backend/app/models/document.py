from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, BigInteger
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.base import Base


class Document(Base):
    __tablename__ = "documents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    file_path = Column(String, nullable=False)
    original_filename = Column(String, nullable=False, server_default="document.pdf")
    file_size = Column(BigInteger, nullable=False, server_default="0")
    upload_date = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="documents")
    highlights = relationship(
        "Highlight", back_populates="document", cascade="all, delete-orphan"
    )
    vocabulary = relationship(
        "Vocabulary", back_populates="document", cascade="all, delete-orphan"
    )
