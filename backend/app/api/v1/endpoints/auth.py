import app.patch_pydantic
import uuid
import jwt
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from google.oauth2 import id_token
from google.auth.transport import requests as google_requests

from app import schemas, crud
from app.api import deps
from app.core.config import settings
from app.core.redis import redis_session
from app.models.user import User
from app.core.rate_limiter import auth_rate_limiter

router = APIRouter()

@router.get("/config", response_model=schemas.AuthConfigResponse)
def get_auth_config(db: Session = Depends(deps.get_db)):
    """Exposes public client configurations for login (Google Client IDs) and initial setup status."""
    has_admin = db.query(User).filter(User.role == "admin").count() > 0
    return schemas.AuthConfigResponse(
        google_client_id=settings.WEB_CLIENT_ID,
        google_client_id_desktop=settings.DESKTOP_CLIENT_ID,
        google_client_secret_desktop=settings.DESKTOP_CLIENT_SECRET,
        google_client_id_android=settings.ANDROID_CLIENT_ID,
        google_client_id_ios=settings.IOS_CLIENT_ID,
        has_admin=has_admin,
    )

@router.post("/google-login", response_model=schemas.UserSession, dependencies=[Depends(auth_rate_limiter)])
def google_login(
    login_in: schemas.GoogleLoginRequest,
    db: Session = Depends(deps.get_db)
):
    """
    Validates the Google OAuth token, checks if the user exists in the database,
    creates the session in Redis, and returns the session JWT token.
    If no admin exists in the database, the first user to log in automatically becomes Admin.
    """
    id_token_str = login_in.id_token
    access_token_str = login_in.access_token
    email = None
    first_name = ""
    last_name = ""

    if not id_token_str and not access_token_str:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide either id_token or access_token for authentication."
        )

    if id_token_str:
        try:
            valid_audiences = {
                cid.strip() for cid in [
                    settings.WEB_CLIENT_ID,
                    settings.DESKTOP_CLIENT_ID,
                    settings.ANDROID_CLIENT_ID,
                    settings.IOS_CLIENT_ID
                ] if cid and cid.strip()
            }
            idinfo = id_token.verify_oauth2_token(
                id_token_str,
                google_requests.Request()
            )
            # Verify that audience matches at least one of our configured Google Client IDs (if configured)
            token_aud = idinfo.get("aud")
            if valid_audiences and token_aud not in valid_audiences:
                raise ValueError(f"Token audience '{token_aud}' does not match any configured Client IDs.")

            email = idinfo.get("email")
            first_name = idinfo.get("given_name", "")
            last_name = idinfo.get("family_name", "")
            if not email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Google token does not contain a valid email address."
                )
        except ValueError as e:
            if not access_token_str:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Google authentication (ID Token) failed: {str(e)}"
                )

    if not email and access_token_str:
        try:
            import requests
            resp = requests.get(
                "https://www.googleapis.com/oauth2/v3/userinfo",
                headers={"Authorization": f"Bearer {access_token_str}"},
                timeout=5
            )
            if resp.status_code == 200:
                user_info = resp.json()
                email = user_info.get("email")
                first_name = user_info.get("given_name", "")
                last_name = user_info.get("family_name", "")
                if not email:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Google access token is not associated with a valid email address."
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Google authentication (Access Token) failed or invalid."
                )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Error during Google verification: {str(e)}"
            )

    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google authentication failed."
        )

    user = crud.crud_user.get_user_by_email(db, email=email)
    if not user:
        # Check if this is the first setup (no admin registered yet)
        admin_count = db.query(User).filter(User.role == "admin").count()
        is_first_run_admin = (admin_count == 0)

        if is_first_run_admin:
            # First-time initial setup: grant the first Google user the 'admin' role!
            email_parts = email.split("@")[0].split(".")
            f_name = first_name.strip() if first_name else email_parts[0].capitalize()
            l_name = last_name.strip() if last_name else (email_parts[1].capitalize() if len(email_parts) > 1 else "Admin")
            
            user_in = schemas.UserCreate(
                email=email,
                first_name=f_name,
                last_name=l_name,
                role="admin"
            )
            try:
                user = crud.crud_user.create_user(db, user_in)
            except ValueError as ex:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=str(ex)
                )
        else:
            # Regular user registration check against allowed_domain
            school_settings = crud.crud_settings.get_school_settings(db)
            allowed_domain = school_settings.allowed_domain
            is_allowed = False
            if allowed_domain:
                domain = allowed_domain.strip().lower()
                if domain and email.strip().lower().endswith(f"@{domain}"):
                    is_allowed = True
            
            if is_allowed:
                email_parts = email.split("@")[0].split(".")
                f_name = first_name.strip() if first_name else email_parts[0].capitalize()
                l_name = last_name.strip() if last_name else (email_parts[1].capitalize() if len(email_parts) > 1 else "User")
                
                user_in = schemas.UserCreate(
                    email=email,
                    first_name=f_name,
                    last_name=l_name,
                    role="user"
                )
                try:
                    user = crud.crud_user.create_user(db, user_in)
                except ValueError as ex:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=str(ex)
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Account not authorized. Contact the administrator for activation."
                )

    session_id = str(uuid.uuid4())
    session_data = {
        "id": user.id,
        "email": user.email,
        "role": user.role
    }

    expire_seconds = settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES * 60
    redis_session.create_session(session_id, session_data, expire_seconds)

    jwt_payload = {
        "sub": user.email,
        "session_id": session_id,
        "exp": datetime.utcnow() + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
    }
    access_token = jwt.encode(
        jwt_payload,
        settings.JWT_SECRET,
        algorithm=settings.JWT_ALGORITHM
    )

    return schemas.UserSession(
        access_token=access_token,
        token_type="bearer",
        user=user
    )

@router.post("/logout", status_code=204)
def logout(
    credentials: HTTPAuthorizationCredentials = Depends(deps.security_scheme),
    current_user: User = Depends(deps.get_current_user)
):
    """
    Invalidates the user session by deleting the record from Redis.
    """
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        session_id = payload.get("session_id")
        if session_id:
            redis_session.delete_session(session_id)
    except Exception:
        pass
    return

@router.get("/me", response_model=schemas.UserResponse)
def read_current_user(current_user: User = Depends(deps.get_current_user)):
    """
    Returns the profile data of the currently logged-in user.
    """
    return current_user
