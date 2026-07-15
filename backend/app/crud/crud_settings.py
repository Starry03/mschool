from sqlalchemy.orm import Session
from app.models.school_settings import SchoolSettings
from app.schemas.school_settings import SchoolSettingsUpdate

def get_school_settings(db: Session) -> SchoolSettings:
    settings = db.query(SchoolSettings).filter(SchoolSettings.id == 1).first()
    if not settings:
        # Create default settings
        settings = SchoolSettings(id=1, days_per_week=5, hours_per_day=6)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings

def update_school_settings(db: Session, settings_in: SchoolSettingsUpdate) -> SchoolSettings:
    settings = get_school_settings(db)
    
    update_data = settings_in.dict(exclude_unset=True)
    # Validation constraints
    if "days_per_week" in update_data:
        days = update_data["days_per_week"]
        if days < 1 or days > 6:
            raise ValueError("Days per week must be between 1 and 6")
            
    if "hours_per_day" in update_data:
        hours = update_data["hours_per_day"]
        if hours < 1 or hours > 8:
            raise ValueError("Hours per day must be between 1 and 8")
            
    for key, value in update_data.items():
        setattr(settings, key, value)
        
    db.commit()
    db.refresh(settings)
    return settings
