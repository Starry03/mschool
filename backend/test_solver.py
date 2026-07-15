import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
import app.patch_pydantic
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.database import Base
from app.models.school_settings import SchoolSettings
from app.models.teacher import Teacher
from app.models.teacher_settings import TeacherSettings
from app.models.teacher_constraint import TeacherConstraint
from app.models.school_class import SchoolClass
from app.models.subject import Subject
from app.models.assignment import Assignment
from app.models.timetable_slot import TimetableSlot
from app.services.solver import generate_timetable

def run_tests():
    print("=== START OF SOLVER TESTS ===")
    
    # 1. Create an in-memory SQLite database for testing
    # (so we do not need MySQL active to verify the solver logic)
    engine = create_engine("sqlite:///:memory:")
    SessionTesting = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    db = SessionTesting()
    
    try:
        # 2. Insert global school settings
        settings = SchoolSettings(id=1, days_per_week=5, hours_per_day=6)
        db.add(settings)
        
        # 3. Insert Teachers
        t_rossi = Teacher(id=1, first_name="Mario", last_name="Rossi", email="mario.rossi@school.it")
        t_verdi = Teacher(id=2, first_name="Luigi", last_name="Verdi", email="luigi.verdi@school.it")
        t_bianchi = Teacher(id=3, first_name="Anna", last_name="Bianchi", email="anna.bianchi@school.it")
        db.add_all([t_rossi, t_verdi, t_bianchi])
        db.commit()
        
        # Initialize teacher settings
        ts_rossi = TeacherSettings(teacher_id=1, max_consecutive_hours=3, max_hours_per_day=4)
        ts_verdi = TeacherSettings(teacher_id=2, max_consecutive_hours=3, max_hours_per_day=5)
        ts_bianchi = TeacherSettings(teacher_id=3, max_consecutive_hours=4, max_hours_per_day=5)
        db.add_all([ts_rossi, ts_verdi, ts_bianchi])
        
        # Add teacher constraints (unavailability)
        # Rossi is unavailable on Monday (day 0) at the first 2 hours (hours 0, 1)
        c_rossi1 = TeacherConstraint(teacher_id=1, day=0, hour=0)
        c_rossi2 = TeacherConstraint(teacher_id=1, day=0, hour=1)
        # Verdi is unavailable on Wednesday (day 2) at the last hour (hour 5)
        c_verdi = TeacherConstraint(teacher_id=2, day=2, hour=5)
        db.add_all([c_rossi1, c_rossi2, c_verdi])
        
        # 4. Insert Classes
        c_1a = SchoolClass(id=1, name="1A")
        c_2b = SchoolClass(id=2, name="2B")
        db.add_all([c_1a, c_2b])
        
        # 5. Insert Subjects
        s_math = Subject(id=1, name="Mathematics")
        s_ita = Subject(id=2, name="Italian")
        s_sci = Subject(id=3, name="Science")
        db.add_all([s_math, s_ita, s_sci])
        db.commit()
        
        # 6. Insert Assignments (total weekly hours per class: 1A=14h, 2B=14h)
        a_math_1a = Assignment(teacher_id=1, class_id=1, subject_id=1, weekly_hours=5)
        a_math_2b = Assignment(teacher_id=1, class_id=2, subject_id=1, weekly_hours=5)
        a_ita_1a = Assignment(teacher_id=2, class_id=1, subject_id=2, weekly_hours=5)
        a_ita_2b = Assignment(teacher_id=2, class_id=2, subject_id=2, weekly_hours=5)
        a_sci_1a = Assignment(teacher_id=3, class_id=1, subject_id=3, weekly_hours=4)
        a_sci_2b = Assignment(teacher_id=3, class_id=2, subject_id=3, weekly_hours=4)
        db.add_all([a_math_1a, a_math_2b, a_ita_1a, a_ita_2b, a_sci_1a, a_sci_2b])
        db.commit()
        
        print("\n[TEST 1] Solving a standard feasible problem...")
        success, msg, slots, err = generate_timetable(db, max_time_seconds=5.0)
        
        print(f"Success: {success}")
        print(f"Message: {msg}")
        print(f"Generated slots: {len(slots)}")
        if err:
            print(f"Error Detail: {err}")
            
        assert success is True, "The feasible solver test failed!"
        assert len(slots) == 28, f"Should have been 28 generated slots, found {len(slots)}"
        
        # Print the generated timetable for visual verification
        giorni_nomi = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        for cid in [1, 2]:
            cname = "1A" if cid == 1 else "2B"
            print(f"\n--- Class Timetable {cname} ---")
            print(f"{'Hour':<6} | " + " | ".join(f"{g:<12}" for g in giorni_nomi))
            print("-" * 80)
            for h in range(6):
                riga = f"Hour {h+1}  "
                for g in range(5):
                    # Find slot
                    slot = next((s for s in slots if s["class_id"] == cid and s["day"] == g and s["hour"] == h), None)
                    if slot:
                        t = db.query(Teacher).get(slot["teacher_id"])
                        sub = db.query(Subject).get(slot["subject_id"])
                        riga += f"| {t.last_name + ' (' + sub.name[:3] + ')':<12} "
                    else:
                        riga += f"| {'Free':<12} "
                print(riga)
                
        # ---------------------------------------------------------------------
        # TEST 2: Failure due to class overload (pre-check)
        # ---------------------------------------------------------------------
        print("\n[TEST 2] Verification pre-check: Class hour overload...")
        # Change Mathematics hours in 1A to 35 hours (the weekly total is 30 hours max!)
        a_math_1a.weekly_hours = 35
        db.commit()
        
        success, msg, slots, err = generate_timetable(db, max_time_seconds=2.0)
        print(f"Success: {success} (Expected: False)")
        print(f"Message: {msg}")
        print(f"Error Detail: {err}")
        
        assert success is False, "The solver should have failed due to class overload!"
        assert "too many assigned hours" in msg.lower(), "Error message mismatch!"
        
        # Restore
        a_math_1a.weekly_hours = 5
        db.commit()

        # ---------------------------------------------------------------------
        # TEST 3: Failure due to too many constraints (solver diagnosis)
        # ---------------------------------------------------------------------
        print("\n[TEST 3] Verification diagnosis: Teacher unavailability conflict...")
        # Delete existing constraints to avoid UNIQUE conflicts
        db.query(TeacherConstraint).delete()
        db.commit()
        # We make Rossi (who teaches 10 hours in total) unavailable for all days except 1 hour
        # Total slots = 30. We add 29 unavailabilities.
        for g in range(5):
            for h in range(6):
                if g == 0 and h == 2:
                    continue # Leave only 1 slot free
                db.add(TeacherConstraint(teacher_id=1, day=g, hour=h))
        db.commit()
        
        success, msg, slots, err = generate_timetable(db, max_time_seconds=2.0)
        print(f"Success: {success} (Expected: False)")
        print(f"Message: {msg}")
        print(f"Error Detail: {err}")
        
        assert success is False, "The solver should have failed due to teacher unavailability!"
        # Should be caught by pre-check (10 hours assigned, only 1 available)
        assert "availability" in msg.lower(), "The pre-check should have detected the lack of available hours!"
        
        print("\n=== ALL SOLVER TESTS PASSED SUCCESSFULLY! ===")
        
    finally:
        db.close()

if __name__ == "__main__":
    run_tests()
