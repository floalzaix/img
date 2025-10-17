"""
    Defines watermark-specific exception classes.
"""

#
#   Imports
#

# Perso

from exceptions.base import Base

#
#   Watermark Errors
#

class WatermarkDimensionsError(Base):
    def __init__(self, source: str):
        super().__init__(
            err_msg=(
                "Watermark dimensions error. "
                "(Base image must be bigger than the watermark image.)"
            ),
            user_msg_title="Invalid images dimensions.",
            user_msg_detail=(
                "Make sure the base image is bigger than the watermark image."
            ),
            source=source
        )
