import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class TeacherApi {
  static Future<List<Teacher>> getTeachers() async {
    final response = await BaseClient.get('/teachers/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => Teacher.fromJson(t)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Teacher> createTeacher(String firstName, String? lastName, String? email) async {
    final response = await BaseClient.post(
      '/teachers/',
      body: {
        'first_name': firstName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    if (response.statusCode == 201) {
      return Teacher.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Teacher> updateTeacher(int id, String firstName, String? lastName, String? email) async {
    final response = await BaseClient.put(
      '/teachers/$id',
      body: {
        'first_name': firstName,
        'last_name': lastName ?? '',
        'email': email ?? '',
      },
    );
    if (response.statusCode == 200) {
      return Teacher.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteTeacher(int id) async {
    final response = await BaseClient.delete('/teachers/$id');
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<TeacherSettings> updateTeacherSettings(int teacherId, int maxConsecutive, int maxDaily, {bool preferConsecutive = false}) async {
    final response = await BaseClient.put(
      '/teachers/$teacherId/settings',
      body: {
        'max_consecutive_hours': maxConsecutive,
        'max_hours_per_day': maxDaily,
        'prefer_consecutive': preferConsecutive,
      },
    );
    if (response.statusCode == 200) {
      return TeacherSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<TeacherConstraint>> syncTeacherConstraints(int teacherId, List<Map<String, int>> constraints) async {
    final response = await BaseClient.put(
      '/teachers/$teacherId/constraints',
      body: constraints,
    );
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => TeacherConstraint.fromJson(c)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }
}

