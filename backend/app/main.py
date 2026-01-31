from fastapi import FastAPI, Depends
from fastapi.exceptions import RequestValidationError 
from sqlalchemy.orm import Session
from sqlalchemy import text


from .db.deps import get_db
from .core.config import settings
from .core.exceptions import general_exception_handler, validation_exception_handler
from .api.v1.routes import api_router 

from fastapi.middleware.cors import CORSMiddleware



app = FastAPI(
    title="Smart PDF Reader API",
    version="1.0.0"
)
app.include_router(api_router)

app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)


app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS or ["*"],
    allow_credentials = True,
    allow_methods =["*"],
    allow_headers =["*"],

)