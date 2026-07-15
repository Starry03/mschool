import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_client.dart';

class SystemApi {
  static Future<Map<String, dynamic>> testConnection() async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(Uri.parse('${BaseClient.baseUrl}/system/health')).timeout(
        const Duration(seconds: 5),
      );
      stopwatch.stop();
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return {
          'success': true,
          'database': body['database'] ?? 'unknown',
          'ping': stopwatch.elapsedMilliseconds,
        };
      } else {
        return {
          'success': false,
          'error': 'Server responded with code ${response.statusCode}',
          'ping': stopwatch.elapsedMilliseconds,
        };
      }
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'error': e.toString(),
        'ping': stopwatch.elapsedMilliseconds,
      };
    }
  }

  static Future<void> clearDatabase() async {
    final response = await http.delete(Uri.parse('${BaseClient.baseUrl}/system/clear-db'));
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> clearTable(String tableName) async {
    final response = await http.delete(Uri.parse('${BaseClient.baseUrl}/system/clear-table/$tableName'));
    if (response.statusCode != 204) {
      throw Exception(BaseClient.handleError(response));
    }
  }
}
