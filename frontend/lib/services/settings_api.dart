import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class SettingsApi {
  static Future<SchoolSettings> getSettings() async {
    final response = await BaseClient.get('/settings/');
    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<SchoolSettings> updateSettings(int days, int hours, {String? allowedDomain}) async {
    final response = await BaseClient.put(
      '/settings/',
      body: {
        'days_per_week': days,
        'hours_per_day': hours,
        'allowed_domain': allowedDomain,
      },
    );
    if (response.statusCode == 200) {
      return SchoolSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }
}

