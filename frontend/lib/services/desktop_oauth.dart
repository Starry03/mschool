import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DesktopOAuth {
  /// Starts a local HTTP loopback server, launches the browser for Google OAuth,
  /// receives the auth code, and exchanges it for tokens.
  static Future<Map<String, dynamic>> login(String clientId, {String? clientSecret}) async {
    // 1. Bind to loopback on a random free port
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final redirectUri = 'http://localhost:$port';

    try {
      // 2. Build authorization URL
      final authUrl = Uri.parse(
        'https://accounts.google.com/o/oauth2/v2/auth'
        '?client_id=$clientId'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&response_type=code'
        '&scope=email%20profile%20openid',
      );

      // 3. Launch URL in browser
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossibile aprire il browser per il login.');
      }

      // 4. Wait for the redirect request from the browser
      final request = await server.first;

      // Extract authorization code from the query parameters
      final code = request.uri.queryParameters['code'];
      final error = request.uri.queryParameters['error'];

      if (error != null) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.contentType = ContentType.html
          ..write('<h1>Errore di autenticazione: $error</h1>');
        await request.response.close();
        throw Exception('Errore di autenticazione da Google: $error');
      }

      if (code == null) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.contentType = ContentType.html
          ..write('<h1>Codice non trovato</h1>');
        await request.response.close();
        throw Exception('Codice di autorizzazione non trovato.');
      }

      // Serve success HTML page in Italian as requested by guidelines
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write('''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="utf-8">
            <title>MSchool Login</title>
            <style>
              body {
                font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                background-color: #0F172A;
                color: #FFFFFF;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                margin: 0;
              }
              .card {
                background-color: #1E2235;
                padding: 40px;
                border-radius: 20px;
                box-shadow: 0 10px 25px rgba(0,0,0,0.5);
                text-align: center;
              }
              h1 { color: #6366F1; margin-bottom: 10px; }
              p { color: #94A3B8; font-size: 16px; }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>Accesso Completato!</h1>
              <p>Puoi chiudere questa scheda e tornare all'applicazione.</p>
            </div>
          </body>
          </html>
        ''');
      await request.response.close();

      // 5. Exchange auth code for tokens
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': clientId,
          if (clientSecret != null && clientSecret.isNotEmpty) 'client_secret': clientSecret,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final Map<String, dynamic> tokenData = jsonDecode(tokenResponse.body);
        return tokenData;
      } else {
        throw Exception('Scambio del codice fallito: ${tokenResponse.body}');
      }
    } finally {
      await server.close();
    }
  }
}
