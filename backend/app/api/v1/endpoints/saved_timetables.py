from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.api import deps
from app import schemas, crud

router = APIRouter()

@router.get("/", response_model=List[schemas.SavedTimetable])
def read_saved_timetables(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 100):
    return crud.crud_saved_timetable.get_saved_timetables(db, skip=skip, limit=limit)

@router.get("/{timetable_id}", response_model=schemas.SavedTimetableDetail)
def read_saved_timetable(timetable_id: int, db: Session = Depends(deps.get_db)):
    db_timetable = crud.crud_saved_timetable.get_saved_timetable(db, timetable_id=timetable_id)
    if not db_timetable:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Saved timetable not found")
    return db_timetable

@router.post("/", response_model=schemas.SavedTimetableDetail, status_code=status.HTTP_201_CREATED)
def create_saved_timetable(timetable_in: schemas.SavedTimetableCreate, db: Session = Depends(deps.get_db)):
    return crud.crud_saved_timetable.create_saved_timetable(db, timetable_in=timetable_in)

@router.delete("/{timetable_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_saved_timetable(timetable_id: int, db: Session = Depends(deps.get_db)):
    success = crud.crud_saved_timetable.delete_saved_timetable(db, timetable_id=timetable_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Saved timetable not found")
    return None

@router.post("/{timetable_id}/restore", status_code=status.HTTP_200_OK)
def restore_saved_timetable(timetable_id: int, db: Session = Depends(deps.get_db)):
    success = crud.crud_saved_timetable.restore_saved_timetable(db, timetable_id=timetable_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Saved timetable not found")
    return {"message": "Timetable restored successfully"}
