from pydantic import BaseModel, EmailStr
from typing import List
from app.schemas.teacher_settings import TeacherSettings
from app.schemas.teacher_constraint import TeacherConstraint

class TeacherBase(BaseModel):
    first_name: str
    last_name: str = None
    email: EmailStr = None

class TeacherCreate(TeacherBase):
    pass

class TeacherUpdate(BaseModel):
    first_name: str = None
    last_name: str = None
    email: EmailStr = None

class Teacher(TeacherBase):
    id: int
    settings: TeacherSettings = None
    constraints: List[TeacherConstraint] = []

    class Config:
        orm_mode = True
