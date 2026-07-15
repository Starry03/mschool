from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.class_subject_constraint import ClassSubjectConstraint
from app.schemas.class_subject_constraint import ClassSubjectConstraintCreate

def get_constraint(db: Session, constraint_id: int) -> Optional[ClassSubjectConstraint]:
    return db.query(ClassSubjectConstraint).filter(ClassSubjectConstraint.id == constraint_id).first()

def get_constraint_by_class_and_subject(db: Session, class_id: int, subject_id: int) -> Optional[ClassSubjectConstraint]:
    return db.query(ClassSubjectConstraint).filter(
        ClassSubjectConstraint.class_id == class_id,
        ClassSubjectConstraint.subject_id == subject_id
    ).first()

def get_constraints(db: Session, skip: int = 0, limit: int = 100) -> List[ClassSubjectConstraint]:
    return db.query(ClassSubjectConstraint).offset(skip).limit(limit).all()

def get_constraints_by_class(db: Session, class_id: int) -> List[ClassSubjectConstraint]:
    return db.query(ClassSubjectConstraint).filter(ClassSubjectConstraint.class_id == class_id).all()

def create_constraint(db: Session, constraint_in: ClassSubjectConstraintCreate) -> ClassSubjectConstraint:
    if constraint_in.weekly_hours < 1:
        raise ValueError("Weekly hours must be at least 1")
    if constraint_in.weekly_hours > 40:
        raise ValueError("Weekly hours cannot exceed 40")
        
    db_constraint = ClassSubjectConstraint(
        class_id=constraint_in.class_id,
        subject_id=constraint_in.subject_id,
        weekly_hours=constraint_in.weekly_hours
    )
    db.add(db_constraint)
    db.commit()
    db.refresh(db_constraint)
    return db_constraint

def delete_constraint(db: Session, constraint_id: int) -> bool:
    db_constraint = get_constraint(db, constraint_id)
    if not db_constraint:
        return False
    db.delete(db_constraint)
    db.commit()
    return True
