import os
import app.patch_pydantic
from pydantic import BaseSettings, Field

class Settings(BaseSettings):
    PROJECT_NAME: str = "School Timetable Generator"
    API_V1_STR: str = "/api/v1"
    
    # Database Settings
    MYSQL_USER: str = Field(default="school_user")
    MYSQL_PASSWORD: str = Field(default="school_pass")
    MYSQL_HOST: str = Field(default="localhost")
    MYSQL_PORT: str = Field(default="3306")
    MYSQL_DATABASE: str = Field(default="school_db")

    @property
    def DATABASE_URL(self) -> str:
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"

    # Allow configuration from .env file
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()
