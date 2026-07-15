from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.school_class import SchoolClass
from app.schemas.school_class import SchoolClassCreate

def get_class(db: Session, class_id: int) -> Optional[SchoolClass]:
    return db.query(SchoolClass).filter(SchoolClass.id == class_id).first()

def get_class_by_name(db: Session, name: str) -> Optional[SchoolClass]:
    return db.query(SchoolClass).filter(SchoolClass.name == name).first()

def get_classes(db: Session, skip: int = 0, limit: int = 100) -> List[SchoolClass]:
    return db.query(SchoolClass).order_by(SchoolClass.name).offset(skip).limit(limit).all()

def create_class(db: Session, class_in: SchoolClassCreate) -> SchoolClass:
    if not class_in.name or not class_in.name.strip():
        raise ValueError("Class name cannot be empty")
    if len(class_in.name) > 50:
        raise ValueError("Class name cannot exceed 50 characters")
        
    db_class = SchoolClass(name=class_in.name)
    db.add(db_class)
    db.commit()
    db.refresh(db_class)
    return db_class

def delete_class(db: Session, class_id: int) -> bool:
    db_class = get_class(db, class_id)
    if not db_class:
        return False
    db.delete(db_class)
    db.commit()
    return True
