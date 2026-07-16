import 'dart:convert';
import '../models/models.dart';
import 'base_client.dart';

class AuthConfigResponse {
  final String googleClientId;

  AuthConfigResponse({required this.googleClientId});

  factory AuthConfigResponse.fromJson(Map<String, dynamic> json) {
    return AuthConfigResponse(
      googleClientId: json['google_client_id'] ?? '',
    );
  }
}

class UserSession {
  final String accessToken;
  final String tokenType;
  final User user;

  UserSession({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: User.fromJson(json['user']),
    );
  }
}

class AuthApi {
  static Future<AuthConfigResponse> getAuthConfig() async {
    final response = await BaseClient.get('/auth/config');
    if (response.statusCode == 200) {
      return AuthConfigResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<UserSession> googleLogin({String? idToken, String? accessToken}) async {
    final response = await BaseClient.post(
      '/auth/google-login',
      body: {
        'id_token': ?idToken,
        'access_token': ?accessToken,
      },
    );
    if (response.statusCode == 200) {
      return UserSession.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(BaseClient.handleError(response));
    }
  }

  static Future<void> logout() async {
    final response = await BaseClient.post('/auth/logout');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(BaseClient.handleError(response));
    }
  }
}
