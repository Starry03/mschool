from fastapi import APIRouter
from app.api.v1.endpoints import (
    teachers,
    classes,
    subjects,
    assignments,
    settings,
    timetable,
    system,
    class_subject_constraints,
    saved_timetables,
)

api_router = APIRouter()

api_router.include_router(teachers.router, prefix="/teachers", tags=["teachers"])
api_router.include_router(classes.router, prefix="/classes", tags=["classes"])
api_router.include_router(subjects.router, prefix="/subjects", tags=["subjects"])
api_router.include_router(assignments.router, prefix="/assignments", tags=["assignments"])
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
api_router.include_router(timetable.router, prefix="/timetable", tags=["timetable"])
api_router.include_router(system.router, prefix="/system", tags=["system"])
api_router.include_router(class_subject_constraints.router, prefix="/class-subject-constraints", tags=["class-subject-constraints"])
api_router.include_router(saved_timetables.router, prefix="/saved-timetables", tags=["saved-timetables"])
