from sqlalchemy.orm import Session
from ortools.sat.python import cp_model
from typing import List, Dict, Tuple, Optional
from app.models.teacher import Teacher
from app.models.school_class import SchoolClass
from app.models.subject import Subject
from app.models.assignment import Assignment
from app.models.teacher_constraint import TeacherConstraint
from app.models.teacher_settings import TeacherSettings
from app.models.school_settings import SchoolSettings
from app.models.timetable_slot import TimetableSlot
from app.models.class_subject_constraint import ClassSubjectConstraint
from app.schemas.timetable_slot import TimetableSlotCreate, TimetableSlotDetail

class SolverDiagnosticException(Exception):
    def __init__(self, message: str, details: Optional[str] = None):
        super().__init__(message)
        self.message = message
        self.details = details

def run_pre_checks(
    days: int,
    hours: int,
    classes: List[SchoolClass],
    teachers: List[Teacher],
    assignments: List[Assignment],
    constraints_map: Dict[int, List[Tuple[int, int]]],
) -> None:
    """
    Performs preventative arithmetic checks on data to detect obvious conflicts before starting the solver.
    Raises SolverDiagnosticException if an error is found.
    """
    total_slots = days * hours

    # 1. Check that the total hours assigned to each class do not exceed the school's capacity
    for c in classes:
        class_assignments = [a for a in assignments if a.class_id == c.id]
        class_hours = sum(a.weekly_hours for a in class_assignments)
        if class_hours > total_slots:
            raise SolverDiagnosticException(
                message=f"Class '{c.name}' has too many assigned hours.",
                details=(
                    f"Assigned hours: {class_hours}. "
                    f"Maximum weekly capacity of the school: {total_slots} hours "
                    f"({days} days x {hours} hours daily)."
                )
            )

    # 2. Check that the total hours assigned to each teacher do not exceed their net availability
    for t in teachers:
        teacher_assignments = [a for a in assignments if a.teacher_id == t.id]
        teacher_hours = sum(a.weekly_hours for a in teacher_assignments)
        
        # Subtract from the total hours the slots in which the teacher is unavailable
        t_constraints = constraints_map.get(t.id, [])
        unavailable_slots = len(t_constraints)
        available_slots = total_slots - unavailable_slots
        
        if teacher_hours > total_slots:
            raise SolverDiagnosticException(
                message=f"Teacher '{t.first_name} {t.last_name or ''}' has an excessive hour load.",
                details=(
                    f"The teacher has {teacher_hours} assigned hours, "
                    f"but the school week only has {total_slots} hours in total."
                )
            )
            
        if teacher_hours > available_slots:
            raise SolverDiagnosticException(
                message=f"Teacher '{t.first_name} {t.last_name or ''}' has too many assigned hours compared to their availability.",
                details=(
                    f"The teacher has {teacher_hours} assigned hours, "
                    f"but only has {available_slots} hours available due to {unavailable_slots} unavailability hours entered."
                )
            )

    # 3. Check constraints on the number of weekly mandatory hours per subject and class
    for sc in subject_constraints:
        class_sub_assigns = [a for a in assignments if a.class_id == sc.class_id and a.subject_id == sc.subject_id]
        assigned_hours = sum(a.weekly_hours for a in class_sub_assigns)
        if assigned_hours != sc.weekly_hours:
            class_name = sc.school_class.name if sc.school_class else f"ID {sc.class_id}"
            subject_name = sc.subject.name if sc.subject else f"ID {sc.subject_id}"
            raise SolverDiagnosticException(
                message=f"Detected inconsistency on the subject hour constraint for the class.",
                details=(
                    f"The constraint for class '{class_name}' and subject '{subject_name}' requires exactly {sc.weekly_hours} hours, "
                    f"but {assigned_hours} hours were assigned in the teaching chairs."
                )
            )

def build_and_solve_model(
    days: int,
    hours: int,
    classes: List[SchoolClass],
    teachers: List[Teacher],
    assignments: List[Assignment],
    constraints_map: Dict[int, List[Tuple[int, int]]],
    settings_map: Dict[int, TeacherSettings],
    subjects_map: Dict[int, Optional[int]] = None,
    ignore_constraints: bool = False,
    ignore_settings: bool = False,
    max_time_seconds: float = 5.0
) -> Tuple[str, List[Dict[str, int]]]:
    """
    Builds and solves the CP-SAT model. Allows selectively disabling constraints
    for diagnostic purposes.
    Returns a tuple (status_name, list_of_generated_slots).
    """
    if subjects_map is None:
        subjects_map = {}
    model = cp_model.CpModel()

    
    # Set of days and hours
    giorni_range = range(days)
    ore_range = range(hours)
    
    # 1. Decision variables
    # x[a_id, g, h] = 1 if assignment 'a' is scheduled on day 'g' at hour 'h', 0 otherwise
    x = {}
    for a in assignments:
        for g in giorni_range:
            for h in ore_range:
                x[a.id, g, h] = model.NewBoolVar(f"x_a{a.id}_g{g}_h{h}")
                
    # Presence variables for teacher t on day g at hour h
    # y[t_id, g, h] = 1 if teacher t teaches on day g at hour h
    y = {}
    for t in teachers:
        for g in giorni_range:
            for h in ore_range:
                # Find all assignments associated with this teacher
                teacher_assigns = [a for a in assignments if a.teacher_id == t.id]
                y[t.id, g, h] = model.NewBoolVar(f"y_t{t.id}_g{g}_h{h}")
                
                # y[t,g,h] is the sum of x of their assignments for that hour
                model.Add(y[t.id, g, h] == sum(x[a.id, g, h] for a in teacher_assigns))

    # -------------------------------------------------------------------------
    # HARD CONSTRAINTS
    # -------------------------------------------------------------------------

    # A. Meet the weekly hours for each assignment
    for a in assignments:
        model.Add(sum(x[a.id, g, h] for g in giorni_range for h in ore_range) == a.weekly_hours)

    # B. Teacher Co-occurrence: A teacher teaches at most 1 lesson per hour (already guaranteed by y[t,g,h] <= 1)
    for t in teachers:
        for g in giorni_range:
            for h in ore_range:
                model.Add(y[t.id, g, h] <= 1)

    # C. Class Co-occurrence: A class has at most 1 lesson per hour
    for c in classes:
        class_assigns = [a for a in assignments if a.class_id == c.id]
        for g in giorni_range:
            for h in ore_range:
                model.Add(sum(x[a.id, g, h] for a in class_assigns) <= 1)

    # D. Teacher Unavailability Slots (teacher_constraints)
    if not ignore_constraints:
        for t in teachers:
            t_constraints = constraints_map.get(t.id, [])
            for (g_ind, h_ind) in t_constraints:
                # Check that unavailability falls within the current grid
                if g_ind < days and h_ind < hours:
                    model.Add(y[t.id, g_ind, h_ind] == 0)

    # E. Teacher Hour Limits (teacher_settings)
    if not ignore_settings:
        for t in teachers:
            t_settings = settings_map.get(t.id)
            if not t_settings:
                continue
                
            # Consecutive hours limit
            max_consec = t_settings.max_consecutive_hours
            if max_consec < hours:
                # Moving window of size max_consec + 1
                for g in giorni_range:
                    for h in range(hours - max_consec):
                        model.Add(
                            sum(y[t.id, g, h + offset] for offset in range(max_consec + 1)) <= max_consec
                        )
                        
            # Daily hours limit
            max_day = t_settings.max_hours_per_day
            if max_day < hours:
                for g in giorni_range:
                    model.Add(sum(y[t.id, g, h] for h in ore_range) <= max_day)

    # F. Subject Limits (subject.max_consecutive_hours and subject.max_hours_per_day)
    if not ignore_subject_limits:
        for c in classes:
            class_assigns = [a for a in assignments if a.class_id == c.id]
            subj_assigns_map: Dict[int, list] = {}
            for a in class_assigns:
                subj_assigns_map.setdefault(a.subject_id, []).append(a)

            for subj_id, subj_assign_list in subj_assigns_map.items():
                # 1. Consecutive hours limit
                max_consec_subj = subjects_map.get(subj_id) if subjects_map else None
                if max_consec_subj is not None and max_consec_subj < hours:
                    for g in giorni_range:
                        for h in range(hours - max_consec_subj):
                            model.Add(
                                sum(
                                    x[a.id, g, h + offset]
                                    for a in subj_assign_list
                                    for offset in range(max_consec_subj + 1)
                                ) <= max_consec_subj
                            )

                # 2. Daily hours limit
                max_daily_subj = subjects_daily_map.get(subj_id) if subjects_daily_map else None
                if max_daily_subj is not None and max_daily_subj < hours:
                    for g in giorni_range:
                        model.Add(
                        )

    # -------------------------------------------------------------------------
    # SOFT CONSTRAINTS (Optimization: Minimizing Gaps)
    # -------------------------------------------------------------------------
    gap_vars = []
    
    # We minimize gaps only if we are not running a super-relaxed diagnostic solve
    for t in teachers:
        for g in giorni_range:
            # has_taught_before[h] = 1 if the teacher taught in an hour < h on the same day
            has_taught_before = {}
            # has_taught_after[h] = 1 if the teacher teaches in an hour > h on the same day
            has_taught_after = {}
            
            # A gap can only happen in the middle hours (from 1 to hours-2)
            for h in range(1, hours - 1):
                has_taught_before[h] = model.NewBoolVar(f"before_t{t.id}_g{g}_h{h}")
                has_taught_after[h] = model.NewBoolVar(f"after_t{t.id}_g{g}_h{h}")
                
                # has_taught_before[h] is 1 if sum(y[t, g, k] for k < h) >= 1
                # We model this linearly:
                # 1. has_taught_before[h] >= y[t, g, k] for each k < h
                for k in range(h):
                    model.Add(has_taught_before[h] >= y[t.id, g, k])
                # 2. has_taught_before[h] <= sum(y[t, g, k] for k < h)
                model.Add(has_taught_before[h] <= sum(y[t.id, g, k] for k in range(h)))
                
                # has_taught_after[h] is 1 if sum(y[t, g, k] for k > h) >= 1
                # 1. has_taught_after[h] >= y[t, g, k] for each k > h
                for k in range(h + 1, hours):
                    model.Add(has_taught_after[h] >= y[t.id, g, k])
                # 2. has_taught_after[h] <= sum(y[t, g, k] for k > h)
                model.Add(has_taught_after[h] <= sum(y[t.id, g, k] for k in range(h + 1, hours)))
                
                # gap[t, g, h] is 1 if has_taught_before[h] == 1 AND has_taught_after[h] == 1 AND y[t, g, h] == 0
                gap = model.NewBoolVar(f"gap_t{t.id}_g{g}_h{h}")
                # Linear model for logical AND with negated y:
                # gap >= before + after - y - 1
                model.Add(gap >= has_taught_before[h] + has_taught_after[h] - y[t.id, g, h] - 1)
                
                gap_vars.append(gap)

    # -------------------------------------------------------------------------
    # SOFT CONSTRAINT: Consecutive hours of the same subject for a class on the same day
    # (Soft: hours are rewarded in the objective function if consecutive)
    # -------------------------------------------------------------------------
    CONSECUTIVITY_WEIGHT = 20  # Premium weight for each pair of consecutive hours of the same subject
    consec_vars = []
    
    for c in classes:
        class_assigns = [a for a in assignments if a.class_id == c.id]
        # Group assignments by subject_id
        subj_assigns: dict = {}
        for a in class_assigns:
            subj_assigns.setdefault(a.subject_id, []).append(a)
        
        for subject_id, subj_assign_list in subj_assigns.items():
            for g in giorni_range:
                for h in range(hours - 1):
                    # z[c, s, g, h] = 1 if subject s is taught to class c on day g at hour h
                    z_h = sum(x[a.id, g, h] for a in subj_assign_list)
                    z_h1 = sum(x[a.id, g, h + 1] for a in subj_assign_list)
                    
                    # consec = 1 if z_h == 1 AND z_h1 == 1
                    consec = model.NewBoolVar(f"consec_c{c.id}_s{subject_id}_g{g}_h{h}")
                    # Model consec <= z_h and consec <= z_h1 and consec >= z_h + z_h1 - 1
                    model.Add(consec <= z_h)
                    model.Add(consec <= z_h1)
                    model.Add(consec >= z_h + z_h1 - 1)
                    consec_vars.append(consec)

    # -------------------------------------------------------------------------
    # SOFT CONSTRAINT: Consecutive hours of the teacher on the same day (prefer_consecutive)
    # If the teacher has prefer_consecutive=True, they are rewarded for each pair of
    # consecutive hours taught on the same day (regardless of class/subject).
    # -------------------------------------------------------------------------
    TEACHER_CONSEC_WEIGHT = 15  # Slightly lower weight than the subject constraint
    teacher_consec_vars = []

    for t in teachers:
        t_settings = settings_map.get(t.id)
        if not t_settings or not t_settings.prefer_consecutive:
            continue
        for g in giorni_range:
            for h in range(hours - 1):
                # tc = 1 if the teacher teaches both at hour h and h+1 on the same day
                tc = model.NewBoolVar(f"tcons_t{t.id}_g{g}_h{h}")
                model.Add(tc <= y[t.id, g, h])
                model.Add(tc <= y[t.id, g, h + 1])
                model.Add(tc >= y[t.id, g, h] + y[t.id, g, h + 1] - 1)
                teacher_consec_vars.append(tc)

    # Minimize gaps and maximize subject and teacher consecutivity
    if gap_vars or consec_vars or teacher_consec_vars:
        objective_terms = []
        if gap_vars:
            objective_terms.extend(gap_vars)
        if consec_vars:
            objective_terms.extend([-CONSECUTIVITY_WEIGHT * c for c in consec_vars])
        if teacher_consec_vars:
            objective_terms.extend([-TEACHER_CONSEC_WEIGHT * tc for tc in teacher_consec_vars])
        model.Minimize(sum(objective_terms))

    # 2. Solver Execution
    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = max_time_seconds
    status = solver.Solve(model)
    
    status_name = solver.StatusName(status)
    slots_output = []
    
    if status == cp_model.OPTIMAL or status == cp_model.FEASIBLE:
        for a in assignments:
            for g in giorni_range:
                for h in ore_range:
                    if solver.Value(x[a.id, g, h]) == 1:
                        slots_output.append({
                            "day": g,
                            "hour": h,
                            "class_id": a.class_id,
                            "teacher_id": a.teacher_id,
                            "subject_id": a.subject_id
                        })
                        
    return status_name, slots_output

def generate_timetable(db: Session, max_time_seconds: float = 10.0) -> Tuple[bool, str, List[Dict[str, int]], Optional[str]]:
    """
    Solves the school timetabling problem by extracting data from the database,
    running pre-checks, and starting the Google OR-Tools CP-SAT solver.
    
    In case of failure, performs an automatic diagnosis to explain the reason.
    
    Returns a tuple (success, message, slots_list, error_details).
    """
    # 1. Load global school settings
    school_settings = db.query(SchoolSettings).filter(SchoolSettings.id == 1).first()
    if not school_settings:
        # Default fallback
        days = 5
        hours = 6
    else:
        days = school_settings.days_per_week
        hours = school_settings.hours_per_day
        
    # 2. Load classes, teachers, and assignments
    classes = db.query(SchoolClass).all()
    teachers = db.query(Teacher).all()
    assignments = db.query(Assignment).all()
    subject_constraints = db.query(ClassSubjectConstraint).all()
    
    if not classes:
        return False, "No classes found in the database. Unable to generate timetable.", [], None
    if not teachers:
        return False, "No teachers found in the database. Unable to generate timetable.", [], None
    if not assignments:
        return False, "No class assignments found in the database. Unable to generate timetable.", [], None

    # Map unavailability per teacher
    constraints_map = {}
    for t in teachers:
        constraints_map[t.id] = [(c.day, c.hour) for c in t.constraints]
        
    # Map settings per teacher
    settings_map = {}
    for t in teachers:
        if t.settings:
            settings_map[t.id] = t.settings

    # Map the consecutive and daily hour limits per subject
    subjects = db.query(Subject).all()
    subjects_consec_map = {s.id: s.max_consecutive_hours for s in subjects}
    subjects_daily_map = {s.id: s.max_hours_per_day for s in subjects}

    # 3. Run preventative arithmetic checks
    try:
        run_pre_checks(days, hours, classes, teachers, assignments, constraints_map, subject_constraints, subjects)
    except SolverDiagnosticException as ex:
        return False, ex.message, [], ex.details

    # 4. Attempt to solve the complete model
    status_name, slots = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_consec_map, subjects_daily_map,
        max_time_seconds=max_time_seconds
    )
    
    if status_name in ("OPTIMAL", "FEASIBLE"):
        return True, "School timetable generated successfully!", slots, None
        
    # -------------------------------------------------------------------------
    # FAILURE DIAGNOSIS
    # If the solver fails, we disable constraints in blocks to understand the reason.
    # -------------------------------------------------------------------------
    
    # Diagnosis 1: Disable daily and consecutive hour limits for teachers (settings)
    status_no_settings, _ = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_consec_map, subjects_daily_map,
        ignore_constraints=False,
        ignore_settings=True,
        ignore_subject_limits=False,
        max_time_seconds=3.0
    )
    
    if status_no_settings in ("OPTIMAL", "FEASIBLE"):
        return (
            False,
            "Unable to generate the timetable with the consecutive or daily hour limits set for the teachers.",
            [],
            "The problem becomes solvable by disabling restrictions on consecutive hours and daily hour limits per teacher. "
            "Suggestion: increase the 'max_consecutive_hours' or 'max_hours_per_day' values of the involved teachers."
        )

    # Diagnosis 1b: Disable subject hour limits (consecutive and daily)
    status_no_subj_limits, _ = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_consec_map, subjects_daily_map,
        ignore_constraints=False,
        ignore_settings=False,
        ignore_subject_limits=True,
        max_time_seconds=3.0
    )

    if status_no_subj_limits in ("OPTIMAL", "FEASIBLE"):
        return (
            False,
            "Unable to generate the timetable with the consecutive or daily hour limits set for the subjects.",
            [],
            "The problem becomes solvable by disabling restrictions on consecutive or daily hour limits per subject. "
            "Suggestion: increase the 'max_consecutive_hours' or 'max_hours_per_day' values of the involved subjects."
        )
        
    # Diagnosis 2: Disable teacher unavailability slots (constraints)
    status_no_constraints, _ = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_consec_map, subjects_daily_map,
        ignore_constraints=True,
        ignore_settings=False,
        ignore_subject_limits=False,
        max_time_seconds=3.0
    )
    
    if status_no_constraints in ("OPTIMAL", "FEASIBLE"):
        return (
            False,
            "Unable to generate the timetable due to too many conflicts in the teacher unavailability slots.",
            [],
            "The problem becomes solvable by removing the blocked hours (unavailability) of the teachers. "
            "The entered unavailability constraints overlap and make it impossible to place all the required lessons. "
            "Suggestion: reduce the number of blocked hours in the teachers' calendars."
        )

    # Diagnosis 3: Disable settings, subject limits, and unavailability
    status_clean, _ = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_consec_map, subjects_daily_map,
        ignore_constraints=True,
        ignore_settings=True,
        ignore_subject_limits=True,
        max_time_seconds=3.0
    )
    
    if status_clean in ("OPTIMAL", "FEASIBLE"):
        return (
            False,
            "Combined conflict between availability and hour limits.",
            [],
        )

    # Structural failure (e.g. oversaturation or unsolvable assignment collisions)
    return (
        False,
        "Unable to find a valid timetable combination.",
        [],
        "Unsolvable structural conflict in the class assignments (chairs). "
        "This typically happens if multiple teachers/classes have incompatible co-occurrence constraints or "
        "if the overall distribution of weekly hours exceeds the physical limits of the school structure. "
        "Suggestion: carefully check the entered weekly assignments."
    )
