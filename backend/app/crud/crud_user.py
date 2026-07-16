from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
from app.crud import crud_settings

def get_user(db: Session, user_id: int) -> User:
    return db.query(User).filter(User.id == user_id).first()

def get_user_by_email(db: Session, email: str) -> User:
    return db.query(User).filter(User.email == email).first()

def get_users(db: Session, skip: int = 0, limit: int = 100) -> list[User]:
    return db.query(User).offset(skip).limit(limit).all()

def validate_user_email(db: Session, email: str, role: str):
    """
    Valida l'indirizzo email dell'utente in base al dominio configurato.
    Gli amministratori possono avere qualsiasi dominio email.
    """
    if role == "admin":
        return
    
    settings = crud_settings.get_school_settings(db)
    if settings.allowed_domain:
        domain = settings.allowed_domain.strip().lower()
        if domain:
            email_lower = email.strip().lower()
            if not email_lower.endswith(f"@{domain}"):
                raise ValueError(f"L'indirizzo email deve appartenere al dominio configurato: {domain}")

def create_user(db: Session, user_in: UserCreate) -> User:
    email = user_in.email.strip().lower()
    
    # Valida dominio email
    validate_user_email(db, email, user_in.role)
    
    db_user = User(
        email=email,
        first_name=user_in.first_name,
        last_name=user_in.last_name,
        role=user_in.role
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def delete_user(db: Session, user_id: int) -> User | None:
    db_user = get_user(db, user_id)
    if db_user:
        db.delete(db_user)
        db.commit()
    return db_user
