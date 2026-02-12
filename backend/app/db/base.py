from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass

# Import all models here so Alembic can discover them
from app.models.user import User
from app.models.document import Document
from app.models.highlight import Highlight
from app.models.vocabulary import Vocabulary
from app.models.flashcard import Flashcard
from app.models.quiz import Quiz