from pydantic import BaseModel
from typing import Optional

class SubjectBase(BaseModel):
    name: str
    max_consecutive_hours: Optional[int] = None
    max_hours_per_day: Optional[int] = None

class SubjectCreate(SubjectBase):
    pass

class SubjectUpdate(BaseModel):
    name: Optional[str] = None
    max_consecutive_hours: Optional[int] = None
    max_hours_per_day: Optional[int] = None

class Subject(SubjectBase):
    id: int

    class Config:
        orm_mode = True
