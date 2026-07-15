import 'dart:convert';
import 'package:http/http.dart' as http;

class BaseClient {
  static String baseUrl = 'http://localhost:8000/api/v1';

  static String handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['detail'] ?? 'Server error (${response.statusCode})';
    } catch (_) {
      return 'Unknown server error (${response.statusCode})';
    }
  }
}
