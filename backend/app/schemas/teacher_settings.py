from pydantic import BaseModel
from typing import Optional

class TeacherSettingsBase(BaseModel):
    max_consecutive_hours: int = 3
    max_hours_per_day: int = 5
    prefer_consecutive: bool = False

class TeacherSettingsCreate(TeacherSettingsBase):
    pass

class TeacherSettingsUpdate(TeacherSettingsBase):
    pass

class TeacherSettings(TeacherSettingsBase):
    teacher_id: int

    class Config:
        orm_mode = True
