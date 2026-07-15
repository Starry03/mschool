import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_client.dart';

class ClassApi {
  static Future<List<SchoolClass>> getClasses() async {
    final response = await http.get(Uri.parse('${BaseClient.baseUrl}/classes/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => SchoolClass.fromJson(c)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<SchoolClass> createClass(String name) async {
    final response = await http.post(
      Uri.parse('${BaseClient.baseUrl}/classes/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      return SchoolClass.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteClass(int id) async {
    final response = await http.delete(Uri.parse('${BaseClient.baseUrl}/classes/$id'));
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<ClassSubjectConstraint>> getClassSubjectConstraints() async {
    final response = await http.get(Uri.parse('${BaseClient.baseUrl}/class-subject-constraints/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => ClassSubjectConstraint.fromJson(c)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<ClassSubjectConstraint> createClassSubjectConstraint(int classId, int subjectId, int weeklyHours) async {
    final response = await http.post(
      Uri.parse('${BaseClient.baseUrl}/class-subject-constraints/'),
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
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteClassSubjectConstraint(int id) async {
    final response = await http.delete(Uri.parse('${BaseClient.baseUrl}/class-subject-constraints/$id'));
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }
}
