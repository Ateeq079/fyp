from fastapi import APIRouter
from app.api.v1.health import router as health_router
from app.api.v1 import users, login, quiz, social

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(health_router)
api_router.include_router(login.router, tags=["login"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(quiz.router, prefix="/quizzes", tags=["quizzes"])
api_router.include_router(social.router, prefix="/login", tags=["social"])
