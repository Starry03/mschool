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

router = APIRouter()

@router.get("/config", response_model=schemas.AuthConfigResponse)
def read_auth_config():
    """
    Restituisce le configurazioni pubbliche per l'autenticazione Google.
    """
    return schemas.AuthConfigResponse(google_client_id=settings.WEB_CLIENT_ID)

@router.post("/google-login", response_model=schemas.UserSession)
def google_login(
    login_in: schemas.GoogleLoginRequest,
    db: Session = Depends(deps.get_db)
):
    """
    Valida il token Google OAuth, controlla se l'utente esiste nel database,
    crea la sessione in Redis e restituisce il token JWT di sessione.
    """
    id_token_str = login_in.id_token
    access_token_str = login_in.access_token
    email = None

    if not id_token_str and not access_token_str:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Fornire id_token o access_token per l'autenticazione."
        )

    if id_token_str:
        try:
            idinfo = id_token.verify_oauth2_token(
                id_token_str,
                google_requests.Request(),
                settings.WEB_CLIENT_ID
            )
            email = idinfo.get("email")
            if not email:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Il token Google non contiene un indirizzo email valido."
                )
        except ValueError as e:
            if not access_token_str:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail=f"Autenticazione Google (ID Token) fallita: {str(e)}"
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
                if not email:
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="L'access token Google non è associato a un indirizzo email valido."
                    )
            else:
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Autenticazione Google (Access Token) fallita o non valida."
                )
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail=f"Errore durante la verifica con Google: {str(e)}"
            )

    if not email:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Autenticazione Google fallita."
        )

    user = crud.crud_user.get_user_by_email(db, email=email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Account non autorizzato. Contatta l'amministratore per l'abilitazione."
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
    Invalida la sessione dell'utente eliminando il record da Redis.
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
    Restituisce i dati del profilo dell'utente correntemente loggato.
    """
    return current_user
