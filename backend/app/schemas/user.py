import app.patch_pydantic
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    email: str
    first_name: str
    last_name: str

class UserCreate(UserBase):
    role: str = "user"  # "admin" o "user"

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    role: Optional[str] = None

class UserResponse(UserBase):
    id: int
    role: str
    created_at: datetime

    class Config:
        orm_mode = True

class GoogleLoginRequest(BaseModel):
    id_token: Optional[str] = None
    access_token: Optional[str] = None

class UserSession(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class AuthConfigResponse(BaseModel):
    google_client_id: str
    google_client_id_desktop: Optional[str] = None
    google_client_secret_desktop: Optional[str] = None
    google_client_id_android: Optional[str] = None
    google_client_id_ios: Optional[str] = None
    has_admin: bool = True
