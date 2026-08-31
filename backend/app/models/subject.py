from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class Subject(Base):
    __tablename__ = "subjects"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    max_consecutive_hours = Column(Integer, nullable=True, default=None)
    max_hours_per_day = Column(Integer, nullable=True, default=None)

    # Relationships
    assignments = relationship("Assignment", back_populates="subject", cascade="all, delete-orphan")
    timetable_slots = relationship("TimetableSlot", back_populates="subject")
    class_constraints = relationship("ClassSubjectConstraint", back_populates="subject", cascade="all, delete-orphan")
