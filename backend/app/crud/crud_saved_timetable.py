from sqlalchemy.orm import Session
from typing import List, Optional
from app.models.saved_timetable import SavedTimetable
from app.models.saved_timetable_slot import SavedTimetableSlot
from app.models.timetable_slot import TimetableSlot
from app.schemas.saved_timetable import SavedTimetableCreate

def get_saved_timetable(db: Session, timetable_id: int) -> Optional[SavedTimetable]:
    return db.query(SavedTimetable).filter(SavedTimetable.id == timetable_id).first()

def get_saved_timetables(db: Session, skip: int = 0, limit: int = 100) -> List[SavedTimetable]:
    return db.query(SavedTimetable).order_by(SavedTimetable.created_at.desc()).offset(skip).limit(limit).all()

def create_saved_timetable(db: Session, timetable_in: SavedTimetableCreate) -> SavedTimetable:
    db_timetable = SavedTimetable(
        name=timetable_in.name,
        description=timetable_in.description,
        days_per_week=timetable_in.days_per_week,
        hours_per_day=timetable_in.hours_per_day
    )
    db.add(db_timetable)
    db.commit()
    db.refresh(db_timetable)

    # Insert slots
    for slot_in in timetable_in.slots:
        db_slot = SavedTimetableSlot(
            saved_timetable_id=db_timetable.id,
            day=slot_in.day,
            hour=slot_in.hour,
            class_id=slot_in.class_id,
            teacher_id=slot_in.teacher_id,
            subject_id=slot_in.subject_id
        )
        db.add(db_slot)
    
    db.commit()
    db.refresh(db_timetable)
    return db_timetable

def delete_saved_timetable(db: Session, timetable_id: int) -> bool:
    db_timetable = get_saved_timetable(db, timetable_id)
    if not db_timetable:
        return False
    db.delete(db_timetable)
    db.commit()
    return True

def restore_saved_timetable(db: Session, timetable_id: int) -> bool:
    db_timetable = get_saved_timetable(db, timetable_id)
    if not db_timetable:
        return False

    # 1. Clear the active timetable slots
    db.query(TimetableSlot).delete()

    # 2. Copy slots from saved_timetable to timetable_slots
    for saved_slot in db_timetable.slots:
        active_slot = TimetableSlot(
            day=saved_slot.day,
            hour=saved_slot.hour,
            class_id=saved_slot.class_id,
            teacher_id=saved_slot.teacher_id,
            subject_id=saved_slot.subject_id
        )
        db.add(active_slot)
        
    db.commit()
    return True
