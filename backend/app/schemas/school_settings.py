from pydantic import BaseModel
from typing import Optional

class SchoolSettingsBase(BaseModel):
    days_per_week: int = 5
    hours_per_day: int = 6
    allowed_domain: Optional[str] = None

class SchoolSettingsCreate(SchoolSettingsBase):
    pass

class SchoolSettingsUpdate(SchoolSettingsBase):
    pass

class SchoolSettings(SchoolSettingsBase):
    id: int

    class Config:
        orm_mode = True

