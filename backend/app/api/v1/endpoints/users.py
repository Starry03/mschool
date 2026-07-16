import app.patch_pydantic
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import schemas, crud
from app.api import deps
from app.models.user import User

router = APIRouter()

@router.get("/", response_model=List[schemas.UserResponse])
def read_users(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(deps.get_db),
    current_admin: User = Depends(deps.get_current_admin)
):
    """
    Restituisce la lista di tutti gli utenti registrati. Solo per amministratori.
    """
    return crud.crud_user.get_users(db, skip=skip, limit=limit)

@router.post("/", response_model=schemas.UserResponse, status_code=201)
def create_user(
    user_in: schemas.UserCreate,
    db: Session = Depends(deps.get_db),
    current_admin: User = Depends(deps.get_current_admin)
):
    """
    Crea un nuovo utente abilitato. Solo per amministratori.
    Valida il dominio email per gli utenti non amministratori.
    """
    db_user = crud.crud_user.get_user_by_email(db, email=user_in.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Questo indirizzo email è già registrato nel sistema."
        )
    try:
        return crud.crud_user.create_user(db, user_in)
    except ValueError as ex:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(ex)
        )

@router.delete("/{user_id}", response_model=schemas.UserResponse)
def delete_user(
    user_id: int,
    db: Session = Depends(deps.get_db),
    current_admin: User = Depends(deps.get_current_admin)
):
    """
    Rimuove un utente dal sistema. Solo per amministratori.
    Impedisce all'amministratore di eliminare il proprio account.
    """
    if user_id == current_admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Operazione non consentita: non puoi eliminare il tuo stesso account amministratore."
        )
    
    db_user = crud.crud_user.get_user(db, user_id)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Utente non trovato."
        )
    
    return crud.crud_user.delete_user(db, user_id)
