from sqlalchemy import Column, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class Assignment(Base):
    __tablename__ = "assignments"

    id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    class_id = Column(Integer, ForeignKey("school_classes.id", ondelete="CASCADE"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False)
    weekly_hours = Column(Integer, nullable=False, default=1)

    # Relationships
    teacher = relationship("Teacher", back_populates="assignments")
    school_class = relationship("SchoolClass", back_populates="assignments")
    subject = relationship("Subject", back_populates="assignments")
