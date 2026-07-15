from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.api import deps
from app import schemas, crud

router = APIRouter()

@router.get("/", response_model=List[schemas.SchoolClass])
def read_classes(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 100):
    return crud.crud_class.get_classes(db, skip=skip, limit=limit)

@router.get("/{class_id}", response_model=schemas.SchoolClass)
def read_class(class_id: int, db: Session = Depends(deps.get_db)):
    db_class = crud.crud_class.get_class(db, class_id)
    if not db_class:
        raise HTTPException(status_code=404, detail="Class not found")
    return db_class

@router.post("/", response_model=schemas.SchoolClass, status_code=status.HTTP_201_CREATED)
def create_class(class_in: schemas.SchoolClassCreate, db: Session = Depends(deps.get_db)):
    db_existing = crud.crud_class.get_class_by_name(db, name=class_in.name)
    if db_existing:
        raise HTTPException(status_code=400, detail="Class name already exists")
    return crud.crud_class.create_class(db, class_in)

@router.delete("/{class_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_class(class_id: int, db: Session = Depends(deps.get_db)):
    success = crud.crud_class.delete_class(db, class_id)
    if not success:
        raise HTTPException(status_code=404, detail="Class not found")
    return None
