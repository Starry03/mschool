#!/bin/sh
set -e

echo "=== MSchool Backend Starting ==="

# Run Alembic migrations to bring the database schema up to date
echo "Applying database migrations (Alembic)..."
alembic upgrade head || {
    echo "Warning: Alembic migration failed or database is not reachable yet."
    echo "The application will continue and retry applying migrations on startup."
}

echo "Starting server process..."
exec "$@"

