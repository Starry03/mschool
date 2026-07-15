from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.assignment import Assignment
from app.schemas.assignment import AssignmentCreate, AssignmentUpdate

def get_assignment(db: Session, assignment_id: int) -> Optional[Assignment]:
    return db.query(Assignment).filter(Assignment.id == assignment_id).first()

def get_assignments(db: Session, skip: int = 0, limit: int = 100) -> List[Assignment]:
    return db.query(Assignment).offset(skip).limit(limit).all()

def get_assignments_by_class(db: Session, class_id: int) -> List[Assignment]:
    return db.query(Assignment).filter(Assignment.class_id == class_id).all()

def get_assignments_by_teacher(db: Session, teacher_id: int) -> List[Assignment]:
    return db.query(Assignment).filter(Assignment.teacher_id == teacher_id).all()

def create_assignment(db: Session, assignment_in: AssignmentCreate) -> Assignment:
    if assignment_in.weekly_hours < 1 or assignment_in.weekly_hours > 48:
        raise ValueError("Weekly hours must be between 1 and 48")
        
    db_assignment = Assignment(
        teacher_id=assignment_in.teacher_id,
        class_id=assignment_in.class_id,
        subject_id=assignment_in.subject_id,
        weekly_hours=assignment_in.weekly_hours
    )
    db.add(db_assignment)
    db.commit()
    db.refresh(db_assignment)
    return db_assignment

def update_assignment(db: Session, assignment_id: int, assignment_in: AssignmentUpdate) -> Optional[Assignment]:
    db_assignment = get_assignment(db, assignment_id)
    if not db_assignment:
        return None
    
    update_data = assignment_in.dict(exclude_unset=True)
    
    # Validation
    if "weekly_hours" in update_data:
        val = update_data["weekly_hours"]
        if val < 1 or val > 48:
            raise ValueError("Weekly hours must be between 1 and 48")
            
    for key, value in update_data.items():
        setattr(db_assignment, key, value)
        
    db.commit()
    db.refresh(db_assignment)
    return db_assignment

def delete_assignment(db: Session, assignment_id: int) -> bool:
    db_assignment = get_assignment(db, assignment_id)
    if not db_assignment:
        return False
    db.delete(db_assignment)
    db.commit()
    return True
