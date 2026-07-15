from pydantic import BaseModel
from typing import Optional

class SchoolClassBase(BaseModel):
    name: str

class SchoolClassCreate(SchoolClassBase):
    pass

class SchoolClassUpdate(SchoolClassBase):
    pass

class SchoolClass(SchoolClassBase):
    id: int

    class Config:
        orm_mode = True
