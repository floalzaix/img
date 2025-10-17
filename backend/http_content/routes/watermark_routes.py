"""
    Handles watermarking routes and endpoints.
"""

#
#   Imports
#

import structlog

from fastapi import (
    APIRouter,
    UploadFile,
    File,
    Depends,
    Response,
    HTTPException,
)

# Perso

from deps import get_watermark_service
from http_content.adapters.media_adapter import prepare_media
from services.watermark_service import WatermarkService
from exceptions.watermark_errors import WatermarkDimensionsError

#
#   Routes
#

router = APIRouter()

_logger = structlog.get_logger()

MAX_MEDIA_SIZE = 50 * 1024 * 1024 # 50MB

EXTENSION_TYPES = [
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".bmp",
    ".tiff",
    ".tif",
    ".webp",
    ".svg",
    ".heic",
    ".heif"
]

CONTENT_TYPES = [
    "image/jpeg", 
    "image/png", 
    "image/gif", 
    "image/bmp", 
    "image/tiff", 
    "image/webp", 
    "image/svg+xml",
    "image/heic",
    "image/heif"
]

@router.post(
    "/watermark",
    summary="Add a watermark to a photo",
    responses={
        "500": {
            "description": "Internal server error"
        },
        "422": {
            "description": "Unprocessable entity"
        },
        "413": {
            "description": "Request entity too large"
        },
        "415": {
            "description": "Unsupported media type"
        }
    }
)
async def add_watermark(
    photo: UploadFile = File(...),
    watermark: UploadFile = File(...),
    watermark_service: WatermarkService = Depends(get_watermark_service)
):
    """
        Add a watermark to a photo.
    """
    try:
        _logger.debug(
            "Entering add_watermark route.",
            photo=photo.filename,
            watermark=watermark.filename
        )
        
        validated_photo = await prepare_media(
            photo, MAX_MEDIA_SIZE, CONTENT_TYPES, EXTENSION_TYPES
        )
        validated_watermark = await prepare_media(
            watermark, MAX_MEDIA_SIZE, CONTENT_TYPES, EXTENSION_TYPES
        )

        watermarked_photo = watermark_service.add_watermark(
            validated_photo, validated_watermark
        )

        _logger.debug(
            "Exiting add_watermark route.",
            photo=photo.filename,
            watermark=watermark.filename
        )

        return Response(
            content=watermarked_photo.getvalue(),
            media_type="image/png"
        )
    except WatermarkDimensionsError as e:
        _logger.error(
            e,
            photo=photo.filename,
            watermark=watermark.filename
        )
        raise HTTPException(
            status_code=422,
            detail=e.get_user_msg()
        )
