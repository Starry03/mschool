from sqlalchemy import Column, Integer, String
from app.core.database import Base

class SchoolSettings(Base):
    """
    Represents the school settings (e.g., days per week, hours per day).
    This table will contain only one row.
    """
    __tablename__ = "school_settings"

    id = Column(Integer, primary_key=True, default=1)
    days_per_week = Column(Integer, nullable=False, default=5) # Max 6
    hours_per_day = Column(Integer, nullable=False, default=6) # Max 8
    allowed_domain = Column(String(255), nullable=True, default="school.it")

