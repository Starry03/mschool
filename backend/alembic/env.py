import os
import sys
from logging.config import fileConfig

# Add project root to sys.path so 'app' can be imported
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Monkeypatch Pydantic v1 for Python 3.14 compatibility before other imports
import app.patch_pydantic

from sqlalchemy import engine_from_config, pool
from alembic import context

from app.core.config import settings
from app.core.database import Base

# Import all models so that Base.metadata contains all model definitions
from app.models.teacher import Teacher
from app.models.teacher_settings import TeacherSettings
from app.models.teacher_constraint import TeacherConstraint
from app.models.school_class import SchoolClass
from app.models.subject import Subject
from app.models.assignment import Assignment
from app.models.class_subject_constraint import ClassSubjectConstraint
from app.models.timetable_slot import TimetableSlot
from app.models.saved_timetable import SavedTimetable
from app.models.saved_timetable_slot import SavedTimetableSlot
from app.models.school_settings import SchoolSettings
from app.models.user import User

# this is the Alembic Config object, which provides
# access to the values within the .ini file in use.
config = context.config

# Interpret the config file for Python logging.
# This line sets up loggers basically.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# target metadata for 'autogenerate' support
target_metadata = Base.metadata

def get_database_url() -> str:
    # Use the dynamic DATABASE_URL from settings (.env or environment variables)
    return settings.DATABASE_URL

def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode.

    This configures the context with just a URL
    and not an Engine, though an Engine is acceptable
    here as well.  By skipping the Engine creation
    we don't even need a DBAPI to be available.

    Calls to context.execute() here emit the given string to the
    script output.

    """
    url = get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode.

    In this scenario we need to create an Engine
    and associate a connection with the context.

    """
    configuration = config.get_section(config.config_ini_section) or {}
    configuration["sqlalchemy.url"] = get_database_url()

    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()

