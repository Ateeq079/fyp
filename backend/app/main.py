from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError

from .db.init_db import init_db
from .core.config import settings
from .core.exceptions import general_exception_handler, validation_exception_handler
from .api.v1.routes import api_router
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Smart PDF Reader API", version="1.0.0")


@app.on_event("startup")
def on_startup():
    init_db()


@app.get("/health", tags=["Health"])
def health_check():
    """
    Keep-alive probe for Render free tier.
    Point an external cron (e.g. cron-job.org / UptimeRobot) at this endpoint
    every 14 minutes so the instance never sleeps.
    """
    return {"status": "ok", "timestamp": datetime.now(timezone.utc).isoformat()}


app.include_router(api_router)

app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)


app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

