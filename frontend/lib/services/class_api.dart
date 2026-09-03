import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class ClassApi {
  static Future<List<SchoolClass>> getClasses() async {
    final response = await BaseClient.get('/classes/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => SchoolClass.fromJson(c)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<SchoolClass> createClass(String name) async {
    final response = await BaseClient.post(
      '/classes/',
      body: {'name': name},
    );
    if (response.statusCode == 201) {
      return SchoolClass.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteClass(int id) async {
    final response = await BaseClient.delete('/classes/$id');
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<SchoolClass> updateClass(int id, String name) async {
    final response = await BaseClient.put(
      '/classes/$id',
      body: {'name': name},
    );
    if (response.statusCode == 200) {
      return SchoolClass.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<List<ClassSubjectConstraint>> getClassSubjectConstraints() async {
    final response = await BaseClient.get('/class-subject-constraints/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((c) => ClassSubjectConstraint.fromJson(c)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<ClassSubjectConstraint> createClassSubjectConstraint(int classId, int subjectId, int weeklyHours) async {
    final response = await BaseClient.post(
      '/class-subject-constraints/',
      body: {
        'class_id': classId,
        'subject_id': subjectId,
        'weekly_hours': weeklyHours,
      },
    );
    if (response.statusCode == 201) {
      return ClassSubjectConstraint.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteClassSubjectConstraint(int id) async {
    final response = await BaseClient.delete('/class-subject-constraints/$id');
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }
}

