from sqlalchemy import Column, Integer, String, DateTime, func
from app.core.database import Base

class User(Base):
    """
    Represents a user authorized to access the system.
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    first_name = Column(String(255), nullable=False)
    last_name = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False, default="user")  # "admin" or "user"
    created_at = Column(DateTime, server_default=func.now(), nullable=False)
