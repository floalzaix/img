"""
    Defines file data models and schemas.
"""

#
#   Imports
#

from pydantic import BaseModel, Field
from typing import Dict

# Perso

#
#   File
#

class File(BaseModel):
    name: str = Field(
        ..., description="The name of the file"
    )
    content: bytes = Field(
        ..., description="The content of the file"
    )
    content_type: str = Field(
        ..., description="The content type of the file"
    )
    extension: str = Field(
        ..., description="The extension of the file"
    )
    size: int = Field(
        ..., description="The size of the file"
    )
    headers: Dict[str, str] = Field(
        ..., description="The headers of the file"
    )
