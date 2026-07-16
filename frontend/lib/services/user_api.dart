import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class UserApi {
  static Future<List<User>> getUsers() async {
    final response = await BaseClient.get('/users/');
    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(response.body);
      return list.map((u) => User.fromJson(u)).toList();
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<User> createUser(String firstName, String lastName, String email, String role) async {
    final response = await BaseClient.post(
      '/users/',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'role': role,
      },
    );
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<User> deleteUser(int id) async {
    final response = await BaseClient.delete('/users/$id');
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }
}
