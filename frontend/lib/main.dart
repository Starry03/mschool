import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'services/base_client.dart';
import 'views/dashboard_view.dart';
import 'views/teachers_view.dart';
import 'views/data_management_view.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'views/assignments_view.dart';
import 'views/login_view.dart';
import 'widgets/app_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? _currentUser;
  String? _token;
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();
    BaseClient.onSessionExpired = _handleSessionExpired;
    _loadPersistedSession();
  }

  @override
  void dispose() {
    BaseClient.onSessionExpired = null;
    super.dispose();
  }

  void _logoutLocal() {
    setState(() {
      _currentUser = null;
      _token = null;
      ApiService.token = null;
    });
    _clearSession();
  }

  void _handleSessionExpired() {
    _logoutLocal();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sessione scaduta o non valida. Effettua nuovamente l\'accesso.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedBaseUrl = prefs.getString('api_base_url');
      if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
        ApiService.baseUrl = savedBaseUrl;
      }

      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('current_user');

      if (savedToken != null && savedUserJson != null) {
        final Map<String, dynamic> userMap = jsonDecode(savedUserJson);
        setState(() {
          _token = savedToken;
          _currentUser = User.fromJson(userMap);
          ApiService.token = savedToken;
        });
      }
    } catch (e) {
      debugPrint('Error loading persisted session: $e');
    } finally {
      setState(() {
        _isLoadingSession = false;
      });
    }
  }

  Future<void> _saveSession(User user, String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('current_user', jsonEncode(user.toJson()));
      await prefs.setString('api_base_url', ApiService.baseUrl);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('current_user');
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MSchool',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Outfit',
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1E2235),
        ),
      ),
      home: _isLoadingSession
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6366F1),
                ),
              ),
            )
          : _token == null
              ? LoginView(
                  onLoginSuccess: (user, token) {
                    setState(() {
                      _currentUser = user;
                      _token = token;
                      ApiService.token = token;
                    });
                    _saveSession(user, token);
                  },
                )
              : MainShell(
                  currentUser: _currentUser!,
                  onLogout: _logoutLocal,
                ),
    );
  }
}

class MainShell extends StatefulWidget {
  final User currentUser;
  final VoidCallback onLogout;

  const MainShell({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  SchoolSettings? _schoolSettings;
  bool _isLoadingSettings = true;
  String _appVersion = 'v1.0.0';
  String _appVersion = 'v1.0.2';

  // Settings controllers
  final _daysController = TextEditingController();
  final _hoursController = TextEditingController();
  final _allowedDomainController = TextEditingController();

  // User Management
  final _userFirstNameController = TextEditingController();
  final _userLastNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  String _userSelectedRole = 'user';
  List<User> _usersList = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version}';
      });
    } catch (_) {
      setState(() {
        _appVersion = 'v1.0.0';
        _appVersion = 'v1.0.2';
      });
    }
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoadingSettings = true);
    try {
      final settings = await ApiService.getSettings();
      setState(() {
        _schoolSettings = settings;
        _daysController.text = settings.daysPerWeek.toString();
        _hoursController.text = settings.hoursPerDay.toString();
        _allowedDomainController.text = settings.allowedDomain ?? '';
      });
      if (widget.currentUser.isAdmin) {
        _loadUsers();
      }
    } catch (e) {
      _showError('Errore nel caricamento delle impostazioni: $e');
    } finally {
      setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _saveSettings() async {
    final days = int.tryParse(_daysController.text) ?? 5;
    final hours = int.tryParse(_hoursController.text) ?? 6;
    final allowedDomain = _allowedDomainController.text.trim();

    if (days < 1 || days > 6 || hours < 1 || hours > 8) {
      _showError('Impostazioni non valide: max 6 giorni e max 8 ore.');
      return;
    }

    setState(() => _isLoadingSettings = true);
    try {
      final settings = await ApiService.updateSettings(
        days,
        hours,
        allowedDomain: allowedDomain.isNotEmpty ? allowedDomain : null,
      );
      setState(() {
        _schoolSettings = settings;
      });
      _showSuccess('Impostazioni salvate con successo!');
    } catch (e) {
      _showError('Impossibile salvare le impostazioni: $e');
    } finally {
      setState(() => _isLoadingSettings = false);
    }
  }

  Future<void> _loadUsers() async {
    if (!widget.currentUser.isAdmin) return;
    setState(() => _isLoadingUsers = true);
    try {
      final list = await ApiService.getUsers();
      setState(() {
        _usersList = list;
      });
    } catch (e) {
      _showError('Impossibile caricare la lista utenti: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createUser() async {
    final fName = _userFirstNameController.text.trim();
    final lName = _userLastNameController.text.trim();
    final email = _userEmailController.text.trim().toLowerCase();
    final role = _userSelectedRole;

    if (fName.isEmpty || lName.isEmpty || email.isEmpty) {
      _showError('Tutti i campi dell\'utente sono obbligatori.');
      return;
    }

    setState(() => _isLoadingUsers = true);
    try {
      await ApiService.createUser(fName, lName, email, role);
      _userFirstNameController.clear();
      _userLastNameController.clear();
      _userEmailController.clear();
      _showSuccess('Utente creato con successo!');
      _loadUsers();
    } catch (e) {
      _showError('Errore nella creazione dell\'utente: $e');
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text(
          'Rimuovi Utente',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sei sicuro di voler rimuovere l\'utente ${user.firstName} ${user.lastName} (${user.email})?\n\nQuesta azione revocherà immediatamente il suo accesso.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Rimuovi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoadingUsers = true);
      try {
        await ApiService.deleteUser(user.id);
        _showSuccess('Utente rimosso con successo!');
        _loadUsers();
      } catch (e) {
        _showError('Errore nella rimozione dell\'utente: $e');
      } finally {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  bool _isTestingConnection = false;
  Map<String, dynamic>? _connectionResult;

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
    });
    try {
      final result = await ApiService.testConnection();

      setState(() {
        _connectionResult = result;
      });
    } catch (e) {
      setState(() {
        _connectionResult = {
          'success': false,
          'error': e.toString(),
          'ping': 0,
        };
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _clearEntireDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: const Text(
          'WARNING: Clear Entire Database',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'This action will clear ALL existing data: teachers, constraints, classes, subjects, chairs, and timetables.\n\nThis action is irreversible. Do you want to proceed?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'CLEAR ALL',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoadingSettings = true);
      try {
        await ApiService.clearDatabase();
        _showSuccess('Entire database cleared successfully!');
        _loadSettings();
      } catch (e) {
        _showError('Error while clearing database: $e');
      } finally {
        setState(() => _isLoadingSettings = false);
      }
    }
  }

  Future<void> _clearTable(
    String tableName,
    String displayName,
    String warningDetails,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        title: Text(
          'WARNING: Clear $displayName',
          style: const TextStyle(
            color: Colors.orangeAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You are about to delete all elements in $displayName.\n\n$warningDetails\n\nDo you want to proceed?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Proceed',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoadingSettings = true);
      try {
        await ApiService.clearTable(tableName);
        _showSuccess('Table $displayName cleared successfully!');
        _loadSettings();
      } catch (e) {
        _showError('Error while clearing $displayName: $e');
      } finally {
        setState(() => _isLoadingSettings = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSettings && _schoolSettings == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    final currentSettings =
        _schoolSettings ??
        SchoolSettings(id: 1, daysPerWeek: 5, hoursPerDay: 6);

    // List of navigation items
    final List<Map<String, dynamic>> navItems = [
      {'title': 'Timetable & Dashboard', 'icon': Icons.grid_on_outlined},
      {'title': 'Teachers & Constraints', 'icon': Icons.people_outline},
      {'title': 'Classes & Subjects', 'icon': Icons.room_preferences_outlined},
      {'title': 'Chair Assignments', 'icon': Icons.assignment_ind_outlined},
      if (widget.currentUser.isAdmin)
        {'title': 'Admin', 'icon': Icons.settings_outlined},
    ];

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 900;

    return Scaffold(
      appBar: isSmallScreen
          ? AppBar(
              title: Text(
                navItems[_selectedIndex]['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
              ),
            )
          : null,
      drawer: isSmallScreen
          ? Drawer(child: _buildSidebar(navItems, isDrawer: true))
          : null,
      body: Stack(
        children: [
          // Background Gradient decoration
          _buildBackgroundGradient(),

          Row(
            children: [
              // Sidebar Navigation
              if (!isSmallScreen) RepaintBoundary(child: _buildSidebar(navItems)),

              // Main content container with fade transition
              Expanded(
                child: RepaintBoundary(
                  child: _buildSelectedView(currentSettings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedView(SchoolSettings currentSettings) {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          key: const ValueKey('dashboard'),
          schoolSettings: currentSettings,
        );
      case 1:
        return TeachersView(
          key: const ValueKey('teachers'),
          schoolSettings: currentSettings,
        );
      case 2:
        return const DataManagementView(key: ValueKey('data_mgmt'));
      case 3:
        return const AssignmentsView(key: ValueKey('assignments'));
      case 4:
        return _buildSettingsView();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBackgroundGradient() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF020617), // very dark slate
                    const Color(0xFF0F172A), // dark slate
                    const Color(0xFF1E1B4B), // dark indigo tint
                  ]
                : [
                    const Color(0xFFF8FAFC), // light slate
                    const Color(0xFFF1F5F9), // light grey/blue
                    const Color(0xFFE2E8F0), // light grey border tint
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(
    List<Map<String, dynamic>> items, {
    bool isDrawer = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B0F19).withOpacity(0.5) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App Logo / Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Row(
              children: [
                const AppLogo(
                  size: 28,
                  borderRadius: 12,
                  padding: 8,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MSchool',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _appVersion,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: isDark ? Colors.white10 : Colors.black12,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 24),

          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        if (isDrawer) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(
                                  0xFF6366F1,
                                ).withOpacity(isDark ? 0.12 : 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(
                                    0xFF6366F1,
                                  ).withOpacity(isDark ? 0.2 : 0.15)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : (isDark ? Colors.white60 : Colors.black54),
                              size: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['title'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF6366F1))
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF6366F1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout Button
          Divider(
            color: isDark ? Colors.white10 : Colors.black12,
            height: 1,
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: InkWell(
              onTap: () async {
                try {
                  await ApiService.logout();
                } catch (_) {}
                widget.onLogout();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_outlined,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

  Widget _buildSettingsView() {
    final pingResult = _connectionResult;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    // Theme-aware styles
    final cardColor = isDark
        ? const Color(0xFF1E2235).withOpacity(0.8)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;
    final fieldBgColor = isDark
        ? const Color(0xFF2E334D).withOpacity(0.4)
        : const Color(0xFFF1F5F9);

    final Widget globalSettingsCard = Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.settings, color: Color(0xFF6366F1), size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Global Settings',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Configure the basic school structure and server endpoint.',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 28),

          // Days per week
          Text(
            'Weekly working days (max 6)',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'e.g., 5',
              hintStyle: TextStyle(color: mutedColor),
              filled: true,
              fillColor: fieldBgColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hours per day
          Text(
            'Daily school hours (max 8)',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _hoursController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'e.g., 6',
              hintStyle: TextStyle(color: mutedColor),
              filled: true,
              fillColor: fieldBgColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dominio Email Abilitato
          Text(
            'Dominio Email Consentito (es. school.it)',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _allowedDomainController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Nessuno (solo utenti registrati)',
              hintStyle: TextStyle(color: mutedColor),
              filled: true,
              fillColor: fieldBgColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6366F1),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _saveSettings,
            child: const Text(
              'Salva Impostazioni',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    final Widget diagnosticsCard = Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                color: Colors.teal,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Diagnostics & Connection',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.withOpacity(isDark ? 0.2 : 0.1),
              foregroundColor: isDark
                  ? Colors.tealAccent
                  : Colors.teal.shade700,
              side: BorderSide(
                color: isDark ? Colors.teal : Colors.teal.shade300,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isTestingConnection ? null : _testConnection,
            icon: _isTestingConnection
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: isDark ? Colors.tealAccent : Colors.teal.shade700,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.wifi_tethering),
            label: const Text(
              'Verify Backend Connection',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          if (pingResult != null) ...[
            const SizedBox(height: 20),
            _buildPingResultWidget(pingResult),
          ],
        ],
      ),
    );

    final Widget userManagementCard = Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                color: Color(0xFF6366F1),
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'User Management',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enable or disable users with access control.',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 24),

          // FORM
          Text(
            'Create New User',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userFirstNameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Nome',
                    hintStyle: TextStyle(color: mutedColor),
                    filled: true,
                    fillColor: fieldBgColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _userLastNameController,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Surname',
                    hintStyle: TextStyle(color: mutedColor),
                    filled: true,
                    fillColor: fieldBgColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _userEmailController,
                  style: TextStyle(color: textColor),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email (eg. prof@school.it)',
                    hintStyle: TextStyle(color: mutedColor),
                    filled: true,
                    fillColor: fieldBgColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6366F1),
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: fieldBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _userSelectedRole,
                    dropdownColor: isDark
                        ? const Color(0xFF1E2235)
                        : Colors.white,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _userSelectedRole = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _createUser,
            icon: const Icon(Icons.add_moderator),
            label: const Text(
              'Create User',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 16),

          Text(
            'Enabled Users (${_usersList.length})',
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            )
          else if (_usersList.isEmpty)
            Text(
              'No user registered.',
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _usersList.length,
                itemBuilder: (context, index) {
                  final user = _usersList[index];
                  final isSelf = user.id == widget.currentUser.id;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: fieldBgColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${user.firstName} ${user.lastName}',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: mutedColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: user.isAdmin
                                ? const Color(0xFF8B5CF6).withOpacity(0.15)
                                : const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: TextStyle(
                              color: user.isAdmin
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: isSelf ? null : () => _deleteUser(user),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );

    final Widget databaseMaintenanceCard = Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.storage_outlined,
                color: Colors.orangeAccent,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Database Maintenance',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Useful tools (to make a mess)',
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
          const SizedBox(height: 28),

          // ALERT WARNING BAR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.report_problem,
                  color: Colors.redAccent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Hope I will not need this',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Full Clean Database Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.15),
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _clearEntireDatabase,
            icon: const Icon(Icons.delete_forever),
            label: const Text(
              'CLEAR ENTIRE DATABASE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),

          const SizedBox(height: 20),
          Divider(color: isDark ? Colors.white12 : Colors.black12),
          const SizedBox(height: 16),

          Text(
            'Clear Individual Tables',
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Teachers
          _buildTableCleanRow(
            title: 'Teachers',
            tableName: 'teachers',
            description:
                'Delete teachers, availability settings, and related chairs.',
            warning:
                'This will permanently remove ALL teachers, their preferences, unavailability schedules, assigned chairs, and the generated school timetable.',
          ),

          // Classes
          _buildTableCleanRow(
            title: 'Classes',
            tableName: 'classes',
            description: 'Delete classes and related chairs.',
            warning:
                'This will permanently remove all entered classes, all connected chair assignments, and the generated school timetable.',
          ),

          // Subjects
          _buildTableCleanRow(
            title: 'Subjects',
            tableName: 'subjects',
            description: 'Delete subjects and related chairs.',
            warning:
                'This will permanently remove all teaching subjects, connected chair assignments, and the generated school timetable.',
          ),

          // Assignments
          _buildTableCleanRow(
            title: 'Chairs / Assignments',
            tableName: 'assignments',
            description: 'Remove teacher-class associations.',
            warning:
                'This will permanently remove all assigned chairs and delete the generated timetable.',
          ),

          // Timetable
          _buildTableCleanRow(
            title: 'School Timetable',
            tableName: 'timetable',
            description: 'Delete the generated timetable.',
            warning:
                'This will only remove the generated timetable. Teachers, classes, subjects, and chair assignments will remain intact.',
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Configuration & Connection Test
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          globalSettingsCard,
                          const SizedBox(height: 24),
                          diagnosticsCard,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right Column: Database Maintenance Tools & User Management
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          userManagementCard,
                          const SizedBox(height: 24),
                          databaseMaintenanceCard,
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    globalSettingsCard,
                    const SizedBox(height: 24),
                    diagnosticsCard,
                    const SizedBox(height: 24),
                    userManagementCard,
                    const SizedBox(height: 24),
                    databaseMaintenanceCard,
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPingResultWidget(Map<String, dynamic> result) {
    final success = result['success'] as bool;
    final ping = result['ping'] as int;
    final version = result['version'] as String?;
    final dbStatus = result['database'] as String?;
    final error = result['error'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success
            ? Colors.teal.withOpacity(0.08)
            : Colors.redAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: success
              ? Colors.teal.withOpacity(0.3)
              : Colors.redAccent.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success
                    ? (isDark ? Colors.tealAccent : Colors.teal.shade700)
                    : Colors.redAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                success ? 'Backend Available!' : 'Connection Failed',
                style: TextStyle(
                  color: success
                      ? (isDark ? Colors.tealAccent : Colors.teal.shade700)
                      : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (success) ...[
            Text(
              '• Server Version: ${version ?? "unknown"}',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• Database: $dbStatus',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '• Latency (Ping): ${ping}ms',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13,
              ),
            ),
          ] else ...[
            Text(
              error ?? 'Unknown connection error.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableCleanRow({
    required String title,
    required String tableName,
    required String description,
    required String warning,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.white38 : Colors.black38;
    final fieldBgColor = isDark
        ? const Color(0xFF2E334D).withOpacity(0.2)
        : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.04);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: mutedColor, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withOpacity(0.15),
              foregroundColor: Colors.orangeAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => _clearTable(tableName, title, warning),
            child: const Text(
              'Clear',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
