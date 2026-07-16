import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class SubjectApi {
  static Future<List<Subject>> getSubjects() async {
    final response = await BaseClient.get('/subjects/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((s) => Subject.fromJson(s)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Subject> createSubject(String name) async {
    final response = await BaseClient.post(
      '/subjects/',
      body: {'name': name},
    );
    if (response.statusCode == 201) {
      return Subject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteSubject(int id) async {
    final response = await BaseClient.delete('/subjects/$id');
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Subject> updateSubject(int id, {int? maxConsecutiveHours}) async {
    final response = await BaseClient.put(
      '/subjects/$id',
      body: {'max_consecutive_hours': maxConsecutiveHours},
    );
    if (response.statusCode == 200) {
      return Subject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }
}

