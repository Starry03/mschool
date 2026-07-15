from pydantic import BaseModel
from typing import Optional
from app.schemas.school_class import SchoolClass
from app.schemas.subject import Subject

class ClassSubjectConstraintBase(BaseModel):
    class_id: int
    subject_id: int
    weekly_hours: int

class ClassSubjectConstraintCreate(ClassSubjectConstraintBase):
    pass

class ClassSubjectConstraint(ClassSubjectConstraintBase):
    id: int

    class Config:
        orm_mode = True

class ClassSubjectConstraintDetail(ClassSubjectConstraint):
    school_class: SchoolClass
    subject: Subject

    class Config:
        orm_mode = True
