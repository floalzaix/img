"""
    Handles watermarking domain logic and operations.
"""

#
#   Imports
#

import io
import numpy as np

from PIL import Image

# Perso

from models.file import File
from exceptions.watermark_errors import WatermarkDimensionsError
from config.settings import settings

#
#   WatermarkService
#

class WatermarkService:
    """
        Handles watermarking operations.
    """

    def add_watermark(self, base_photo: File, watermark: File) -> io.BytesIO:
        # Loading images
        base_photo_image = Image.open(
            io.BytesIO(base_photo.content)
        ).convert("RGB")
        watermark_image = Image.open(
            io.BytesIO(watermark.content)
        ).convert("RGB")

        # Checking dimensions
        p_w = base_photo_image.width
        p_h = base_photo_image.height
        w_w = watermark_image.width
        w_h = watermark_image.height

        if p_w < w_w or p_h < w_h:
            raise WatermarkDimensionsError(
                source="WatermarkService.add_watermark"
            )

        #
        #   Applying watermark using numpy for performance
        #

        base_photo_array = np.array(base_photo_image)
        watermark_array = np.array(watermark_image)

        nuanced_watermark_array = (
            watermark_array / 255 * settings.WATERMARK_INTENSITY
        ).astype(np.uint8)

        padded_watermark_array = np.pad(
            nuanced_watermark_array,
            ((0, p_h - w_h), (0, p_w - w_w), (0, 0)),
            mode="constant",
            constant_values=0
        )

        # Applying watermark
        base_photo_array = base_photo_array + padded_watermark_array

        # Exporting image
        base_photo_image = Image.fromarray(base_photo_array)
        buffer = io.BytesIO()
        base_photo_image.save(buffer, format="PNG")
        buffer.seek(0)

        return buffer