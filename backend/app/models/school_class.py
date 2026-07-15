from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import relationship
from app.core.database import Base

class SchoolClass(Base):
    __tablename__ = "school_classes"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False, index=True)

    # Relationships
    assignments = relationship("Assignment", back_populates="school_class", cascade="all, delete-orphan")
    timetable_slots = relationship("TimetableSlot", back_populates="school_class", cascade="all, delete-orphan")
    subject_constraints = relationship("ClassSubjectConstraint", back_populates="school_class", cascade="all, delete-orphan")
