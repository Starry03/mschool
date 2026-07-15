from pydantic import BaseModel

class TeacherConstraintBase(BaseModel):
    day: int
    hour: int

class TeacherConstraintCreate(TeacherConstraintBase):
    pass

class TeacherConstraint(TeacherConstraintBase):
    id: int
    teacher_id: int

    class Config:
        orm_mode = True
