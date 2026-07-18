import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/design_system.dart';
import '../widgets/app_logo.dart';
import '../services/desktop_oauth.dart';

class LoginView extends StatefulWidget {
  final Function(User user, String token) onLoginSuccess;

  const LoginView({super.key, required this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false;
  bool _isPinging = false;
  String? _googleClientId;
  String? _googleClientIdDesktop;
  String? _googleClientIdAndroid;
  String? _googleClientIdIos;
  String? _errorMessage;
  late final TextEditingController _apiUrlController;

  @override
  void initState() {
    super.initState();
    _apiUrlController = TextEditingController(text: ApiService.baseUrl);
    _apiUrlController.addListener(() async {
      final url = _apiUrlController.text.trim();
      ApiService.baseUrl = url;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('api_base_url', url);
      } catch (_) {}
    });
    _loadAuthConfig();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final config = await ApiService.getAuthConfig();
      setState(() {
        _googleClientId = config.googleClientId;
        _googleClientIdDesktop = config.googleClientIdDesktop;
        _googleClientIdAndroid = config.googleClientIdAndroid;
        _googleClientIdIos = config.googleClientIdIos;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            "Error loading authentication config: $e\nPlease check that the backend is active.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pingServer() async {
    setState(() {
      _isPinging = true;
    });
    try {
      final res = await ApiService.testConnection();
      if (!mounted) return;
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server raggiungibile! Latenza: ${res['ping']} ms. Stato DB: ${res['database']}',
            ),
            backgroundColor: DesignSystem.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossibile connettersi: ${res['error']}'),
            backgroundColor: DesignSystem.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore imprevisto: $e'),
          backgroundColor: DesignSystem.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPinging = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final isDesktop = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS);

    if (isDesktop) {
      final desktopClientId = (_googleClientIdDesktop != null && _googleClientIdDesktop!.isNotEmpty)
          ? _googleClientIdDesktop
          : _googleClientId;

      if (desktopClientId == null || desktopClientId.isEmpty) {
        _showError("Client ID Google non configurato per Desktop.");
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final tokens = await DesktopOAuth.login(desktopClientId);
        final String? idToken = tokens['id_token'];
        final String? accessToken = tokens['access_token'];

        if ((idToken == null || idToken.isEmpty) &&
            (accessToken == null || accessToken.isEmpty)) {
          throw Exception(
            "Impossibile ottenere le credenziali da Google (ID Token o Access Token vuoto).",
          );
        }

        // Invia il token al backend per validazione e creazione sessione
        final session = await ApiService.googleLogin(
          idToken: idToken,
          accessToken: accessToken,
        );

        // Notifica il successo al widget principale
        widget.onLoginSuccess(session.user, session.accessToken);
      } catch (e) {
        setState(() {
          _errorMessage = "Login fallito: $e";
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      return;
    }

    // Web / Mobile Flow
    final mobileOrWebClientId = (defaultTargetPlatform == TargetPlatform.iOS
            ? (_googleClientIdIos != null && _googleClientIdIos!.isNotEmpty ? _googleClientIdIos : null)
            : (_googleClientIdAndroid != null && _googleClientIdAndroid!.isNotEmpty ? _googleClientIdAndroid : null)) ??
        _googleClientId;

    if (mobileOrWebClientId == null || mobileOrWebClientId.isEmpty) {
      _showError("Client ID Google non disponibile.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        clientId: mobileOrWebClientId,
        scopes: ['email', 'profile'],
      );

      // Avvia il login con Google
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // L'utente ha annullato il login
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception(
          "Impossibile ottenere le credenziali da Google (ID Token o Access Token vuoto).",
        );
      }

      // Invia il token al backend per validazione e creazione sessione
      final session = await ApiService.googleLogin(
        idToken: idToken,
        accessToken: accessToken,
      );

      // Notifica il successo al widget principale
      widget.onLoginSuccess(session.user, session.accessToken);
    } catch (e) {
      setState(() {
        _errorMessage = "Login fallito: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: DesignSystem.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final textColor = DesignSystem.getTextColor(context);
    final subtitleColor = DesignSystem.getSubtitleColor(context);
    final mutedColor = DesignSystem.getMutedColor(context);
    final fieldBgColor = DesignSystem.getFieldColor(context);
    final borderColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF020617), // very dark slate
                        const Color(0xFF0F172A), // dark slate
                        const Color(0xFF1E1B4B), // dark indigo
                      ]
                    : [
                        const Color(0xFFEEF2F6), // light grey/blue
                        const Color(0xFFE2E8F0),
                        const Color(0xFFC7D2FE), // light indigo
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Decorative glowing circles for premium look (glassmorphism feel)
          Positioned(
            top: -size.height * 0.2,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF6366F1,
                ).withOpacity(isDark ? 0.08 : 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.3,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.6,
              height: size.width * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF8B5CF6,
                ).withOpacity(isDark ? 0.06 : 0.12),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand / Logo
                    const AppLogo(),
                    const SizedBox(height: 20),
                    Text(
                      'MSchool',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: DesignSystem.getTextColor(context),
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'School Management System',
                      style: TextStyle(
                        fontSize: 14,
                        color: DesignSystem.getSubtitleColor(context),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Login Card
                    Container(
                      width: 420,
                      padding: const EdgeInsets.all(36),
                      decoration: BoxDecoration(
                        color: DesignSystem.getCardColor(context),
                        borderRadius: BorderRadius.circular(24),
                        border: DesignSystem.getBorder(context),
                        boxShadow: DesignSystem.getShadow(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Restricted Access',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DesignSystem.getTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This is a closed system. Only users enabled by the administrator can access it.',
                            style: TextStyle(
                              fontSize: 12,
                              color: DesignSystem.getMutedColor(context),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          // Backend API URL Input
                          Text(
                            'Server Backend (API)',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _apiUrlController,
                            style: TextStyle(color: textColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'http://localhost:8000/api/v1',
                              hintStyle: TextStyle(color: mutedColor),
                              filled: true,
                              fillColor: fieldBgColor,
                              prefixIcon: const Icon(
                                Icons.dns_rounded,
                                size: 18,
                                color: DesignSystem.primary,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: DesignSystem.primary,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: _isPinging ? null : _pingServer,
                                icon: _isPinging
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: DesignSystem.primary,
                                        ),
                                      )
                                    : const Icon(Icons.bolt_rounded, size: 16),
                                label: const Text('Testa Connessione'),
                                style: TextButton.styleFrom(
                                  foregroundColor: DesignSystem.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: DesignSystem.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: DesignSystem.error.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: DesignSystem.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: DesignSystem.error,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: CircularProgressIndicator(
                                  color: DesignSystem.primary,
                                ),
                              ),
                            )
                          else ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF2E334D)
                                    : Colors.white,
                                foregroundColor: DesignSystem.getTextColor(
                                  context,
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black12,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _googleClientId == null
                                  ? _loadAuthConfig
                                  : _handleGoogleSignIn,
                              icon: ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [
                                        DesignSystem.primary,
                                        DesignSystem.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ).createShader(bounds),
                                child: const FaIcon(FontAwesomeIcons.google),
                              ),
                              label: Text(
                                _googleClientId == null
                                    ? 'Riconnetti al Server'
                                    : 'Accedi con Google',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      'Open Source at https://github.com/Starry03/mschool',
                      style: TextStyle(
                        fontSize: 11,
                        color: DesignSystem.getMutedColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
