import os
import app.patch_pydantic
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.core.rate_limiter import global_rate_limiter
from app.core.database import engine, Base
from app.api.v1.api import api_router

from alembic.config import Config
from alembic import command
from app.core.database import SessionLocal
from app.models.user import User

def run_startup_migrations():
    try:
        # Run Alembic migrations programmatically to bring schema to 'head'
        backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        alembic_ini_path = os.path.join(backend_dir, "alembic.ini")

        if os.path.exists(alembic_ini_path):
            alembic_cfg = Config(alembic_ini_path)
            # Ensure the script location is an absolute path
            alembic_cfg.set_main_option("script_location", os.path.join(backend_dir, "alembic"))
            alembic_cfg.set_main_option("sqlalchemy.url", settings.DATABASE_URL)
            command.upgrade(alembic_cfg, "head")
            print("Alembic database migrations applied successfully.")
        else:
            # Fallback to create_all if alembic.ini is absent
            Base.metadata.create_all(bind=engine)
            print("Database tables initialized via create_all fallback.")

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
        print(f"Error initializing database / running migrations: {e}")
        print("Note: If the database is not running yet, it will be initialized when available.")

run_startup_migrations()


app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    dependencies=[Depends(global_rate_limiter)]
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

# Mount static files for all-in-one deployment if the directory exists
static_dir = os.path.join(os.path.dirname(__file__), "static")
if os.path.exists(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")
else:
    @app.get("/")
    def root():
        return {
            "message": "Welcome to the School Timetable Generator API!",
            "documentation": "/docs"
        }
