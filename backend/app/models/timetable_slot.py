from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base

class TimetableSlot(Base):
    """
    Represents an occupied slot in the generated school timetable.
    """
    __tablename__ = "timetable_slots"

    id = Column(Integer, primary_key=True, index=True)
    day = Column(Integer, nullable=False)
    hour = Column(Integer, nullable=False)
    class_id = Column(Integer, ForeignKey("school_classes.id", ondelete="CASCADE"), nullable=False)
    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False)

    # Relationships
    school_class = relationship("SchoolClass", back_populates="timetable_slots")
    teacher = relationship("Teacher", back_populates="timetable_slots")
    subject = relationship("Subject", back_populates="timetable_slots")

    __table_args__ = (
        # A class cannot take two subjects at the same time
        UniqueConstraint('day', 'hour', 'class_id', name='_class_schedule_uc'),
        # A teacher cannot teach two classes at the same time
        UniqueConstraint('day', 'hour', 'teacher_id', name='_teacher_schedule_uc'),
    )
