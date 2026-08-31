"""Initial schema with all tables and columns

Revision ID: 0001_initial_schema
Revises: 
Create Date: 2026-08-31 20:25:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector


# revision identifiers, used by Alembic.
revision: str = '0001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = Inspector.from_engine(bind)
    existing_tables = inspector.get_table_names()

    # 1. school_settings
    if "school_settings" not in existing_tables:
        op.create_table(
            "school_settings",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("days_per_week", sa.Integer(), nullable=False, server_default="5"),
            sa.Column("hours_per_day", sa.Integer(), nullable=False, server_default="6"),
            sa.Column("allowed_domain", sa.String(length=255), nullable=True, server_default="school.it"),
            sa.PrimaryKeyConstraint("id"),
        )
    else:
        cols = [c["name"] for c in inspector.get_columns("school_settings")]
        if "allowed_domain" not in cols:
            op.add_column("school_settings", sa.Column("allowed_domain", sa.String(length=255), nullable=True, server_default="school.it"))

    # 2. teachers
    if "teachers" not in existing_tables:
        op.create_table(
            "teachers",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("first_name", sa.String(length=100), nullable=False),
            sa.Column("last_name", sa.String(length=100), nullable=True),
            sa.Column("email", sa.String(length=255), nullable=True),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_teachers_id"), "teachers", ["id"], unique=False)
        op.create_index(op.f("ix_teachers_email"), "teachers", ["email"], unique=True)

    # 3. teacher_settings
    if "teacher_settings" not in existing_tables:
        op.create_table(
            "teacher_settings",
            sa.Column("teacher_id", sa.Integer(), nullable=False),
            sa.Column("max_consecutive_hours", sa.Integer(), nullable=False, server_default="3"),
            sa.Column("max_hours_per_day", sa.Integer(), nullable=False, server_default="5"),
            sa.Column("prefer_consecutive", sa.Boolean(), nullable=False, server_default="0"),
            sa.ForeignKeyConstraint(["teacher_id"], ["teachers.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("teacher_id"),
        )
    else:
        cols = [c["name"] for c in inspector.get_columns("teacher_settings")]
        if "prefer_consecutive" not in cols:
            op.add_column("teacher_settings", sa.Column("prefer_consecutive", sa.Boolean(), nullable=False, server_default="0"))

    # 4. teacher_constraints
    if "teacher_constraints" not in existing_tables:
        op.create_table(
            "teacher_constraints",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("teacher_id", sa.Integer(), nullable=False),
            sa.Column("day", sa.Integer(), nullable=False),
            sa.Column("hour", sa.Integer(), nullable=False),
            sa.ForeignKeyConstraint(["teacher_id"], ["teachers.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_teacher_constraints_id"), "teacher_constraints", ["id"], unique=False)

    # 5. school_classes
    if "school_classes" not in existing_tables:
        op.create_table(
            "school_classes",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("name", sa.String(length=50), nullable=False),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_school_classes_id"), "school_classes", ["id"], unique=False)
        op.create_index(op.f("ix_school_classes_name"), "school_classes", ["name"], unique=True)

    # 6. subjects
    if "subjects" not in existing_tables:
        op.create_table(
            "subjects",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("name", sa.String(length=100), nullable=False),
            sa.Column("max_consecutive_hours", sa.Integer(), nullable=True),
            sa.Column("max_hours_per_day", sa.Integer(), nullable=True),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_subjects_id"), "subjects", ["id"], unique=False)
        op.create_index(op.f("ix_subjects_name"), "subjects", ["name"], unique=True)
    else:
        cols = [c["name"] for c in inspector.get_columns("subjects")]
        if "max_consecutive_hours" not in cols:
            op.add_column("subjects", sa.Column("max_consecutive_hours", sa.Integer(), nullable=True))
        if "max_hours_per_day" not in cols:
            op.add_column("subjects", sa.Column("max_hours_per_day", sa.Integer(), nullable=True))

    # 7. assignments
    if "assignments" not in existing_tables:
        op.create_table(
            "assignments",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("teacher_id", sa.Integer(), nullable=False),
            sa.Column("class_id", sa.Integer(), nullable=False),
            sa.Column("subject_id", sa.Integer(), nullable=False),
            sa.Column("weekly_hours", sa.Integer(), nullable=False),
            sa.ForeignKeyConstraint(["class_id"], ["school_classes.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["subject_id"], ["subjects.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["teacher_id"], ["teachers.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_assignments_id"), "assignments", ["id"], unique=False)

    # 8. class_subject_constraints
    if "class_subject_constraints" not in existing_tables:
        op.create_table(
            "class_subject_constraints",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("class_id", sa.Integer(), nullable=False),
            sa.Column("subject_id", sa.Integer(), nullable=False),
            sa.Column("weekly_hours", sa.Integer(), nullable=False),
            sa.ForeignKeyConstraint(["class_id"], ["school_classes.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["subject_id"], ["subjects.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_class_subject_constraints_id"), "class_subject_constraints", ["id"], unique=False)

    # 9. timetable_slots
    if "timetable_slots" not in existing_tables:
        op.create_table(
            "timetable_slots",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("day", sa.Integer(), nullable=False),
            sa.Column("hour", sa.Integer(), nullable=False),
            sa.Column("teacher_id", sa.Integer(), nullable=False),
            sa.Column("class_id", sa.Integer(), nullable=False),
            sa.Column("subject_id", sa.Integer(), nullable=False),
            sa.ForeignKeyConstraint(["class_id"], ["school_classes.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["subject_id"], ["subjects.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["teacher_id"], ["teachers.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_timetable_slots_id"), "timetable_slots", ["id"], unique=False)

    # 10. saved_timetables
    if "saved_timetables" not in existing_tables:
        op.create_table(
            "saved_timetables",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("name", sa.String(length=100), nullable=False),
            sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
            sa.Column("description", sa.String(length=500), nullable=True),
            sa.Column("days_per_week", sa.Integer(), nullable=False),
            sa.Column("hours_per_day", sa.Integer(), nullable=False),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_saved_timetables_id"), "saved_timetables", ["id"], unique=False)

    # 11. saved_timetable_slots
    if "saved_timetable_slots" not in existing_tables:
        op.create_table(
            "saved_timetable_slots",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("saved_timetable_id", sa.Integer(), nullable=False),
            sa.Column("day", sa.Integer(), nullable=False),
            sa.Column("hour", sa.Integer(), nullable=False),
            sa.Column("class_id", sa.Integer(), nullable=False),
            sa.Column("teacher_id", sa.Integer(), nullable=False),
            sa.Column("subject_id", sa.Integer(), nullable=False),
            sa.ForeignKeyConstraint(["class_id"], ["school_classes.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["saved_timetable_id"], ["saved_timetables.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["subject_id"], ["subjects.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["teacher_id"], ["teachers.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_saved_timetable_slots_id"), "saved_timetable_slots", ["id"], unique=False)

    # 12. users
    if "users" not in existing_tables:
        op.create_table(
            "users",
            sa.Column("id", sa.Integer(), nullable=False),
            sa.Column("email", sa.String(length=255), nullable=False),
            sa.Column("first_name", sa.String(length=255), nullable=False),
            sa.Column("last_name", sa.String(length=255), nullable=False),
            sa.Column("role", sa.String(length=50), nullable=False, server_default="user"),
            sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.func.now()),
            sa.PrimaryKeyConstraint("id"),
        )
        op.create_index(op.f("ix_users_id"), "users", ["id"], unique=False)
        op.create_index(op.f("ix_users_email"), "users", ["email"], unique=True)


def downgrade() -> None:
    op.drop_table("users")
    op.drop_table("saved_timetable_slots")
    op.drop_table("saved_timetables")
    op.drop_table("timetable_slots")
    op.drop_table("class_subject_constraints")
    op.drop_table("assignments")
    op.drop_table("subjects")
    op.drop_table("school_classes")
    op.drop_table("teacher_constraints")
    op.drop_table("teacher_settings")
    op.drop_table("teachers")
    op.drop_table("school_settings")

