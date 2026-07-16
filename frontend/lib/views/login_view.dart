import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../theme/design_system.dart';


class LoginView extends StatefulWidget {
  final Function(User user, String token) onLoginSuccess;

  const LoginView({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLoading = false;
  String? _googleClientId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAuthConfig();
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
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Impossibile caricare la configurazione di autenticazione: $e\nVerifica che il backend sia attivo.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows)) {
      setState(() {
        _errorMessage = "Google Sign-In non è supportato nativamente su questa piattaforma desktop.\nUsa la versione Web avviando:\n\nflutter run -d chrome";
      });
      return;
    }

    if (_googleClientId == null || _googleClientId!.isEmpty) {
      _showError("Client ID di Google non caricato. Controlla la connessione al server.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientId,
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

      if ((idToken == null || idToken.isEmpty) && (accessToken == null || accessToken.isEmpty)) {
        throw Exception("Impossibile ottenere credenziali di accesso da Google (ID Token o Access Token vuoti).");
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
        _errorMessage = "Accesso fallito: $e";
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
      SnackBar(
        content: Text(message),
        backgroundColor: DesignSystem.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

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
                color: const Color(0xFF6366F1).withOpacity(isDark ? 0.08 : 0.15),
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
                color: const Color(0xFF8B5CF6).withOpacity(isDark ? 0.06 : 0.12),
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
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: DesignSystem.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: DesignSystem.primary.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
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
                      'Generatore di Orario Scolastico',
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
                            'Area Riservata',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: DesignSystem.getTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Questo è un sistema chiuso. Solo gli utenti abilitati dall\'amministratore possono effettuare l\'accesso.',
                            style: TextStyle(
                              fontSize: 12,
                              color: DesignSystem.getMutedColor(context),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),

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
                                backgroundColor: isDark ? const Color(0xFF2E334D) : Colors.white,
                                foregroundColor: DesignSystem.getTextColor(context),
                                side: BorderSide(
                                  color: isDark ? Colors.white10 : Colors.black12,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _googleClientId == null ? _loadAuthConfig : _handleGoogleSignIn,
                              icon: Image.network(
                                'https://lh3.googleusercontent.com/COxit4gJr1sICwPXS-1QdCDwc8b1th1TqIdELP48R15735QOMTRyCpaFQI4u10pCRGo83WYt-1OPq6hsIpZs=s120',
                                height: 20,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.login, color: DesignSystem.primary),
                              ),
                              label: Text(
                                _googleClientId == null
                                    ? 'Riprova a Connettere'
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
                      'Sviluppato per uso interno • Gestione Scolastica',
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
