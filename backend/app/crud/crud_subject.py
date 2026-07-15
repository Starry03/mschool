from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.subject import Subject
from app.schemas.subject import SubjectCreate, SubjectUpdate

def get_subject(db: Session, subject_id: int) -> Optional[Subject]:
    return db.query(Subject).filter(Subject.id == subject_id).first()

def get_subject_by_name(db: Session, name: str) -> Optional[Subject]:
    return db.query(Subject).filter(Subject.name == name).first()

def get_subjects(db: Session, skip: int = 0, limit: int = 100) -> List[Subject]:
    return db.query(Subject).order_by(Subject.name).offset(skip).limit(limit).all()

def create_subject(db: Session, subject_in: SubjectCreate) -> Subject:
    if not subject_in.name or not subject_in.name.strip():
        raise ValueError("Subject name cannot be empty")
    if len(subject_in.name) > 100:
        raise ValueError("Subject name cannot exceed 100 characters")
    if subject_in.max_consecutive_hours is not None:
        if subject_in.max_consecutive_hours < 1 or subject_in.max_consecutive_hours > 8:
            raise ValueError("max_consecutive_hours must be between 1 and 8")

    db_subject = Subject(
        name=subject_in.name,
        max_consecutive_hours=subject_in.max_consecutive_hours
    )
    db.add(db_subject)
    db.commit()
    db.refresh(db_subject)
    return db_subject

def update_subject(db: Session, subject_id: int, subject_in: SubjectUpdate) -> Optional[Subject]:
    db_subject = get_subject(db, subject_id)
    if not db_subject:
        return None

    update_data = subject_in.dict(exclude_unset=True)

    if "name" in update_data:
        val = update_data["name"]
        if not val or not val.strip():
            raise ValueError("Subject name cannot be empty")
        if len(val) > 100:
            raise ValueError("Subject name cannot exceed 100 characters")
    if "max_consecutive_hours" in update_data and update_data["max_consecutive_hours"] is not None:
        val = update_data["max_consecutive_hours"]
        if val < 1 or val > 8:
            raise ValueError("max_consecutive_hours must be between 1 and 8")

    for key, value in update_data.items():
        setattr(db_subject, key, value)

    db.commit()
    db.refresh(db_subject)
    return db_subject

def delete_subject(db: Session, subject_id: int) -> bool:
    db_subject = get_subject(db, subject_id)
    if not db_subject:
        return False
    db.delete(db_subject)
    db.commit()
    return True
