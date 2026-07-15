from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.api import deps
from app import schemas, crud

router = APIRouter()

@router.get("/", response_model=List[schemas.ClassSubjectConstraintDetail])
def read_constraints(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 100):
    return crud.crud_class_subject_constraint.get_constraints(db, skip=skip, limit=limit)

@router.get("/class/{class_id}", response_model=List[schemas.ClassSubjectConstraintDetail])
def read_constraints_by_class(class_id: int, db: Session = Depends(deps.get_db)):
    return crud.crud_class_subject_constraint.get_constraints_by_class(db, class_id=class_id)

@router.post("/", response_model=schemas.ClassSubjectConstraintDetail, status_code=status.HTTP_201_CREATED)
def create_constraint(constraint_in: schemas.ClassSubjectConstraintCreate, db: Session = Depends(deps.get_db)):
    # Check if a constraint already exists for this class and subject
    db_existing = crud.crud_class_subject_constraint.get_constraint_by_class_and_subject(
        db, class_id=constraint_in.class_id, subject_id=constraint_in.subject_id
    )
    if db_existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A constraint for this class and subject already exists. Please update or delete it first."
        )
    
    # Verify class and subject exist
    db_class = crud.crud_class.get_class(db, constraint_in.class_id)
    if not db_class:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Class not found")
        
    db_subject = crud.crud_subject.get_subject(db, constraint_in.subject_id)
    if not db_subject:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found")
        
    try:
        db_obj = crud.crud_class_subject_constraint.create_constraint(db, constraint_in)
        # Fetch with relationships populated
        return db_obj
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

@router.delete("/{constraint_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_constraint(constraint_id: int, db: Session = Depends(deps.get_db)):
    success = crud.crud_class_subject_constraint.delete_constraint(db, constraint_id)
    if not success:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Constraint not found")
    return None
