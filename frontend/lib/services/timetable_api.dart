import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class TimetableApi {
  static Future<TimetableGenerateResponse> generateTimetable({double maxTimeSeconds = 10.0}) async {
    final response = await BaseClient.post('/timetable/generate?max_time_seconds=$maxTimeSeconds');
    if (response.statusCode == 200) {
      return TimetableGenerateResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<TimetableSlot>> getTimetable() async {
    final response = await BaseClient.get('/timetable/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => TimetableSlot.fromJson(t)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<TimetableSlot>> getTimetableByClass(int classId) async {
    final response = await BaseClient.get('/timetable/class/$classId');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => TimetableSlot.fromJson(t)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<TimetableSlot>> getTimetableByTeacher(int teacherId) async {
    final response = await BaseClient.get('/timetable/teacher/$teacherId');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => TimetableSlot.fromJson(t)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> clearTimetable() async {
    final response = await BaseClient.delete('/timetable/');
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<SavedTimetable>> getSavedTimetables() async {
    final response = await BaseClient.get('/saved-timetables/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => SavedTimetable.fromJson(t)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<SavedTimetable> getSavedTimetable(int id) async {
    final response = await BaseClient.get('/saved-timetables/$id');
    if (response.statusCode == 200) {
      return SavedTimetable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
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

    final response = await BaseClient.post(
      '/saved-timetables/',
      body: {
        'name': name,
        'description': description,
        'days_per_week': daysPerWeek,
        'hours_per_day': hoursPerDay,
        'slots': slotsJson,
      },
    );
    if (response.statusCode == 201) {
      return SavedTimetable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteSavedTimetable(int id) async {
    final response = await BaseClient.delete('/saved-timetables/$id');
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> restoreSavedTimetable(int id) async {
    final response = await BaseClient.post('/saved-timetables/$id/restore');
    if (response.statusCode != 200) {
      throw Exception(BaseClient.handleError(response));
    }
  }
}

