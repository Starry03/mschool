from fastapi import APIRouter, Depends
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
    auth,
    users,
)
from app.api import deps

api_router = APIRouter()

# Public routes or routes with internal permissions for authentication
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])

# Routes reserved for administrators
api_router.include_router(users.router, prefix="/users", tags=["users"], dependencies=[Depends(deps.get_current_admin)])

# General settings (public GET, internally restricted PUT to admin)
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])

# System maintenance (mixed public/private routes)
api_router.include_router(system.router, prefix="/system", tags=["system"])

# Protected routes for planning (require general authentication)
api_router.include_router(teachers.router, prefix="/teachers", tags=["teachers"], dependencies=[Depends(deps.get_current_user)])
api_router.include_router(classes.router, prefix="/classes", tags=["classes"], dependencies=[Depends(deps.get_current_user)])
api_router.include_router(subjects.router, prefix="/subjects", tags=["subjects"], dependencies=[Depends(deps.get_current_user)])
api_router.include_router(assignments.router, prefix="/assignments", tags=["assignments"], dependencies=[Depends(deps.get_current_user)])
api_router.include_router(timetable.router, prefix="/timetable", tags=["timetable"], dependencies=[Depends(deps.get_current_user)])
api_router.include_router(class_subject_constraints.router, prefix="/class-subject-constraints", tags=["class-subject-constraints"], dependencies=[Depends(deps.get_current_user)])
api_router.include_router(saved_timetables.router, prefix="/saved-timetables", tags=["saved-timetables"], dependencies=[Depends(deps.get_current_user)])

