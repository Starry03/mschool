import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_client.dart';

class TeacherApi {
  static Future<List<Teacher>> getTeachers() async {
    final response = await http.get(Uri.parse('${BaseClient.baseUrl}/teachers/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((t) => Teacher.fromJson(t)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Teacher> createTeacher(String firstName, String? lastName, String? email) async {
    final response = await http.post(
      Uri.parse('${BaseClient.baseUrl}/teachers/'),
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
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Teacher> updateTeacher(int id, String firstName, String? lastName, String? email) async {
    final response = await http.put(
      Uri.parse('${BaseClient.baseUrl}/teachers/$id'),
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
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteTeacher(int id) async {
    final response = await http.delete(Uri.parse('${BaseClient.baseUrl}/teachers/$id'));
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<TeacherSettings> updateTeacherSettings(int teacherId, int maxConsecutive, int maxDaily, {bool preferConsecutive = false}) async {
    final response = await http.put(
      Uri.parse('${BaseClient.baseUrl}/teachers/$teacherId/settings'),
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
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<TeacherConstraint>> syncTeacherConstraints(int teacherId, List<Map<String, int>> constraints) async {
    final response = await http.put(
      Uri.parse('${BaseClient.baseUrl}/teachers/$teacherId/constraints'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(constraints),
    );
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => TeacherConstraint.fromJson(c)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }
}
