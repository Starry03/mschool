from sqlalchemy.orm import Session
from sqlalchemy import text
from app.models.teacher import Teacher
from app.models.teacher_settings import TeacherSettings
from app.models.teacher_constraint import TeacherConstraint
from app.models.school_class import SchoolClass
from app.models.subject import Subject
from app.models.assignment import Assignment
from app.models.timetable_slot import TimetableSlot
from app.models.class_subject_constraint import ClassSubjectConstraint
from app.models.saved_timetable import SavedTimetable
from app.models.saved_timetable_slot import SavedTimetableSlot

def check_db_health(db: Session) -> bool:
    try:
        # Run a simple query to verify database connection
        db.execute(text("SELECT 1"))
        return True
    except Exception:
        return False

def clear_entire_database(db: Session):
    # Relies on database-level ON DELETE CASCADE constraints, but deletes in order for safety
    db.query(TimetableSlot).delete()
    db.query(SavedTimetableSlot).delete()
    db.query(SavedTimetable).delete()
    db.query(Assignment).delete()
    db.query(ClassSubjectConstraint).delete()
    db.query(TeacherConstraint).delete()
    db.query(TeacherSettings).delete()
    db.query(Teacher).delete()
    db.query(SchoolClass).delete()
    db.query(Subject).delete()
    db.commit()

def clear_specific_table(db: Session, table_name: str) -> bool:
    """
    Clears a specific table. Relies on ON DELETE CASCADE constraints configured in the database.
    Returns True if table was cleared, False if table name is invalid.
    """
    table_mapping = {
        "teachers": Teacher,
        "classes": SchoolClass,
        "subjects": Subject,
        "assignments": Assignment,
        "timetable": TimetableSlot,
        "subject_constraints": ClassSubjectConstraint,
        "saved_timetables": SavedTimetable
    }
    
    name = table_name.lower().strip()
    if name not in table_mapping:
        return False
        
    db.query(table_mapping[name]).delete()
    db.commit()
    return True
