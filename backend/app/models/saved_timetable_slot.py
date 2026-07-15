from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class SavedTimetableSlot(Base):
    __tablename__ = "saved_timetable_slots"

    id = Column(Integer, primary_key=True, index=True)
    saved_timetable_id = Column(Integer, ForeignKey("saved_timetables.id", ondelete="CASCADE"), nullable=False)
    day = Column(Integer, nullable=False)
    hour = Column(Integer, nullable=False)
    class_id = Column(Integer, ForeignKey("school_classes.id", ondelete="CASCADE"), nullable=False)
    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False)

    saved_timetable = relationship("SavedTimetable", back_populates="slots")
    school_class = relationship("SchoolClass")
    teacher = relationship("Teacher")
    subject = relationship("Subject")
