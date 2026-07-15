class SchoolSettings {
  final int id;
  final int daysPerWeek;
  final int hoursPerDay;

  SchoolSettings({
    required this.id,
    required this.daysPerWeek,
    required this.hoursPerDay,
  });

  factory SchoolSettings.fromJson(Map<String, dynamic> json) {
    return SchoolSettings(
      id: json['id'] ?? 1,
      daysPerWeek: json['days_per_week'] ?? 5,
      hoursPerDay: json['hours_per_day'] ?? 6,
    );
  }

  Map<String, dynamic> toJson() {
    return {'days_per_week': daysPerWeek, 'hours_per_day': hoursPerDay};
  }
}

class TeacherSettings {
  final int teacherId;
  final int maxConsecutiveHours;
  final int maxHoursPerDay;
  final bool preferConsecutive;

  TeacherSettings({
    required this.teacherId,
    required this.maxConsecutiveHours,
    required this.maxHoursPerDay,
    this.preferConsecutive = false,
  });

  factory TeacherSettings.fromJson(Map<String, dynamic> json) {
    return TeacherSettings(
      teacherId: json['teacher_id'],
      maxConsecutiveHours: json['max_consecutive_hours'] ?? 3,
      maxHoursPerDay: json['max_hours_per_day'] ?? 5,
      preferConsecutive: json['prefer_consecutive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'max_consecutive_hours': maxConsecutiveHours,
      'max_hours_per_day': maxHoursPerDay,
      'prefer_consecutive': preferConsecutive,
    };
  }
}

class TeacherConstraint {
  final int id;
  final int teacherId;
  final int day;
  final int hour;

  TeacherConstraint({
    required this.id,
    required this.teacherId,
    required this.day,
    required this.hour,
  });

  factory TeacherConstraint.fromJson(Map<String, dynamic> json) {
    return TeacherConstraint(
      id: json['id'],
      teacherId: json['teacher_id'],
      day: json['day'],
      hour: json['hour'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'hour': hour};
  }
}

class Teacher {
  final int id;
  final String firstName;
  final String? lastName;
  final String? email;
  final TeacherSettings? settings;
  final List<TeacherConstraint> constraints;

  Teacher({
    required this.id,
    required this.firstName,
    this.lastName,
    this.email,
    this.settings,
    this.constraints = const [],
  });

  String get fullName => lastName != null && lastName!.isNotEmpty
      ? '$firstName $lastName'
      : firstName;

  factory Teacher.fromJson(Map<String, dynamic> json) {
    var constraintsList = json['constraints'] as List? ?? [];
    return Teacher(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      settings: json['settings'] != null
          ? TeacherSettings.fromJson(json['settings'])
          : null,
      constraints: constraintsList
          .map((c) => TeacherConstraint.fromJson(c))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) => other is Teacher && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class SchoolClass {
  final int id;
  final String name;

  SchoolClass({required this.id, required this.name});

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(id: json['id'], name: json['name']);
  }

  @override
  bool operator ==(Object other) => other is SchoolClass && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Subject {
  final int id;
  final String name;
  final int? maxConsecutiveHours;

  Subject({required this.id, required this.name, this.maxConsecutiveHours});

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      maxConsecutiveHours: json['max_consecutive_hours'],
    );
  }

  @override
  bool operator ==(Object other) => other is Subject && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Assignment {
  final int id;
  final int teacherId;
  final int classId;
  final int subjectId;
  final int weeklyHours;

  // Detailed info (optional)
  final Teacher? teacher;
  final SchoolClass? schoolClass;
  final Subject? subject;

  Assignment({
    required this.id,
    required this.teacherId,
    required this.classId,
    required this.subjectId,
    required this.weeklyHours,
    this.teacher,
    this.schoolClass,
    this.subject,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      teacherId: json['teacher_id'],
      classId: json['class_id'],
      subjectId: json['subject_id'],
      weeklyHours: json['weekly_hours'],
      teacher: json['teacher'] != null
          ? Teacher.fromJson(json['teacher'])
          : null,
      schoolClass: json['school_class'] != null
          ? SchoolClass.fromJson(json['school_class'])
          : null,
      subject: json['subject'] != null
          ? Subject.fromJson(json['subject'])
          : null,
    );
  }
}

class TimetableSlot {
  final int id;
  final int day;
  final int hour;
  final int classId;
  final int teacherId;
  final int subjectId;

  final SchoolClass schoolClass;
  final Teacher teacher;
  final Subject subject;

  TimetableSlot({
    required this.id,
    required this.day,
    required this.hour,
    required this.classId,
    required this.teacherId,
    required this.subjectId,
    required this.schoolClass,
    required this.teacher,
    required this.subject,
  });

  factory TimetableSlot.fromJson(Map<String, dynamic> json) {
    return TimetableSlot(
      id: json['id'],
      day: json['day'],
      hour: json['hour'],
      classId: json['class_id'],
      teacherId: json['teacher_id'],
      subjectId: json['subject_id'],
      schoolClass: SchoolClass.fromJson(json['school_class']),
      teacher: Teacher.fromJson(json['teacher']),
      subject: Subject.fromJson(json['subject']),
    );
  }
}

class TimetableGenerateResponse {
  final bool success;
  final String message;
  final List<TimetableSlot> timetable;
  final String? errorDetails;

  TimetableGenerateResponse({
    required this.success,
    required this.message,
    required this.timetable,
    this.errorDetails,
  });

  factory TimetableGenerateResponse.fromJson(Map<String, dynamic> json) {
    var timetableList = json['timetable'] as List? ?? [];
    return TimetableGenerateResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      timetable: timetableList.map((t) => TimetableSlot.fromJson(t)).toList(),
      errorDetails: json['error_details'],
    );
  }
}

class ClassSubjectConstraint {
  final int id;
  final int classId;
  final int subjectId;
  final int weeklyHours;
  final SchoolClass? schoolClass;
  final Subject? subject;

  ClassSubjectConstraint({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.weeklyHours,
    this.schoolClass,
    this.subject,
  });

  factory ClassSubjectConstraint.fromJson(Map<String, dynamic> json) {
    return ClassSubjectConstraint(
      id: json['id'],
      classId: json['class_id'],
      subjectId: json['subject_id'],
      weeklyHours: json['weekly_hours'],
      schoolClass: json['school_class'] != null
          ? SchoolClass.fromJson(json['school_class'])
          : null,
      subject: json['subject'] != null
          ? Subject.fromJson(json['subject'])
          : null,
    );
  }
}

class SavedTimetableSlot {
  final int id;
  final int savedTimetableId;
  final int day;
  final int hour;
  final int classId;
  final int teacherId;
  final int subjectId;
  final SchoolClass? schoolClass;
  final Teacher? teacher;
  final Subject? subject;

  SavedTimetableSlot({
    required this.id,
    required this.savedTimetableId,
    required this.day,
    required this.hour,
    required this.classId,
    required this.teacherId,
    required this.subjectId,
    this.schoolClass,
    this.teacher,
    this.subject,
  });

  factory SavedTimetableSlot.fromJson(Map<String, dynamic> json) {
    return SavedTimetableSlot(
      id: json['id'],
      savedTimetableId: json['saved_timetable_id'],
      day: json['day'],
      hour: json['hour'],
      classId: json['class_id'],
      teacherId: json['teacher_id'],
      subjectId: json['subject_id'],
      schoolClass: json['school_class'] != null
          ? SchoolClass.fromJson(json['school_class'])
          : null,
      teacher: json['teacher'] != null
          ? Teacher.fromJson(json['teacher'])
          : null,
      subject: json['subject'] != null
          ? Subject.fromJson(json['subject'])
          : null,
    );
  }
}

class SavedTimetable {
  final int id;
  final String name;
  final DateTime createdAt;
  final String? description;
  final int daysPerWeek;
  final int hoursPerDay;
  final List<SavedTimetableSlot> slots;

  SavedTimetable({
    required this.id,
    required this.name,
    required this.createdAt,
    this.description,
    required this.daysPerWeek,
    required this.hoursPerDay,
    this.slots = const [],
  });

  factory SavedTimetable.fromJson(Map<String, dynamic> json) {
    var slotList = json['slots'] as List? ?? [];
    return SavedTimetable(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      description: json['description'],
      daysPerWeek: json['days_per_week'],
      hoursPerDay: json['hours_per_day'],
      slots: slotList.map((s) => SavedTimetableSlot.fromJson(s)).toList(),
    );
  }
}
