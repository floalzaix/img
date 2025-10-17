"""
    Defines dependency injection utilities and common dependencies.
"""

#
#   Imports
#

# Perso

from services.watermark_service import WatermarkService

#
#   Dependencies
#

def get_watermark_service() -> WatermarkService:
    return WatermarkService()
