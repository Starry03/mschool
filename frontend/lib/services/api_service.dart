import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Can be overridden dynamically (e.g. for testing on physical devices)
  static String baseUrl = 'http://localhost:8000/api/v1';

  // Helper for parsing errors from API
  static String _handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['detail'] ?? 'Errore del server (${response.statusCode})';
    } catch (_) {
      return 'Errore sconosciuto del server (${response.statusCode})';
    }
  }

  // School Settings
  static Future<SchoolSettings> getSettings() async {
    final response = await http.get(Uri.parse('$baseUrl/settings/'));
    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<SchoolSettings> updateSettings(int days, int hours) async {
    final response = await http.put(
      Uri.parse('$baseUrl/settings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'days_per_week': days, 'hours_per_day': hours}),
    );
    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  // Teachers
  static Future<List<Teacher>> getTeachers() async {
    final response = await http.get(Uri.parse('$baseUrl/teachers/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => Teacher.fromJson(t)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Teacher> createTeacher(String firstName, String? lastName, String? email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/teachers/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
      }),
    );
    if (response.statusCode == 201) {
      return Teacher.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Teacher> updateTeacher(int id, String firstName, String? lastName, String? email) async {
    final response = await http.put(
      Uri.parse('$baseUrl/teachers/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName ?? '',
        'email': email ?? '',
      }),
    );
    if (response.statusCode == 200) {
      return Teacher.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteTeacher(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/teachers/$id'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  // Teacher Settings
  static Future<TeacherSettings> updateTeacherSettings(int teacherId, int maxConsecutive, int maxDaily, {bool preferConsecutive = false}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/teachers/$teacherId/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'max_consecutive_hours': maxConsecutive,
        'max_hours_per_day': maxDaily,
        'prefer_consecutive': preferConsecutive,
      }),
    );
    if (response.statusCode == 200) {
      return TeacherSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  // Teacher Constraints (unavailabilities)
  static Future<List<TeacherConstraint>> syncTeacherConstraints(int teacherId, List<Map<String, int>> constraints) async {
    final response = await http.put(
      Uri.parse('$baseUrl/teachers/$teacherId/constraints'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(constraints),
    );
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => TeacherConstraint.fromJson(c)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  // Classes
  static Future<List<SchoolClass>> getClasses() async {
    final response = await http.get(Uri.parse('$baseUrl/classes/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => SchoolClass.fromJson(c)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<SchoolClass> createClass(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/classes/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      return SchoolClass.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteClass(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/classes/$id'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  // Subjects
  static Future<List<Subject>> getSubjects() async {
    final response = await http.get(Uri.parse('$baseUrl/subjects/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((s) => Subject.fromJson(s)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Subject> createSubject(String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subjects/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      return Subject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteSubject(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/subjects/$id'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  static Future<Subject> updateSubject(int id, {int? maxConsecutiveHours}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/subjects/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'max_consecutive_hours': maxConsecutiveHours}),
    );
    if (response.statusCode == 200) {
      return Subject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  // Assignments
  static Future<List<Assignment>> getAssignments() async {
    final response = await http.get(Uri.parse('$baseUrl/assignments/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((a) => Assignment.fromJson(a)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<Assignment> createAssignment(int teacherId, int classId, int subjectId, int weeklyHours) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assignments/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'teacher_id': teacherId,
        'class_id': classId,
        'subject_id': subjectId,
        'weekly_hours': weeklyHours,
      }),
    );
    if (response.statusCode == 201) {
      return Assignment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteAssignment(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/assignments/$id'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  // Timetable Solver & View
  static Future<TimetableGenerateResponse> generateTimetable({double maxTimeSeconds = 10.0}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/timetable/generate?max_time_seconds=$maxTimeSeconds'),
    );
    if (response.statusCode == 200) {
      return TimetableGenerateResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<List<TimetableSlot>> getTimetable() async {
    final response = await http.get(Uri.parse('$baseUrl/timetable/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => TimetableSlot.fromJson(t)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<List<TimetableSlot>> getTimetableByClass(int classId) async {
    final response = await http.get(Uri.parse('$baseUrl/timetable/class/$classId'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => TimetableSlot.fromJson(t)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<List<TimetableSlot>> getTimetableByTeacher(int teacherId) async {
    final response = await http.get(Uri.parse('$baseUrl/timetable/teacher/$teacherId'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => TimetableSlot.fromJson(t)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> clearTimetable() async {
    final response = await http.delete(Uri.parse('$baseUrl/timetable/'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  // System Maintenance
  static Future<Map<String, dynamic>> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse('$baseUrl/system/health')).timeout(
        const Duration(seconds: 5),
      );
      stopwatch.stop();
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'success': true,
          'database': body['database'] ?? 'unknown',
          'ping': stopwatch.elapsedMilliseconds,
        };
      } else {
        return {
          'success': false,
          'error': 'Server ha risposto con codice ${response.statusCode}',
          'ping': stopwatch.elapsedMilliseconds,
        };
      }
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'ping': stopwatch.elapsedMilliseconds,
      };
    }
  }

  static Future<void> clearDatabase() async {
    final response = await http.delete(Uri.parse('$baseUrl/system/clear-db'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> clearTable(String tableName) async {
    final response = await http.delete(Uri.parse('$baseUrl/system/clear-table/$tableName'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  // Class Subject Constraints
  static Future<List<ClassSubjectConstraint>> getClassSubjectConstraints() async {
    final response = await http.get(Uri.parse('$baseUrl/class-subject-constraints/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => ClassSubjectConstraint.fromJson(c)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<ClassSubjectConstraint> createClassSubjectConstraint(int classId, int subjectId, int weeklyHours) async {
    final response = await http.post(
      Uri.parse('$baseUrl/class-subject-constraints/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'class_id': classId,
        'subject_id': subjectId,
        'weekly_hours': weeklyHours,
      }),
    );
    if (response.statusCode == 201) {
      return ClassSubjectConstraint.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteClassSubjectConstraint(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/class-subject-constraints/$id'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  // Saved Timetables
  static Future<List<SavedTimetable>> getSavedTimetables() async {
    final response = await http.get(Uri.parse('$baseUrl/saved-timetables/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => SavedTimetable.fromJson(t)).toList();
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<SavedTimetable> getSavedTimetable(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/saved-timetables/$id'));
    if (response.statusCode == 200) {
      return SavedTimetable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<SavedTimetable> saveTimetable({
    required String name,
    required String? description,
    required List<TimetableSlot> slots,
    required int daysPerWeek,
    required int hoursPerDay,
  }) async {
    final slotsJson = slots.map((s) => {
      'day': s.day,
      'hour': s.hour,
      'class_id': s.classId,
      'teacher_id': s.teacherId,
      'subject_id': s.subjectId,
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/saved-timetables/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'days_per_week': daysPerWeek,
        'hours_per_day': hoursPerDay,
        'slots': slotsJson,
      }),
    );
    if (response.statusCode == 201) {
      return SavedTimetable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> deleteSavedTimetable(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/saved-timetables/$id'));
    if (response.statusCode != 204) {
      throw Exception(_handleError(response));
    }
  }

  static Future<void> restoreSavedTimetable(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/saved-timetables/$id/restore'));
    if (response.statusCode != 200) {
      throw Exception(_handleError(response));
    }
  }
}
