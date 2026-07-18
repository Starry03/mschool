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

    # Redis Settings
    REDIS_HOST: str = Field(default="localhost")
    REDIS_PORT: int = Field(default=6379)

    # JWT Settings
    JWT_SECRET: str = Field(default="change_this_secret_in_production_jwt_secret_12345")
    JWT_ALGORITHM: str = Field(default="HS256")
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = Field(default=60 * 24 * 7)  # 7 giorni

    # Google OAuth Settings
    PROJECT_ID: str = Field(default="")
    WEB_CLIENT_ID: str = Field(default="")
    WEB_CLIENT_SECRET: str = Field(default="")
    DESKTOP_CLIENT_ID: str = Field(default="")
    DESKTOP_CLIENT_SECRET: str = Field(default="")
    ANDROID_CLIENT_ID: str = Field(default="")
    IOS_CLIENT_ID: str = Field(default="")

    # Default Admin Settings
    DEFAULT_ADMIN_EMAIL: str = Field(default="admin@example.com")

    @property
    def DATABASE_URL(self) -> str:
        return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DATABASE}"

    # Allow configuration from .env file
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        extra = "ignore"

settings = Settings()

