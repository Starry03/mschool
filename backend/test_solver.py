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
    print("=== INIZIO TEST DEL SOLVER ===")
    
    # 1. Crea un database SQLite in memoria per i test
    # (così non abbiamo bisogno di MySQL attivo per verificare la logica del solver)
    engine = create_engine("sqlite:///:memory:")
    SessionTesting = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    
    # Crea le tabelle
    Base.metadata.create_all(bind=engine)
    db = SessionTesting()
    
    try:
        # 2. Inserisci configurazione globale della scuola
        settings = SchoolSettings(id=1, days_per_week=5, hours_per_day=6)
        db.add(settings)
        
        # 3. Inserisci Docenti
        t_rossi = Teacher(id=1, first_name="Mario", last_name="Rossi", email="mario.rossi@school.it")
        t_verdi = Teacher(id=2, first_name="Luigi", last_name="Verdi", email="luigi.verdi@school.it")
        t_bianchi = Teacher(id=3, first_name="Anna", last_name="Bianchi", email="anna.bianchi@school.it")
        db.add_all([t_rossi, t_verdi, t_bianchi])
        db.commit()
        
        # Inizializza impostazioni docenti
        ts_rossi = TeacherSettings(teacher_id=1, max_consecutive_hours=3, max_hours_per_day=4)
        ts_verdi = TeacherSettings(teacher_id=2, max_consecutive_hours=3, max_hours_per_day=5)
        ts_bianchi = TeacherSettings(teacher_id=3, max_consecutive_hours=4, max_hours_per_day=5)
        db.add_all([ts_rossi, ts_verdi, ts_bianchi])
        
        # Aggiungi vincoli docenti (indisponibilità)
        # Rossi non può il lunedì (giorno 0) alle prime 2 ore (ore 0, 1)
        c_rossi1 = TeacherConstraint(teacher_id=1, day=0, hour=0)
        c_rossi2 = TeacherConstraint(teacher_id=1, day=0, hour=1)
        # Verdi non può il mercoledì (giorno 2) all'ultima ora (ora 5)
        c_verdi = TeacherConstraint(teacher_id=2, day=2, hour=5)
        db.add_all([c_rossi1, c_rossi2, c_verdi])
        
        # 4. Inserisci Classi
        c_1a = SchoolClass(id=1, name="1A")
        c_2b = SchoolClass(id=2, name="2B")
        db.add_all([c_1a, c_2b])
        
        # 5. Inserisci Materie
        s_math = Subject(id=1, name="Matematica")
        s_ita = Subject(id=2, name="Italiano")
        s_sci = Subject(id=3, name="Scienze")
        db.add_all([s_math, s_ita, s_sci])
        db.commit()
        
        # 6. Inserisci Assegnazioni (weekly_hours totali per classe: 1A=14h, 2B=14h)
        a_math_1a = Assignment(teacher_id=1, class_id=1, subject_id=1, weekly_hours=5)
        a_math_2b = Assignment(teacher_id=1, class_id=2, subject_id=1, weekly_hours=5)
        a_ita_1a = Assignment(teacher_id=2, class_id=1, subject_id=2, weekly_hours=5)
        a_ita_2b = Assignment(teacher_id=2, class_id=2, subject_id=2, weekly_hours=5)
        a_sci_1a = Assignment(teacher_id=3, class_id=1, subject_id=3, weekly_hours=4)
        a_sci_2b = Assignment(teacher_id=3, class_id=2, subject_id=3, weekly_hours=4)
        db.add_all([a_math_1a, a_math_2b, a_ita_1a, a_ita_2b, a_sci_1a, a_sci_2b])
        db.commit()
        
        print("\n[TEST 1] Risoluzione di un problema fattibile standard...")
        success, msg, slots, err = generate_timetable(db, max_time_seconds=5.0)
        
        print(f"Successo: {success}")
        print(f"Messaggio: {msg}")
        print(f"Slot generati: {len(slots)}")
        if err:
            print(f"Dettaglio Errore: {err}")
            
        assert success is True, "Il test del solver fattibile ha fallito!"
        assert len(slots) == 28, f"Avrebbero dovuto esserci 28 slot generati, trovati {len(slots)}"
        
        # Stampiamo l'orario generato per verifica visiva
        giorni_nomi = ["Lun", "Mar", "Mer", "Gio", "Ven"]
        for cid in [1, 2]:
            cname = "1A" if cid == 1 else "2B"
            print(f"\n--- Orario Classe {cname} ---")
            print(f"{'Ora':<6} | " + " | ".join(f"{g:<12}" for g in giorni_nomi))
            print("-" * 80)
            for h in range(6):
                riga = f"Ora {h+1}  "
                for g in range(5):
                    # Trova slot
                    slot = next((s for s in slots if s["class_id"] == cid and s["day"] == g and s["hour"] == h), None)
                    if slot:
                        t = db.query(Teacher).get(slot["teacher_id"])
                        sub = db.query(Subject).get(slot["subject_id"])
                        riga += f"| {t.last_name + ' (' + sub.name[:3] + ')':<12} "
                    else:
                        riga += f"| {'Libero':<12} "
                print(riga)
                
        # ---------------------------------------------------------------------
        # TEST 2: Fallimento per sovraccarico della classe (pre-check)
        # ---------------------------------------------------------------------
        print("\n[TEST 2] Verifica pre-check: Sovraccarico ore classe...")
        # Cambia ore Matematica in 1A a 35 ore (il totale della settimana è 30 ore max!)
        a_math_1a.weekly_hours = 35
        db.commit()
        
        success, msg, slots, err = generate_timetable(db, max_time_seconds=2.0)
        print(f"Successo: {success} (Atteso: False)")
        print(f"Messaggio: {msg}")
        print(f"Dettaglio Errore: {err}")
        
        assert success is False, "Il solver avrebbe dovuto fallire per sovraccarico classe!"
        assert "troppe ore assegnate" in msg.lower(), "Messaggio di errore non corrispondente!"
        
        # Ripristina
        a_math_1a.weekly_hours = 5
        db.commit()

        # ---------------------------------------------------------------------
        # TEST 3: Fallimento per troppi vincoli (diagnostica solver)
        # ---------------------------------------------------------------------
        print("\n[TEST 3] Verifica diagnostica: Conflitto indisponibilità docenti...")
        # Elimina i vincoli orari esistenti per evitare conflitti UNIQUE
        db.query(TeacherConstraint).delete()
        db.commit()
        # Rendiamo Rossi (che insegna 10 ore in totale) indisponibile per tutti i giorni tranne 1 ora
        # Total slots = 30. Mettiamo 29 indisponibilità.
        for g in range(5):
            for h in range(6):
                if g == 0 and h == 2:
                    continue # Lascia solo 1 slot libero
                db.add(TeacherConstraint(teacher_id=1, day=g, hour=h))
        db.commit()
        
        success, msg, slots, err = generate_timetable(db, max_time_seconds=2.0)
        print(f"Successo: {success} (Atteso: False)")
        print(f"Messaggio: {msg}")
        print(f"Dettaglio Errore: {err}")
        
        assert success is False, "Il solver avrebbe dovuto fallire per indisponibilità docente!"
        # Dovrebbe essere preso dal pre-check (10 ore assegnate, solo 1 disponibile)
        assert "disponibilità" in msg.lower(), "Il pre-check avrebbe dovuto rilevare la carenza di ore disponibili!"
        
        print("\n=== TUTTI I TEST DEL SOLVER SONO PASSAATI CON SUCCESSO! ===")
        
    finally:
        db.close()

if __name__ == "__main__":
    run_tests()
