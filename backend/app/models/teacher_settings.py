from sqlalchemy import Column, Integer, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from app.core.database import Base

class TeacherSettings(Base):
    """
    Rappresenta le impostazioni personali del docente (es. limite ore consecutive, limite ore giornaliere).
    """
    __tablename__ = "teacher_settings"

    teacher_id = Column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), primary_key=True)
    max_consecutive_hours = Column(Integer, nullable=False, default=3)
    max_hours_per_day = Column(Integer, nullable=False, default=5)
    prefer_consecutive = Column(Boolean, nullable=False, default=False)

    # Relationships
    teacher = relationship("Teacher", back_populates="settings")
