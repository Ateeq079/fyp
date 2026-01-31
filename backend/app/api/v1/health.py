from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.schemas.response import ResponseSchema
from app.db.deps import get_db

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=ResponseSchema)
def health_check(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))
    return ResponseSchema(
        succes=True,
        message="API is healthy.",
        data={"database": "connected"}
    )



