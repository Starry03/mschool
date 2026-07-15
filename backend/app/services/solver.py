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
    subject_constraints: List[ClassSubjectConstraint]
) -> None:
    """
    Esegue controlli aritmetici preventivi sui dati per rilevare conflitti evidenti prima di avviare il solver.
    Solleva SolverDiagnosticException se viene trovato un errore.
    """
    total_slots = days * hours

    # 1. Controlla che le ore totali assegnate a ciascuna classe non superino la capacità della scuola
    for c in classes:
        class_assignments = [a for a in assignments if a.class_id == c.id]
        class_hours = sum(a.weekly_hours for a in class_assignments)
        if class_hours > total_slots:
            raise SolverDiagnosticException(
                message=f"La classe '{c.name}' ha troppe ore assegnate.",
                details=(
                    f"Ore assegnate: {class_hours}. "
                    f"Capacità massima settimanale della scuola: {total_slots} ore "
                    f"({days} giorni x {hours} ore giornaliere)."
                )
            )

    # 2. Controlla che le ore totali assegnate a ciascun docente non superino la sua disponibilità netta
    for t in teachers:
        teacher_assignments = [a for a in assignments if a.teacher_id == t.id]
        teacher_hours = sum(a.weekly_hours for a in teacher_assignments)
        
        # Sottrai dal totale delle ore gli slot in cui il docente è indisponibile
        t_constraints = constraints_map.get(t.id, [])
        unavailable_slots = len(t_constraints)
        available_slots = total_slots - unavailable_slots
        
        if teacher_hours > total_slots:
            raise SolverDiagnosticException(
                message=f"Il docente '{t.first_name} {t.last_name or ''}' ha un carico orario eccessivo.",
                details=(
                    f"Il docente ha {teacher_hours} ore assegnate, "
                    f"ma la settimana scolastica ha solo {total_slots} ore in totale."
                )
            )
            
        if teacher_hours > available_slots:
            raise SolverDiagnosticException(
                message=f"Il docente '{t.first_name} {t.last_name or ''}' ha troppe ore assegnate rispetto alla sua disponibilità.",
                details=(
                    f"Il docente ha {teacher_hours} ore assegnate, "
                    f"ma ha solo {available_slots} ore disponibili a causa di {unavailable_slots} ore di indisponibilità inserite."
                )
            )

    # 3. Controlla i vincoli sul numero di ore settimanali obbligatorie per materia e classe
    for sc in subject_constraints:
        class_sub_assigns = [a for a in assignments if a.class_id == sc.class_id and a.subject_id == sc.subject_id]
        assigned_hours = sum(a.weekly_hours for a in class_sub_assigns)
        if assigned_hours != sc.weekly_hours:
            class_name = sc.school_class.name if sc.school_class else f"ID {sc.class_id}"
            subject_name = sc.subject.name if sc.subject else f"ID {sc.subject_id}"
            raise SolverDiagnosticException(
                message=f"Rilevata incongruenza sul vincolo ore della materia per la classe.",
                details=(
                    f"Il vincolo per la classe '{class_name}' e la materia '{subject_name}' richiede esattamente {sc.weekly_hours} ore, "
                    f"ma sono state assegnate {assigned_hours} ore nelle cattedre."
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
    Costruisce e risolve il modello CP-SAT. Permette di disattivare selettivamente vincoli
    per finalità di diagnostica.
    Ritorna una tupla (status_name, lista_slot_generati).
    """
    if subjects_map is None:
        subjects_map = {}
    model = cp_model.CpModel()

    
    # Insieme dei giorni e delle ore
    giorni_range = range(days)
    ore_range = range(hours)
    
    # 1. Variabili decisionali
    # x[a_id, g, h] = 1 se l'assegnazione 'a' è programmata al giorno 'g' all'ora 'h', 0 altrimenti
    x = {}
    for a in assignments:
        for g in giorni_range:
            for h in ore_range:
                x[a.id, g, h] = model.NewBoolVar(f"x_a{a.id}_g{g}_h{h}")
                
    # Variabili di presenza per docente t al giorno g all'ora h
    # y[t_id, g, h] = 1 se il docente t insegna al giorno g all'ora h
    y = {}
    for t in teachers:
        for g in giorni_range:
            for h in ore_range:
                # Trova tutte le assegnazioni associate a questo docente
                teacher_assigns = [a for a in assignments if a.teacher_id == t.id]
                y[t.id, g, h] = model.NewBoolVar(f"y_t{t.id}_g{g}_h{h}")
                
                # y[t,g,h] è la somma delle x delle sue assegnazioni per quell'ora
                model.Add(y[t.id, g, h] == sum(x[a.id, g, h] for a in teacher_assigns))

    # -------------------------------------------------------------------------
    # VINCOLI HARD
    # -------------------------------------------------------------------------

    # A. Soddisfare il monte ore settimanale per ogni assegnazione
    for a in assignments:
        model.Add(sum(x[a.id, g, h] for g in giorni_range for h in ore_range) == a.weekly_hours)

    # B. Contemporaneità Docente: Un docente fa al massimo 1 lezione per ora (già garantito da y[t,g,h] <= 1)
    for t in teachers:
        for g in giorni_range:
            for h in ore_range:
                model.Add(y[t.id, g, h] <= 1)

    # C. Contemporaneità Classe: Una classe fa al massimo 1 lezione per ora
    for c in classes:
        class_assigns = [a for a in assignments if a.class_id == c.id]
        for g in giorni_range:
            for h in ore_range:
                model.Add(sum(x[a.id, g, h] for a in class_assigns) <= 1)

    # D. Fasce di Indisponibilità dei Docenti (teacher_constraints)
    if not ignore_constraints:
        for t in teachers:
            t_constraints = constraints_map.get(t.id, [])
            for (g_ind, h_ind) in t_constraints:
                # Controlla che le indisponibilità rientrino nella griglia corrente
                if g_ind < days and h_ind < hours:
                    model.Add(y[t.id, g_ind, h_ind] == 0)

    # E. Limiti orari dei Docenti (teacher_settings)
    if not ignore_settings:
        for t in teachers:
            t_settings = settings_map.get(t.id)
            if not t_settings:
                continue
                
            # Limite ore consecutive
            max_consec = t_settings.max_consecutive_hours
            if max_consec < hours:
                # Finestra mobile di ampiezza max_consec + 1
                for g in giorni_range:
                    for h in range(hours - max_consec):
                        model.Add(
                            sum(y[t.id, g, h + offset] for offset in range(max_consec + 1)) <= max_consec
                        )
                        
            # Limite ore giornaliere
            max_day = t_settings.max_hours_per_day
            if max_day < hours:
                for g in giorni_range:
                    model.Add(sum(y[t.id, g, h] for h in ore_range) <= max_day)

    # F. Limite ore consecutive per materia (subject.max_consecutive_hours)
    # Per ogni materia con limite impostato, per ogni classe e giorno:
    # la somma degli slot della materia in qualsiasi finestra di max+1 ore deve essere <= max
    for c in classes:
        class_assigns = [a for a in assignments if a.class_id == c.id]
        subj_assigns_map: Dict[int, list] = {}
        for a in class_assigns:
            subj_assigns_map.setdefault(a.subject_id, []).append(a)

        for subj_id, subj_assign_list in subj_assigns_map.items():
            max_consec_subj = subjects_map.get(subj_id)
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

    # -------------------------------------------------------------------------
    # VINCOLI SOFT (Ottimizzazione: Minimizzazione dei Buchi)
    # -------------------------------------------------------------------------
    gap_vars = []
    
    # Minimizziamo i buchi solo se non stiamo facendo una diagnostica super rilassata
    for t in teachers:
        for g in giorni_range:
            # has_taught_before[h] = 1 se il docente ha insegnato in un'ora < h nello stesso giorno
            has_taught_before = {}
            # has_taught_after[h] = 1 se il docente insegna in un'ora > h nello stesso giorno
            has_taught_after = {}
            
            # Un buco può avvenire solo dalle ore centrali (da 1 a hours-2)
            for h in range(1, hours - 1):
                has_taught_before[h] = model.NewBoolVar(f"before_t{t.id}_g{g}_h{h}")
                has_taught_after[h] = model.NewBoolVar(f"after_t{t.id}_g{g}_h{h}")
                
                # has_taught_before[h] è 1 se sum(y[t, g, k] per k < h) >= 1
                # Lo modelliamo linearmente:
                # 1. has_taught_before[h] >= y[t, g, k] per ogni k < h
                for k in range(h):
                    model.Add(has_taught_before[h] >= y[t.id, g, k])
                # 2. has_taught_before[h] <= sum(y[t, g, k] per k < h)
                model.Add(has_taught_before[h] <= sum(y[t.id, g, k] for k in range(h)))
                
                # has_taught_after[h] è 1 se sum(y[t, g, k] per k > h) >= 1
                # 1. has_taught_after[h] >= y[t, g, k] per ogni k > h
                for k in range(h + 1, hours):
                    model.Add(has_taught_after[h] >= y[t.id, g, k])
                # 2. has_taught_after[h] <= sum(y[t, g, k] per k > h)
                model.Add(has_taught_after[h] <= sum(y[t.id, g, k] for k in range(h + 1, hours)))
                
                # gap[t, g, h] è 1 se has_taught_before[h] == 1 AND has_taught_after[h] == 1 AND y[t, g, h] == 0
                gap = model.NewBoolVar(f"gap_t{t.id}_g{g}_h{h}")
                # Modello lineare per AND logico con y negato:
                # gap >= before + after - y - 1
                model.Add(gap >= has_taught_before[h] + has_taught_after[h] - y[t.id, g, h] - 1)
                
                gap_vars.append(gap)

    # -------------------------------------------------------------------------
    # VINCOLO SOFT: Consecutività ore stessa materia per classe nello stesso giorno
    # (Soft: le ore vengono premiate nella funzione obiettivo se consecutive)
    # -------------------------------------------------------------------------
    CONSECUTIVITY_WEIGHT = 20  # Peso premium per ogni coppia di ore consecutive della stessa materia
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
                    # z[c, s, g, h] = 1 se materia s è insegnata alla classe c nel giorno g ora h
                    z_h = sum(x[a.id, g, h] for a in subj_assign_list)
                    z_h1 = sum(x[a.id, g, h + 1] for a in subj_assign_list)
                    
                    # consec = 1 se z_h == 1 AND z_h1 == 1
                    consec = model.NewBoolVar(f"consec_c{c.id}_s{subject_id}_g{g}_h{h}")
                    # Model consec <= z_h and consec <= z_h1 and consec >= z_h + z_h1 - 1
                    model.Add(consec <= z_h)
                    model.Add(consec <= z_h1)
                    model.Add(consec >= z_h + z_h1 - 1)
                    consec_vars.append(consec)

    # -------------------------------------------------------------------------
    # VINCOLO SOFT: Consecutività ore del docente nello stesso giorno (prefer_consecutive)
    # Se il docente ha prefer_consecutive=True, viene premiato per ogni coppia di
    # ore consecutive insegnate nello stesso giorno (indipendentemente dalla classe/materia).
    # -------------------------------------------------------------------------
    TEACHER_CONSEC_WEIGHT = 15  # Peso leggermente inferiore al vincolo per materia
    teacher_consec_vars = []

    for t in teachers:
        t_settings = settings_map.get(t.id)
        if not t_settings or not t_settings.prefer_consecutive:
            continue
        for g in giorni_range:
            for h in range(hours - 1):
                # tc = 1 se il docente insegna sia all'ora h che h+1 nello stesso giorno
                tc = model.NewBoolVar(f"tcons_t{t.id}_g{g}_h{h}")
                model.Add(tc <= y[t.id, g, h])
                model.Add(tc <= y[t.id, g, h + 1])
                model.Add(tc >= y[t.id, g, h] + y[t.id, g, h + 1] - 1)
                teacher_consec_vars.append(tc)

    # Minimizzare i buchi e massimizzare la consecutività delle materie e dei docenti
    if gap_vars or consec_vars or teacher_consec_vars:
        objective_terms = []
        if gap_vars:
            objective_terms.extend(gap_vars)
        if consec_vars:
            objective_terms.extend([-CONSECUTIVITY_WEIGHT * c for c in consec_vars])
        if teacher_consec_vars:
            objective_terms.extend([-TEACHER_CONSEC_WEIGHT * tc for tc in teacher_consec_vars])
        model.Minimize(sum(objective_terms))

    # 2. Esecuzione del Solver
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
    Risolve il problema del timetabling scolastico estraendo i dati dal database,
    eseguendo pre-controlli e lanciando il solver Google OR-Tools CP-SAT.
    
    In caso di fallimento, esegue una diagnosi automatica per spiegare il motivo.
    
    Ritorna una tupla (success, message, slots_list, error_details).
    """
    # 1. Carica impostazioni globali della scuola
    school_settings = db.query(SchoolSettings).filter(SchoolSettings.id == 1).first()
    if not school_settings:
        # Default fallback
        days = 5
        hours = 6
    else:
        days = school_settings.days_per_week
        hours = school_settings.hours_per_day
        
    # 2. Carica anagrafiche e assegnazioni
    classes = db.query(SchoolClass).all()
    teachers = db.query(Teacher).all()
    assignments = db.query(Assignment).all()
    subject_constraints = db.query(ClassSubjectConstraint).all()
    
    if not classes:
        return False, "Nessuna classe inserita nel database. Impossibile generare l'orario.", [], None
    if not teachers:
        return False, "Nessun docente inserito nel database. Impossibile generare l'orario.", [], None
    if not assignments:
        return False, "Nessuna assegnazione cattedra inserita nel database. Impossibile generare l'orario.", [], None

    # Mappa le indisponibilità per docente
    constraints_map = {}
    for t in teachers:
        constraints_map[t.id] = [(c.day, c.hour) for c in t.constraints]
        
    # Mappa le impostazioni per docente
    settings_map = {}
    for t in teachers:
        if t.settings:
            settings_map[t.id] = t.settings

    # Mappa il limite di ore consecutive per materia (subject_id -> max_consecutive_hours o None)
    subjects = db.query(Subject).all()
    subjects_map = {s.id: s.max_consecutive_hours for s in subjects}

    # 3. Esegui pre-controlli aritmetici preventivi
    try:
        run_pre_checks(days, hours, classes, teachers, assignments, constraints_map, subject_constraints)
    except SolverDiagnosticException as ex:
        return False, ex.message, [], ex.details

    # 4. Tenta di risolvere il modello completo
    status_name, slots = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_map,
        max_time_seconds=max_time_seconds
    )
    
    if status_name in ("OPTIMAL", "FEASIBLE"):
        return True, "Orario scolastico generato con successo!", slots, None
        
    # -------------------------------------------------------------------------
    # DIAGNOSTICA DEL FALLIMENTO
    # Se il solver fallisce, disattiviamo i vincoli a blocchi per capire il motivo.
    # -------------------------------------------------------------------------
    
    # Diagnosi 1: Disattiva i limiti orari giornalieri e consecutivi (settings)
    status_no_settings, _ = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_map,
        ignore_constraints=False,
        ignore_settings=True,
        max_time_seconds=3.0
    )
    
    if status_no_settings in ("OPTIMAL", "FEASIBLE"):
        return (
            False,
            "Impossibile generare l'orario con i limiti di ore consecutive o giornaliere impostati per i docenti.",
            [],
            "Il problema diventa risolvibile disattivando le restrizioni sulle ore consecutive e sui limiti di ore giornaliere per docente. "
            "Suggerimento: aumenta i valori di 'max_consecutive_hours' o 'max_hours_per_day' dei docenti coinvolti."
        )
        
    # Diagnosi 2: Disattiva le fasce di indisponibilità dei docenti (constraints)
    status_no_constraints, _ = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_map,
        ignore_constraints=True,
        ignore_settings=False,
        max_time_seconds=3.0
    )
    
    if status_no_constraints in ("OPTIMAL", "FEASIBLE"):
        return (
            False,
            "Impossibile generare l'orario a causa di troppi conflitti nelle fasce di indisponibilità dei docenti.",
            [],
            "Il problema diventa risolvibile rimuovendo le ore bloccate (indisponibilità) dei docenti. "
            "I vincoli di indisponibilità inseriti si sovrappongono e rendono impossibile collocare tutte le lezioni richieste. "
            "Suggerimento: riduci il numero di ore bloccate nei calendari dei docenti."
        )

    # Diagnosi 3: Disattiva sia i settings che le indisponibilità
    status_clean, _ = build_and_solve_model(
        days, hours, classes, teachers, assignments,
        constraints_map, settings_map, subjects_map,
        ignore_constraints=True,
        ignore_settings=True,
        max_time_seconds=3.0
    )
    
    if status_clean in ("OPTIMAL", "FEASIBLE"):
        return (
            False,
            "Conflitto combinato tra indisponibilità e limiti orari dei docenti.",
            [],
            "L'orario non è risolvibile a causa della combinazione tra i vincoli di indisponibilità oraria e le preferenze di ore consecutive/giornaliere dei docenti. "
            "Suggerimento: prova a rilassare sia le indisponibilità che i limiti orari di alcuni docenti."
        )

    # Fallimento strutturale (es. sovrasaturazione o collisioni di assegnazioni irrisolvibili)
    return (
        False,
        "Impossibile trovare una combinazione oraria valida.",
        [],
        "Conflitto strutturale irrisolvibile nelle assegnazioni cattedre. "
        "Questo accade tipicamente se più docenti/classi hanno vincoli di contemporaneità incompatibili o "
        "se la ripartizione complessiva delle ore settimanali saturate supera i limiti fisici della struttura scolastica. "
        "Suggerimento: verifica attentamente le assegnazioni settimanali inserite."
    )
