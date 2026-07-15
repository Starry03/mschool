from pydantic import BaseModel
from app.schemas.teacher import Teacher
from app.schemas.school_class import SchoolClass
from app.schemas.subject import Subject
from typing import List, Optional

class TimetableSlotBase(BaseModel):
    day: int
    hour: int
    class_id: int
    teacher_id: int
    subject_id: int

class TimetableSlotCreate(TimetableSlotBase):
    pass

class TimetableSlot(TimetableSlotBase):
    id: int

    class Config:
        orm_mode = True

class TimetableSlotDetail(TimetableSlot):
    school_class: SchoolClass
    teacher: Teacher
    subject: Subject

    class Config:
        orm_mode = True

class TimetableGenerateResponse(BaseModel):
    success: bool
    message: str
    timetable: List[TimetableSlotDetail] = []
    error_details: str = None
