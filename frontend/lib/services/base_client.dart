import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class BaseClient {
  static String baseUrl = _initBaseUrl();

  static String _initBaseUrl() {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin != 'null') {
          return '$origin/api/v1';
        }
      } catch (_) {}
    }
    return 'http://localhost:8000/api/v1';
  }
  static String? token;
  static void Function()? onSessionExpired;

  static void _checkResponse(String path, http.Response response) {
    if (response.statusCode == 401 && path != '/auth/google-login' && token != null) {
      onSessionExpired?.call();
    }
  }

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
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
    );
    _checkResponse(path, response);
    return response;
  }

  static Future<http.Response> post(String path, {Object? body, Map<String, String>? headers}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(path, response);
    return response;
  }

  static Future<http.Response> put(String path, {Object? body, Map<String, String>? headers}) async {
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    _checkResponse(path, response);
    return response;
  }

  static Future<http.Response> delete(String path, {Map<String, String>? headers}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: _getHeaders(headers),
    );
    _checkResponse(path, response);
    return response;
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

