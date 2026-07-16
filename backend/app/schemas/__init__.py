from app.schemas.teacher import TeacherBase, TeacherCreate, TeacherUpdate, Teacher
from app.schemas.teacher_settings import TeacherSettingsBase, TeacherSettingsCreate, TeacherSettingsUpdate, TeacherSettings
from app.schemas.teacher_constraint import TeacherConstraintBase, TeacherConstraintCreate, TeacherConstraint
from app.schemas.school_class import SchoolClassBase, SchoolClassCreate, SchoolClassUpdate, SchoolClass
from app.schemas.subject import SubjectBase, SubjectCreate, SubjectUpdate, Subject
from app.schemas.assignment import AssignmentBase, AssignmentCreate, AssignmentUpdate, Assignment, AssignmentDetail
from app.schemas.school_settings import SchoolSettingsBase, SchoolSettingsCreate, SchoolSettingsUpdate, SchoolSettings
from app.schemas.timetable_slot import TimetableSlotBase, TimetableSlotCreate, TimetableSlot, TimetableSlotDetail, TimetableGenerateResponse
from app.schemas.class_subject_constraint import ClassSubjectConstraintBase, ClassSubjectConstraintCreate, ClassSubjectConstraint, ClassSubjectConstraintDetail
from app.schemas.saved_timetable import SavedTimetableBase, SavedTimetableCreate, SavedTimetable, SavedTimetableDetail, SavedTimetableSlot, SavedTimetableSlotDetail
from app.schemas.user import UserBase, UserCreate, UserUpdate, UserResponse, GoogleLoginRequest, UserSession, AuthConfigResponse

__all__ = [
    "TeacherBase",
    "TeacherCreate",
    "TeacherUpdate",
    "Teacher",
    "TeacherSettingsBase",
    "TeacherSettingsCreate",
    "TeacherSettingsUpdate",
    "TeacherSettings",
    "TeacherConstraintBase",
    "TeacherConstraintCreate",
    "TeacherConstraint",
    "SchoolClassBase",
    "SchoolClassCreate",
    "SchoolClassUpdate",
    "SchoolClass",
    "SubjectBase",
    "SubjectCreate",
    "SubjectUpdate",
    "Subject",
    "AssignmentBase",
    "AssignmentCreate",
    "AssignmentUpdate",
    "Assignment",
    "AssignmentDetail",
    "SchoolSettingsBase",
    "SchoolSettingsCreate",
    "SchoolSettingsUpdate",
    "SchoolSettings",
    "TimetableSlotBase",
    "TimetableSlotCreate",
    "TimetableSlot",
    "TimetableSlotDetail",
    "TimetableGenerateResponse",
    "ClassSubjectConstraintBase",
    "ClassSubjectConstraintCreate",
    "ClassSubjectConstraint",
    "ClassSubjectConstraintDetail",
    "SavedTimetableBase",
    "SavedTimetableCreate",
    "SavedTimetable",
    "SavedTimetableDetail",
    "SavedTimetableSlot",
    "SavedTimetableSlotDetail",
    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserResponse",
    "GoogleLoginRequest",
    "UserSession",
    "AuthConfigResponse",
]

