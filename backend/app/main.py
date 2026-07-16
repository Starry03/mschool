import app.patch_pydantic
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1.api import api_router

# Initialize Database tables on startup
# This creates all tables in MySQL if they do not exist
from sqlalchemy import text, inspect
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.user import User

def run_startup_migrations():
    try:
        # Create all tables first
        Base.metadata.create_all(bind=engine)
        print("Database tables initialized successfully.")

        # Check and migrate column 'allowed_domain' in 'school_settings' if not present
        try:
            inspector = inspect(engine)
            # Check if the table exists first to avoid error
            if 'school_settings' in inspector.get_table_names():
                columns = [col['name'] for col in inspector.get_columns('school_settings')]
                if 'allowed_domain' not in columns:
                    print("Migrating school_settings table: adding allowed_domain column...")
                    with engine.begin() as conn:
                        conn.execute(text("ALTER TABLE school_settings ADD COLUMN allowed_domain VARCHAR(255) DEFAULT 'school.it'"))
                    print("school_settings table migrated successfully.")
        except Exception as ex:
            print(f"Warning during column migration: {ex}")

        # Seed default admin if users table is empty
        try:
            db = SessionLocal()
            try:
                if db.query(User).count() == 0:
                    admin_email = settings.DEFAULT_ADMIN_EMAIL
                    default_admin = User(
                        email=admin_email,
                        first_name="Admin",
                        last_name="System",
                        role="admin"
                    )
                    db.add(default_admin)
                    db.commit()
                    print(f"Seeded default admin user: {admin_email}")
            finally:
                db.close()
        except Exception as ex:
            print(f"Warning during admin seeding: {ex}")

    except Exception as e:
        print(f"Error initializing database: {e}")
        print("Note: If the database is not running yet, it will be initialized when available.")

run_startup_migrations()


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# CORS Middleware (indispensable for Flutter frontend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins in development
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Include API Router
app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "message": "Welcome to the School Timetable Generator API!",
        "documentation": "/docs"
    }
