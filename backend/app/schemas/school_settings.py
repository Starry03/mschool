from pydantic import BaseModel

class SchoolSettingsBase(BaseModel):
    days_per_week: int = 5
    hours_per_day: int = 6

class SchoolSettingsCreate(SchoolSettingsBase):
    pass

class SchoolSettingsUpdate(SchoolSettingsBase):
    pass

class SchoolSettings(SchoolSettingsBase):
    id: int

    class Config:
        orm_mode = True
