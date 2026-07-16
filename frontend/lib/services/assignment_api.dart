import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class AssignmentApi {
  static Future<List<Assignment>> getAssignments() async {
    final response = await BaseClient.get('/assignments/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((a) => Assignment.fromJson(a)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Assignment> createAssignment(int teacherId, int classId, int subjectId, int weeklyHours) async {
    final response = await BaseClient.post(
      '/assignments/',
      body: {
        'teacher_id': teacherId,
        'class_id': classId,
        'subject_id': subjectId,
        'weekly_hours': weeklyHours,
      },
    );
    if (response.statusCode == 201) {
      return Assignment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteAssignment(int id) async {
    final response = await BaseClient.delete('/assignments/$id');
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }
}

