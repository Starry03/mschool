from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.deps import get_db
from app import crud

from app.api import deps
from app.models.user import User

from app.core.version import __version__, __app_name__, __api_version__
from app.schemas.system import SystemVersionResponse, SystemHealthResponse

router = APIRouter()

@router.get("/version", response_model=SystemVersionResponse)
def get_version():
    """
    Returns application and backend version metadata.
    """
    return SystemVersionResponse(
        app_name=__app_name__,
        version=__version__,
        api_version=__api_version__,
        environment="production",
        status="healthy"
    )

@router.get("/health", response_model=SystemHealthResponse)
def health_check(db: Session = Depends(get_db)):
    """
    Checks backend health, database connectivity, and returns active version.
    """
    is_healthy = crud.crud_system.check_db_health(db)
    if is_healthy:
        return SystemHealthResponse(
            status="ok",
            version=__version__,
            database="connected"
        )
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection failed"
        )

@router.delete("/clear-db", status_code=status.HTTP_204_NO_CONTENT)
def clear_db(
    db: Session = Depends(get_db),
    current_admin: User = Depends(deps.get_current_admin)
):
    try:
        crud.crud_system.clear_entire_database(db)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error clearing database: {e}"
        )

@router.delete("/clear-table/{table_name}", status_code=status.HTTP_204_NO_CONTENT)
def clear_table(
    table_name: str,
    db: Session = Depends(get_db),
    current_admin: User = Depends(deps.get_current_admin)
):
    success = crud.crud_system.clear_specific_table(db, table_name)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid table '{table_name}'. Use: teachers, classes, subjects, assignments, timetable"
        )

