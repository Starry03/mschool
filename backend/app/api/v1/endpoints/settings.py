from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app import schemas, crud

router = APIRouter()

@router.get("/", response_model=schemas.SchoolSettings)
def read_school_settings(db: Session = Depends(deps.get_db)):
    return crud.crud_settings.get_school_settings(db)

@router.put("/", response_model=schemas.SchoolSettings)
def update_school_settings(settings_in: schemas.SchoolSettingsUpdate, db: Session = Depends(deps.get_db)):
    try:
        return crud.crud_settings.update_school_settings(db, settings_in)
    except ValueError as ex:
        raise HTTPException(status_code=400, detail=str(ex))
