from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.teacher import Teacher
from app.models.teacher_settings import TeacherSettings
from app.models.teacher_constraint import TeacherConstraint
from app.schemas.teacher import TeacherCreate, TeacherUpdate
from app.schemas.teacher_settings import TeacherSettingsUpdate
from app.schemas.teacher_constraint import TeacherConstraintCreate

def get_teacher(db: Session, teacher_id: int) -> Optional[Teacher]:
    return db.query(Teacher).filter(Teacher.id == teacher_id).first()

def get_teachers(db: Session, skip: int = 0, limit: int = 100) -> List[Teacher]:
    return db.query(Teacher).order_by(Teacher.last_name, Teacher.first_name).offset(skip).limit(limit).all()

def create_teacher(db: Session, teacher_in: TeacherCreate) -> Teacher:
    # Validation
    if not teacher_in.first_name or not teacher_in.first_name.strip():
        raise ValueError("First name cannot be empty")
    if len(teacher_in.first_name) > 50:
        raise ValueError("First name cannot exceed 50 characters")
    if teacher_in.last_name and len(teacher_in.last_name) > 50:
        raise ValueError("Last name cannot exceed 50 characters")

    # Create teacher
    db_teacher = Teacher(
        first_name=teacher_in.first_name,
        last_name=teacher_in.last_name,
        email=teacher_in.email
    )
    db.add(db_teacher)
    db.commit()
    db.refresh(db_teacher)
    
    # Initialize default settings for this teacher
    db_settings = TeacherSettings(
        teacher_id=db_teacher.id,
        max_consecutive_hours=3,
        max_hours_per_day=5
    )
    db.add(db_settings)
    db.commit()
    db.refresh(db_teacher)
    
    return db_teacher

def update_teacher(db: Session, teacher_id: int, teacher_in: TeacherUpdate) -> Optional[Teacher]:
    db_teacher = get_teacher(db, teacher_id)
    if not db_teacher:
        return None
    
    update_data = teacher_in.dict(exclude_unset=True)
    
    # Validation
    if "first_name" in update_data:
        val = update_data["first_name"]
        if not val or not val.strip():
            raise ValueError("First name cannot be empty")
        if len(val) > 50:
            raise ValueError("First name cannot exceed 50 characters")
    if "last_name" in update_data:
        val = update_data["last_name"]
        if val and len(val) > 50:
            raise ValueError("Last name cannot exceed 50 characters")

    for key, value in update_data.items():
        setattr(db_teacher, key, value)
        
    db.commit()
    db.refresh(db_teacher)
    return db_teacher

def delete_teacher(db: Session, teacher_id: int) -> bool:
    db_teacher = get_teacher(db, teacher_id)
    if not db_teacher:
        return False
    db.delete(db_teacher)
    db.commit()
    return True

# Teacher Settings Operations
def get_teacher_settings(db: Session, teacher_id: int) -> Optional[TeacherSettings]:
    return db.query(TeacherSettings).filter(TeacherSettings.teacher_id == teacher_id).first()

def update_teacher_settings(db: Session, teacher_id: int, settings_in: TeacherSettingsUpdate) -> Optional[TeacherSettings]:
    db_settings = get_teacher_settings(db, teacher_id)
    if not db_settings:
        # If it doesn't exist, create it
        db_settings = TeacherSettings(teacher_id=teacher_id)
        db.add(db_settings)
        
    update_data = settings_in.dict(exclude_unset=True)
    
    # Validation
    if "max_consecutive_hours" in update_data:
        val = update_data["max_consecutive_hours"]
        if val < 1 or val > 8:
            raise ValueError("Max consecutive hours must be between 1 and 8")
    if "max_hours_per_day" in update_data:
        val = update_data["max_hours_per_day"]
        if val < 1 or val > 8:
            raise ValueError("Max hours per day must be between 1 and 8")

    for key, value in update_data.items():
        setattr(db_settings, key, value)
        
    db.commit()
    db.refresh(db_settings)
    return db_settings

# Teacher Constraints Operations
def get_teacher_constraints(db: Session, teacher_id: int) -> List[TeacherConstraint]:
    return db.query(TeacherConstraint).filter(TeacherConstraint.teacher_id == teacher_id).all()

def sync_teacher_constraints(db: Session, teacher_id: int, constraints_in: List[TeacherConstraintCreate]) -> List[TeacherConstraint]:
    # Delete existing constraints
    db.query(TeacherConstraint).filter(TeacherConstraint.teacher_id == teacher_id).delete()
    
    # Add new ones
    new_constraints = []
    for c in constraints_in:
        # Validation
        if c.day < 0 or c.day > 5:
            raise ValueError("Day must be between 0 (Monday) and 5 (Saturday)")
        if c.hour < 0 or c.hour > 7:
            raise ValueError("Hour must be between 0 and 7")

        db_constraint = TeacherConstraint(
            teacher_id=teacher_id,
            day=c.day,
            hour=c.hour
        )
        db.add(db_constraint)
        new_constraints.append(db_constraint)
        
    db.commit()
    return new_constraints
