from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.api import deps
from app import schemas, crud

router = APIRouter()

@router.get("/", response_model=List[schemas.Subject])
def read_subjects(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 100):
    return crud.crud_subject.get_subjects(db, skip=skip, limit=limit)

@router.get("/{subject_id}", response_model=schemas.Subject)
def read_subject(subject_id: int, db: Session = Depends(deps.get_db)):
    db_subject = crud.crud_subject.get_subject(db, subject_id)
    if not db_subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    return db_subject

@router.post("/", response_model=schemas.Subject, status_code=status.HTTP_201_CREATED)
def create_subject(subject_in: schemas.SubjectCreate, db: Session = Depends(deps.get_db)):
    db_existing = crud.crud_subject.get_subject_by_name(db, name=subject_in.name)
    if db_existing:
        raise HTTPException(status_code=400, detail="Subject name already exists")
    try:
        return crud.crud_subject.create_subject(db, subject_in)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

@router.put("/{subject_id}", response_model=schemas.Subject)
def update_subject(subject_id: int, subject_in: schemas.SubjectUpdate, db: Session = Depends(deps.get_db)):
    try:
        db_subject = crud.crud_subject.update_subject(db, subject_id=subject_id, subject_in=subject_in)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    if not db_subject:
        raise HTTPException(status_code=404, detail="Subject not found")
    return db_subject

@router.delete("/{subject_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_subject(subject_id: int, db: Session = Depends(deps.get_db)):
    success = crud.crud_subject.delete_subject(db, subject_id)
    if not success:
        raise HTTPException(status_code=404, detail="Subject not found")
    return None
