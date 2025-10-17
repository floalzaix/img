"""
    Register every routers.
"""

#
#   Imports
#

from fastapi import APIRouter

# Perso

from http_content.routes.watermark_routes import router as watermark_router

#
#   Routers
#

http_router = APIRouter()

http_router.include_router(watermark_router)