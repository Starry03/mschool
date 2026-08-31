import app.patch_pydantic
from pydantic import BaseModel
from typing import Optional

class SystemVersionResponse(BaseModel):
    app_name: str
    version: str
    api_version: str
    environment: str = "production"
    status: str = "healthy"

class SystemHealthResponse(BaseModel):
    status: str
    version: str
    database: str

