import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_client.dart';

class SubjectApi {
  static Future<List<Subject>> getSubjects() async {
    final response = await http.get(Uri.parse('${BaseClient.baseUrl}/subjects/'));
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((s) => Subject.fromJson(s)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Subject> createSubject(String name) async {
    final response = await http.post(
      Uri.parse('${BaseClient.baseUrl}/subjects/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode == 201) {
      return Subject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> deleteSubject(int id) async {
    final response = await http.delete(Uri.parse('${BaseClient.baseUrl}/subjects/$id'));
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<Subject> updateSubject(int id, {int? maxConsecutiveHours}) async {
    final response = await http.put(
      Uri.parse('${BaseClient.baseUrl}/subjects/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'max_consecutive_hours': maxConsecutiveHours}),
    );
    if (response.statusCode == 200) {
      return Subject.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }
}
