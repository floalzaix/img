"""
    The entry point of the backend.
"""

#
#   Imports
#

import logging
import structlog

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi import Request

# Perso

from config.settings import settings, Environnement
from http_content.routers import http_router

#
#   App
#

app = FastAPI(
    title="Backend",
    description="The backend of the app",
    version="0.1.0",
    contact={
        "name": "Flo Alzaix",
        "email": "floalzfencing@gmail.com"
    },
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

#
#   Middlewares
#

app.add_middleware(
    CORSMiddleware,
    allow_origins=(
        ["*"] if settings.ENV == Environnement.DEV 
            else settings.PROD_CORS_ORIGINS
    ),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#
#   Logging
#

logging.basicConfig(
    level=settings.LOGGING_LEVEL.value,
    format="%(asctime)s %(levelname)s %(module)s %(message)s",
    handlers=[
        logging.FileHandler("app.log"),
        logging.StreamHandler()
    ]
)

_logger = structlog.get_logger()

#
#   Routes
#

app.include_router(http_router)

#
#   Exception Handler
#

@app.exception_handler(Exception)
async def exception_handler(request: Request, exc: Exception):
    _logger.error(
        "APP | Unhandled Exception.", 
        error=str(exc), 
    )
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error !" 
            if settings.ENV != Environnement.DEV
            else str(exc)
        }
    )