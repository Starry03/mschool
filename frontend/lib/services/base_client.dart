import 'dart:convert';
import 'package:http/http.dart' as http;

class BaseClient {
  static String baseUrl = const String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
  static String? token;

  static Map<String, String> _getHeaders(Map<String, String>? extraHeaders) {
    final Map<String, String> hdrs = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    if (extraHeaders != null) {
      hdrs.addAll(extraHeaders);
    }
    return hdrs;
  }

  static Future<http.Response> get(String path, {Map<String, String>? headers}) async {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
    );
  }

  static Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> put(String path, {Object? body, Map<String, String>? headers}) async {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Future<http.Response> delete(String path, {Map<String, String>? headers}) async {
    return http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
    );
  }

  static String handleError(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['detail'] ?? 'Server error (${response.statusCode})';
    } catch (_) {
      return 'Unknown server error (${response.statusCode})';
    }
  }
}

