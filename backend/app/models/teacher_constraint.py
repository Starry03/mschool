from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base

class TeacherConstraint(Base):
    """
    Rappresenta le fasce orarie in cui il docente NON può insegnare.
    Day: 0 = lunedì, 1 = martedì, ecc.
    Hour: 0 = prima ora, 1 = seconda ora, ecc.
    """
    __tablename__ = "teacher_constraints"

    id = Column(Integer, primary_key=True, index=True)
    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False)
    day = Column(Integer, nullable=False)
    hour = Column(Integer, nullable=False)

    # Relationships
    teacher = relationship("Teacher", back_populates="constraints")

    __table_args__ = (
        UniqueConstraint('teacher_id', 'day', 'hour', name='_teacher_day_hour_uc'),
    )
