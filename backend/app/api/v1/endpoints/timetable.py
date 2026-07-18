from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from app.api import deps
from app import schemas, crud
from app.services.solver import generate_timetable
from app.core.rate_limiter import solver_rate_limiter

router = APIRouter()

@router.post("/generate", response_model=schemas.TimetableGenerateResponse, dependencies=[Depends(solver_rate_limiter)])
def run_generate_timetable(max_time_seconds: float = 10.0, db: Session = Depends(deps.get_db)):
    # Run the solver service
    success, message, slots_data, error_details = generate_timetable(db, max_time_seconds)
    
    if not success:
        return schemas.TimetableGenerateResponse(
            success=False,
            message=message,
            error_details=error_details,
            timetable=[]
        )
        
    # Convert dictionaries to TimetableSlotCreate
    slots_create = [
        schemas.TimetableSlotCreate(**s) for s in slots_data
    ]
    
    # Save to database (overwriting previous timetable)
    db_slots = crud.crud_timetable.save_timetable_slots(db, slots_create)
    
    # Reload slots with relations (details)
    # SQLAlchemy will fetch relationships like school_class, teacher, subject automatically
    # since we query the newly inserted slots and they are linked to the session.
    # To be safe, we query the db_slots IDs
    db_slots_detailed = (
        db.query(crud.crud_timetable.TimetableSlot)
        .filter(crud.crud_timetable.TimetableSlot.id.in_([s.id for s in db_slots]))
        .all()
    )
    
    return schemas.TimetableGenerateResponse(
        success=True,
        message=message,
        timetable=db_slots_detailed
    )

@router.get("/", response_model=List[schemas.TimetableSlotDetail])
def read_timetable(db: Session = Depends(deps.get_db)):
    return crud.crud_timetable.get_timetable_slots(db)

@router.get("/class/{class_id}", response_model=List[schemas.TimetableSlotDetail])
def read_timetable_by_class(class_id: int, db: Session = Depends(deps.get_db)):
    # Verify class exists
    if not crud.crud_class.get_class(db, class_id):
        raise HTTPException(status_code=404, detail="Class not found")
    return crud.crud_timetable.get_slots_by_class(db, class_id)

@router.get("/teacher/{teacher_id}", response_model=List[schemas.TimetableSlotDetail])
def read_timetable_by_teacher(teacher_id: int, db: Session = Depends(deps.get_db)):
    # Verify teacher exists
    if not crud.crud_teacher.get_teacher(db, teacher_id):
        raise HTTPException(status_code=404, detail="Teacher not found")
    return crud.crud_timetable.get_slots_by_teacher(db, teacher_id)

@router.delete("/", status_code=status.HTTP_204_NO_CONTENT)
def clear_timetable(db: Session = Depends(deps.get_db)):
    crud.crud_timetable.clear_timetable(db)
    return None
