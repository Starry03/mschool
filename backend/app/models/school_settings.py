from sqlalchemy import Column, Integer
from app.core.database import Base

class SchoolSettings(Base):
    """
    Rappresenta le impostazioni della scuola (es. giorni settimanali, ore al giorno).
    Questa tabella conterrà solo una riga.
    """
    __tablename__ = "school_settings"

    id = Column(Integer, primary_key=True, default=1)
    days_per_week = Column(Integer, nullable=False, default=5) # Max 6
    hours_per_day = Column(Integer, nullable=False, default=6) # Max 8
