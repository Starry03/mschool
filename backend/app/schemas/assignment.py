from pydantic import BaseModel
from typing import Optional
from app.schemas.teacher import Teacher
from app.schemas.school_class import SchoolClass
from app.schemas.subject import Subject

class AssignmentBase(BaseModel):
    teacher_id: int
    class_id: int
    subject_id: int
    weekly_hours: int

class AssignmentCreate(AssignmentBase):
    pass

class AssignmentUpdate(BaseModel):
    teacher_id: int = None
    class_id: int = None
    subject_id: int = None
    weekly_hours: int = None

class Assignment(AssignmentBase):
    id: int

    class Config:
        orm_mode = True

class AssignmentDetail(Assignment):
    teacher: Teacher
    school_class: SchoolClass
    subject: Subject

    class Config:
        orm_mode = True
