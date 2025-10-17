"""
    Handles all the settings of the app using the .env file.
"""

#
#   Imports
#

from pydantic_settings import BaseSettings
from pydantic import Field
from typing import List
from enum import Enum 

# Perso

#
#   Settings
#

class Environnement(str, Enum):
    DEV = "dev"
    PROD = "prod"

class LoggingLevel(str, Enum):
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"

class Settings(BaseSettings):
    #
    #   General
    #
    
    ENV: Environnement = Field(
        default=Environnement.DEV,
        description="The current app environnement usage"
    )

    PROD_CORS_ORIGINS: List[str] = Field(
        [],
        description="The origins allowed to access the app in production"
    )

    LOGGING_LEVEL: LoggingLevel = Field(
        default=LoggingLevel.DEBUG,
        description="The logging level of the app"
    )

    WATERMARK_INTENSITY: int = Field(
        default=4,
        description="The intensity of the watermark"
    )

    #
    #   Config
    #
    
    model_config = {
        "env_file": ".env",
        "case_sensitive": True,
    }

def get_settings() -> Settings:
    return Settings() # type: ignore

settings = get_settings()