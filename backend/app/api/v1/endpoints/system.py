from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.api.deps import get_db
from app import crud

router = APIRouter()

@router.get("/health")
def health_check(db: Session = Depends(get_db)):
    is_healthy = crud.crud_system.check_db_health(db)
    if is_healthy:
        return {"status": "ok", "database": "connected"}
    else:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Database connection failed"
        )

@router.delete("/clear-db", status_code=status.HTTP_204_NO_CONTENT)
def clear_db(db: Session = Depends(get_db)):
    try:
        crud.crud_system.clear_entire_database(db)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Errore durante la pulizia del database: {e}"
        )

@router.delete("/clear-table/{table_name}", status_code=status.HTTP_204_NO_CONTENT)
def clear_table(table_name: str, db: Session = Depends(get_db)):
    success = crud.crud_system.clear_specific_table(db, table_name)
    if not success:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tabella '{table_name}' non valida. Usa: teachers, classes, subjects, assignments, timetable"
        )
