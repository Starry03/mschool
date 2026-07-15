from sqlalchemy.orm import Session
from typing import List
from app.models.timetable_slot import TimetableSlot
from app.schemas.timetable_slot import TimetableSlotCreate

def get_timetable_slots(db: Session) -> List[TimetableSlot]:
    return db.query(TimetableSlot).all()

def get_slots_by_class(db: Session, class_id: int) -> List[TimetableSlot]:
    return db.query(TimetableSlot).filter(TimetableSlot.class_id == class_id).all()

def get_slots_by_teacher(db: Session, teacher_id: int) -> List[TimetableSlot]:
    return db.query(TimetableSlot).filter(TimetableSlot.teacher_id == teacher_id).all()

def clear_timetable(db: Session):
    db.query(TimetableSlot).delete()
    db.commit()

def save_timetable_slots(db: Session, slots_in: List[TimetableSlotCreate]) -> List[TimetableSlot]:
    # Clear existing timetable slots first
    db.query(TimetableSlot).delete()
    
    db_slots = []
    for slot in slots_in:
        db_slot = TimetableSlot(
            day=slot.day,
            hour=slot.hour,
            class_id=slot.class_id,
            teacher_id=slot.teacher_id,
            subject_id=slot.subject_id
        )
        db.add(db_slot)
        db_slots.append(db_slot)
        
    db.commit()
    return db_slots
