from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.core.database import Base

class SavedTimetable(Base):
    __tablename__ = "saved_timetables"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    created_at = Column(DateTime, default=datetime.now, nullable=False)
    description = Column(String(500), nullable=True)
    days_per_week = Column(Integer, nullable=False)
    hours_per_day = Column(Integer, nullable=False)

    slots = relationship("SavedTimetableSlot", back_populates="saved_timetable", cascade="all, delete-orphan")
