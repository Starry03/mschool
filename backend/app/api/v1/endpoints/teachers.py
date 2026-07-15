from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.api import deps
from app import schemas, crud

router = APIRouter()

@router.get("/", response_model=List[schemas.Teacher])
def read_teachers(db: Session = Depends(deps.get_db), skip: int = 0, limit: int = 100):
    return crud.crud_teacher.get_teachers(db, skip=skip, limit=limit)

@router.get("/{teacher_id}", response_model=schemas.Teacher)
def read_teacher(teacher_id: int, db: Session = Depends(deps.get_db)):
    db_teacher = crud.crud_teacher.get_teacher(db, teacher_id)
    if not db_teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return db_teacher

@router.post("/", response_model=schemas.Teacher, status_code=status.HTTP_201_CREATED)
def create_teacher(teacher_in: schemas.TeacherCreate, db: Session = Depends(deps.get_db)):
    return crud.crud_teacher.create_teacher(db, teacher_in)

@router.put("/{teacher_id}", response_model=schemas.Teacher)
def update_teacher(teacher_id: int, teacher_in: schemas.TeacherUpdate, db: Session = Depends(deps.get_db)):
    db_teacher = crud.crud_teacher.update_teacher(db, teacher_id, teacher_in)
    if not db_teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return db_teacher

@router.delete("/{teacher_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_teacher(teacher_id: int, db: Session = Depends(deps.get_db)):
    success = crud.crud_teacher.delete_teacher(db, teacher_id)
    if not success:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return None

# Settings
@router.get("/{teacher_id}/settings", response_model=schemas.TeacherSettings)
def read_teacher_settings(teacher_id: int, db: Session = Depends(deps.get_db)):
    db_settings = crud.crud_teacher.get_teacher_settings(db, teacher_id)
    if not db_settings:
        raise HTTPException(status_code=404, detail="Settings not found for this teacher")
    return db_settings

@router.put("/{teacher_id}/settings", response_model=schemas.TeacherSettings)
def update_teacher_settings(
    teacher_id: int, 
    settings_in: schemas.TeacherSettingsUpdate, 
    db: Session = Depends(deps.get_db)
):
    db_teacher = crud.crud_teacher.get_teacher(db, teacher_id)
    if not db_teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return crud.crud_teacher.update_teacher_settings(db, teacher_id, settings_in)

# Constraints
@router.get("/{teacher_id}/constraints", response_model=List[schemas.TeacherConstraint])
def read_teacher_constraints(teacher_id: int, db: Session = Depends(deps.get_db)):
    db_teacher = crud.crud_teacher.get_teacher(db, teacher_id)
    if not db_teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return crud.crud_teacher.get_teacher_constraints(db, teacher_id)

@router.put("/{teacher_id}/constraints", response_model=List[schemas.TeacherConstraint])
def sync_teacher_constraints(
    teacher_id: int,
    constraints_in: List[schemas.TeacherConstraintCreate],
    db: Session = Depends(deps.get_db)
):
    db_teacher = crud.crud_teacher.get_teacher(db, teacher_id)
    if not db_teacher:
        raise HTTPException(status_code=404, detail="Teacher not found")
    return crud.crud_teacher.sync_teacher_constraints(db, teacher_id, constraints_in)
