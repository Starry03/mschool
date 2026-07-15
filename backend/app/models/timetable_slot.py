from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base

class TimetableSlot(Base):
    """
    Rappresenta uno slot occupato nell'orario scolastico generato.
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
        # Una classe non può fare due materie contemporaneamente
        UniqueConstraint('day', 'hour', 'class_id', name='_class_schedule_uc'),
        # Un insegnante non può insegnare a due classi contemporaneamente
        UniqueConstraint('day', 'hour', 'teacher_id', name='_teacher_schedule_uc'),
    )
