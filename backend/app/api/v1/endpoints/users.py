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
    Returns the list of all registered users. Only for administrators.
    """
    return crud.crud_user.get_users(db, skip=skip, limit=limit)

@router.post("/", response_model=schemas.UserResponse, status_code=201)
def create_user(
    user_in: schemas.UserCreate,
    db: Session = Depends(deps.get_db),
    current_admin: User = Depends(deps.get_current_admin)
):
    """
    Creates a new enabled user. Only for administrators.
    Validates the email domain for non-admin users.
    """
    db_user = crud.crud_user.get_user_by_email(db, email=user_in.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This email address is already registered in the system."
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
    Removes a user from the system. Only for administrators.
    Prevents the administrator from deleting their own account.
    """
    if user_id == current_admin.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Operation not allowed: you cannot delete your own admin account."
        )
    
    db_user = crud.crud_user.get_user(db, user_id)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found."
        )
    
    return crud.crud_user.delete_user(db, user_id)
