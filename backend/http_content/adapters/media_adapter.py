"""
	media adapter for handling framework media operations.
"""

#
#   Imports
#

from pathlib import Path
from typing import List
from fastapi import HTTPException, UploadFile, status

# Perso

from models.file import File

#
#   mediaAdapter
#

async def ensure_media_size(media : UploadFile, max_size: int) -> None:
    """
        Ensure the media size is less than the max size.
    """
    content = await media.read()
    await media.seek(0)

    if len(content) > max_size:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="media size is too large."
        )

def ensure_media_type(
    media: UploadFile,
    content_types: List[str],
    extension_types: List[str],
) -> None:
    """
        Ensure the media type is the expected type.
    """
    if media.content_type not in content_types:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="media type is not supported."
        )

    if media.filename \
        and Path(media.filename).suffix.lower() not in extension_types:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="media extension is not supported."
        )

async def upload_media_to_media_types(media: UploadFile) -> File:
    """
        Upload a media to a media types.
    """
    if not media.filename or not media.content_type:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="media name or content type is not provided."
        )

    await media.seek(0)
    content = await media.read()

    return File(
            name=media.filename,
            content_type=media.content_type,
            content=content,
            extension=Path(media.filename).suffix.lower(),
            size=len(content),
            headers=dict(media.headers.items())
        )

async def prepare_media(
    media: UploadFile,
    max_size: int,
    content_types: List[str],
    extension_types: List[str],
) -> File:
    """
        Prepare a media to be handled by the app.
    """
    await ensure_media_size(media, max_size)
    ensure_media_type(media, content_types, extension_types)
    return await upload_media_to_media_types(media)
