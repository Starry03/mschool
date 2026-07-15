from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.api import deps
from app import schemas, crud

router = APIRouter()

@router.get("/", response_model=List[schemas.AssignmentDetail])
def read_assignments(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 100):
    return crud.crud_assignment.get_assignments(db, skip=skip, limit=limit)

@router.get("/{assignment_id}", response_model=schemas.AssignmentDetail)
def read_assignment(assignment_id: int, db: Session = Depends(deps.get_db)):
    db_assignment = crud.crud_assignment.get_assignment(db, assignment_id)
    if not db_assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
    return db_assignment

@router.post("/", response_model=schemas.Assignment, status_code=status.HTTP_201_CREATED)
def create_assignment(assignment_in: schemas.AssignmentCreate, db: Session = Depends(deps.get_db)):
    # Verify related entities exist
    teacher = crud.crud_teacher.get_teacher(db, assignment_in.teacher_id)
    if not teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
        
    school_class = crud.crud_class.get_class(db, assignment_in.class_id)
    if not school_class:
        raise HTTPException(status_code=404, detail="Class not found")
        
    subject = crud.crud_subject.get_subject(db, assignment_in.subject_id)
    if not subject:
        raise HTTPException(status_code=404, detail="Subject not found")
        
    return crud.crud_assignment.create_assignment(db, assignment_in)

@router.put("/{assignment_id}", response_model=schemas.Assignment)
def update_assignment(
    assignment_id: int, 
    assignment_in: schemas.AssignmentUpdate, 
    db: Session = Depends(deps.get_db)
):
    db_assignment = crud.crud_assignment.get_assignment(db, assignment_id)
    if not db_assignment:
        raise HTTPException(status_code=404, detail="Assignment not found")
        
    # Verify new relations if updated
    if assignment_in.teacher_id is not None:
        if not crud.crud_teacher.get_teacher(db, assignment_in.teacher_id):
            raise HTTPException(status_code=404, detail="Teacher not found")
            
    if assignment_in.class_id is not None:
        if not crud.crud_class.get_class(db, assignment_in.class_id):
            raise HTTPException(status_code=404, detail="Class not found")
            
    if assignment_in.subject_id is not None:
        if not crud.crud_subject.get_subject(db, assignment_in.subject_id):
            raise HTTPException(status_code=404, detail="Subject not found")
            
    return crud.crud_assignment.update_assignment(db, assignment_id, assignment_in)

@router.delete("/{assignment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_assignment(assignment_id: int, db: Session = Depends(deps.get_db)):
    success = crud.crud_assignment.delete_assignment(db, assignment_id)
    if not success:
        raise HTTPException(status_code=404, detail="Assignment not found")
    return None
