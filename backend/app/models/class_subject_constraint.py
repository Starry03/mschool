from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from app.core.database import Base

class ClassSubjectConstraint(Base):
    """
    Rappresenta il vincolo sul numero di ore settimanali che una determinata classe
    deve fare per una determinata materia.
    """
    __tablename__ = "class_subject_constraints"

    id = Column(Integer, primary_key=True, index=True)
    class_id = Column(Integer, ForeignKey("school_classes.id", ondelete="CASCADE"), nullable=False)
    subject_id = Column(Integer, ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False)
    weekly_hours = Column(Integer, nullable=False, default=1)

    # Relationships
    school_class = relationship("SchoolClass", back_populates="subject_constraints")
    subject = relationship("Subject", back_populates="class_constraints")

    __table_args__ = (
        UniqueConstraint('class_id', 'subject_id', name='_class_subject_uc'),
    )
