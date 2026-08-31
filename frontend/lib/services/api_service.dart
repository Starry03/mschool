import '../models/models.dart';
import 'base_client.dart';
import 'settings_api.dart';
import 'teacher_api.dart';
import 'class_api.dart';
import 'subject_api.dart';
import 'assignment_api.dart';
import 'timetable_api.dart';
import 'system_api.dart';
import 'auth_api.dart';
import 'user_api.dart';

class ApiService {
  static String get baseUrl => BaseClient.baseUrl;
  static set baseUrl(String value) => BaseClient.baseUrl = value;

  static String? get token => BaseClient.token;
  static set token(String? value) => BaseClient.token = value;

  // Authentication
  static Future<AuthConfigResponse> getAuthConfig() => AuthApi.getAuthConfig();
  static Future<UserSession> googleLogin({String? idToken, String? accessToken}) =>
      AuthApi.googleLogin(idToken: idToken, accessToken: accessToken);
  static Future<void> logout() => AuthApi.logout();

  // User Management
  static Future<List<User>> getUsers() => UserApi.getUsers();
  static Future<User> createUser(String firstName, String lastName, String email, String role) =>
      UserApi.createUser(firstName, lastName, email, role);
  static Future<User> deleteUser(int id) => UserApi.deleteUser(id);

  // School Settings
  static Future<SchoolSettings> getSettings() => SettingsApi.getSettings();
  static Future<SchoolSettings> updateSettings(int days, int hours, {String? allowedDomain}) =>
      SettingsApi.updateSettings(days, hours, allowedDomain: allowedDomain);


  // Teachers
  static Future<List<Teacher>> getTeachers() => TeacherApi.getTeachers();
  static Future<Teacher> createTeacher(String firstName, String? lastName, String? email) =>
      TeacherApi.createTeacher(firstName, lastName, email);
  static Future<Teacher> updateTeacher(int id, String firstName, String? lastName, String? email) =>
      TeacherApi.updateTeacher(id, firstName, lastName, email);
  static Future<void> deleteTeacher(int id) => TeacherApi.deleteTeacher(id);

  // Teacher Settings
  static Future<TeacherSettings> updateTeacherSettings(int teacherId, int maxConsecutive, int maxDaily, {bool preferConsecutive = false}) =>
      TeacherApi.updateTeacherSettings(teacherId, maxConsecutive, maxDaily, preferConsecutive: preferConsecutive);

  // Teacher Constraints
  static Future<List<TeacherConstraint>> syncTeacherConstraints(int teacherId, List<Map<String, int>> constraints) =>
      TeacherApi.syncTeacherConstraints(teacherId, constraints);

  // Classes
  static Future<List<SchoolClass>> getClasses() => ClassApi.getClasses();
  static Future<SchoolClass> createClass(String name) => ClassApi.createClass(name);
  static Future<void> deleteClass(int id) => ClassApi.deleteClass(id);

  // Class Subject Constraints
  static Future<List<ClassSubjectConstraint>> getClassSubjectConstraints() =>
      ClassApi.getClassSubjectConstraints();
  static Future<ClassSubjectConstraint> createClassSubjectConstraint(int classId, int subjectId, int weeklyHours) =>
      ClassApi.createClassSubjectConstraint(classId, subjectId, weeklyHours);
  static Future<void> deleteClassSubjectConstraint(int id) =>
      ClassApi.deleteClassSubjectConstraint(id);

  // Subjects
  static Future<List<Subject>> getSubjects() => SubjectApi.getSubjects();
  static Future<Subject> createSubject(String name) => SubjectApi.createSubject(name);
  static Future<void> deleteSubject(int id) => SubjectApi.deleteSubject(id);
  static Future<Subject> updateSubject(
    int id, {
    int? maxConsecutiveHours,
    int? maxHoursPerDay,
  }) =>
      SubjectApi.updateSubject(
        id,
        maxConsecutiveHours: maxConsecutiveHours,
        maxHoursPerDay: maxHoursPerDay,
      );

  // Assignments
  static Future<List<Assignment>> getAssignments() => AssignmentApi.getAssignments();
  static Future<Assignment> createAssignment(int teacherId, int classId, int subjectId, int weeklyHours) =>
      AssignmentApi.createAssignment(teacherId, classId, subjectId, weeklyHours);
  static Future<void> deleteAssignment(int id) => AssignmentApi.deleteAssignment(id);

  // Timetable Solver & View
  static Future<TimetableGenerateResponse> generateTimetable({double maxTimeSeconds = 10.0}) =>
      TimetableApi.generateTimetable(maxTimeSeconds: maxTimeSeconds);
  static Future<List<TimetableSlot>> getTimetable() => TimetableApi.getTimetable();
  static Future<List<TimetableSlot>> getTimetableByClass(int classId) =>
      TimetableApi.getTimetableByClass(classId);
  static Future<List<TimetableSlot>> getTimetableByTeacher(int teacherId) =>
      TimetableApi.getTimetableByTeacher(teacherId);
  static Future<void> clearTimetable() => TimetableApi.clearTimetable();

  // Saved Timetables
  static Future<List<SavedTimetable>> getSavedTimetables() => TimetableApi.getSavedTimetables();
  static Future<SavedTimetable> getSavedTimetable(int id) => TimetableApi.getSavedTimetable(id);
  static Future<SavedTimetable> saveTimetable({
    required String name,
    required String? description,
    required List<TimetableSlot> slots,
    required int daysPerWeek,
    required int hoursPerDay,
  }) =>
      TimetableApi.saveTimetable(
        name: name,
        description: description,
        slots: slots,
        daysPerWeek: daysPerWeek,
        hoursPerDay: hoursPerDay,
      );
  static Future<void> deleteSavedTimetable(int id) => TimetableApi.deleteSavedTimetable(id);
  static Future<void> restoreSavedTimetable(int id) => TimetableApi.restoreSavedTimetable(id);

  // System Maintenance
  static Future<Map<String, dynamic>> testConnection() => SystemApi.testConnection();
  static Future<Map<String, dynamic>> getBackendVersion() => SystemApi.getVersion();
  static Future<void> clearDatabase() => SystemApi.clearDatabase();
  static Future<void> clearTable(String tableName) => SystemApi.clearTable(tableName);
}
