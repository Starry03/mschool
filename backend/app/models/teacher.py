from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class Teacher(Base):
    __tablename__ = "teachers"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String(50), nullable=False)
    last_name = Column(String(50), nullable=True)
    email = Column(String(100), nullable=True)

    # Relationships
    assignments = relationship("Assignment", back_populates="teacher", cascade="all, delete-orphan")
    constraints = relationship("TeacherConstraint", back_populates="teacher", cascade="all, delete-orphan")
    settings = relationship("TeacherSettings", back_populates="teacher", uselist=False, cascade="all, delete-orphan")
    timetable_slots = relationship("TimetableSlot", back_populates="teacher")
