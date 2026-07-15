import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'base_client.dart';

class SettingsApi {
  static Future<SchoolSettings> getSettings() async {
    final response = await http.get(Uri.parse('${BaseClient.baseUrl}/settings/'));
    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<SchoolSettings> updateSettings(int days, int hours) async {
    final response = await http.put(
      Uri.parse('${BaseClient.baseUrl}/settings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'days_per_week': days, 'hours_per_day': hours}),
    );
    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }
}
