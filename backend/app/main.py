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
from app.core.version import __version__

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

    except Exception as e:
        print(f"Error initializing database / running migrations: {e}")
        print("Note: If the database is not running yet, it will be initialized when available.")

run_startup_migrations()


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=__version__,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    dependencies=[Depends(global_rate_limiter)]
)

# CORS Middleware (indispensable for Flutter frontend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_origin_regex=r"^https?://.*$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
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
            "message": "Welcome to the mschool API!",
            "documentation": "/docs"
        }
