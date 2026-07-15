from pydantic import BaseModel
from datetime import datetime
from typing import List, Optional
from app.schemas.school_class import SchoolClass
from app.schemas.teacher import Teacher
from app.schemas.subject import Subject

class SavedTimetableSlotBase(BaseModel):
    day: int
    hour: int
    class_id: int
    teacher_id: int
    subject_id: int

class SavedTimetableSlotCreate(SavedTimetableSlotBase):
    pass

class SavedTimetableSlot(SavedTimetableSlotBase):
    id: int
    saved_timetable_id: int

    class Config:
        orm_mode = True

class SavedTimetableSlotDetail(SavedTimetableSlot):
    school_class: SchoolClass
    teacher: Teacher
    subject: Subject

    class Config:
        orm_mode = True

class SavedTimetableBase(BaseModel):
    name: str
    description: Optional[str] = None
    days_per_week: int
    hours_per_day: int

class SavedTimetableCreate(SavedTimetableBase):
    slots: List[SavedTimetableSlotCreate]

class SavedTimetable(SavedTimetableBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

class SavedTimetableDetail(SavedTimetable):
    slots: List[SavedTimetableSlotDetail]

    class Config:
        orm_mode = True
