import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/version.dart';
import 'system_api.dart';

class UpdateStatus {
  final String currentClientVersion;
  final String? currentServerVersion;
  final String latestReleaseVersion;
  final String? releaseUrl;
  final String? releaseNotes;
  final bool clientNeedsUpdate;
  final bool serverNeedsUpdate;

  const UpdateStatus({
    required this.currentClientVersion,
    required this.currentServerVersion,
    required this.latestReleaseVersion,
    required this.clientNeedsUpdate,
    required this.serverNeedsUpdate,
    this.releaseUrl,
    this.releaseNotes,
  });

  bool get hasUpdate => clientNeedsUpdate || serverNeedsUpdate;
  bool get bothNeedUpdate => clientNeedsUpdate && serverNeedsUpdate;
}

class UpdateService {
  static const String _prefEtagKey = 'github_release_etag';
  static const String _prefLatestTagKey = 'github_release_latest_tag';
  static const String _prefReleaseUrlKey = 'github_release_url';
  static const String _prefReleaseNotesKey = 'github_release_notes';

  static bool _hasRunStartupCheck = false;
  static UpdateStatus? _lastStatus;

  /// Returns the cached status if already checked during this app session.
  static UpdateStatus? get cachedStatus => _lastStatus;

  /// Cleans and extracts major.minor.patch from tags like "v1.0.13", "v.1.0.13", "1.0.13+1"
  static String cleanSemver(String version) {
    var v = version.trim();
    // Remove leading v. or v (case insensitive)
    v = v.replaceFirst(RegExp(r'^[vV]\.?'), '');
    // Remove build metadata e.g. +1
    if (v.contains('+')) {
      v = v.split('+').first;
    }
    // Remove pre-release metadata e.g. -beta.1
    if (v.contains('-')) {
      v = v.split('-').first;
    }
    return v.trim();
  }

  /// Compares two semver strings: returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal.
  static int compareSemver(String v1, String v2) {
    final clean1 = cleanSemver(v1);
    final clean2 = cleanSemver(v2);

    final parts1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// Returns true if candidate is strictly newer than current.
  static bool isNewer(String candidate, String current) {
    return compareSemver(candidate, current) > 0;
  }

  /// Checks for updates against GitHub Releases using conditional HTTP (If-None-Match).
  /// [force]: if false and already ran once during this session, returns cached result.
  static Future<UpdateStatus?> checkForUpdates({bool force = false}) async {
    if (_hasRunStartupCheck && !force) {
      return _lastStatus;
    }
    _hasRunStartupCheck = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEtag = prefs.getString(_prefEtagKey);
      final savedLatestTag = prefs.getString(_prefLatestTagKey);
      final savedReleaseUrl = prefs.getString(_prefReleaseUrlKey);
      final savedReleaseNotes = prefs.getString(_prefReleaseNotesKey);

      final url = Uri.parse(
        'https://api.github.com/repos/${AppVersion.githubOwner}/${AppVersion.githubRepo}/releases/latest',
      );

      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'MSchool-App',
      };

      if (savedEtag != null && savedEtag.isNotEmpty) {
        headers['If-None-Match'] = savedEtag;
      }

      String? latestTag = savedLatestTag;
      String? releaseUrl = savedReleaseUrl;
      String? releaseNotes = savedReleaseNotes;

      try {
        final response = await http.get(url, headers: headers).timeout(
          const Duration(seconds: 5),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          latestTag = data['tag_name'] as String?;
          releaseUrl = data['html_url'] as String?;
          releaseNotes = data['body'] as String?;

          final etag = response.headers['etag'];
          if (etag != null && etag.isNotEmpty) {
            await prefs.setString(_prefEtagKey, etag);
          }
          if (latestTag != null) {
            await prefs.setString(_prefLatestTagKey, latestTag);
          }
          if (releaseUrl != null) {
            await prefs.setString(_prefReleaseUrlKey, releaseUrl);
          }
          if (releaseNotes != null) {
            await prefs.setString(_prefReleaseNotesKey, releaseNotes);
          }
        } else if (response.statusCode == 304) {
          // Not Modified: use cached release tag
          latestTag = savedLatestTag;
          releaseUrl = savedReleaseUrl;
          releaseNotes = savedReleaseNotes;
        } else {
          debugPrint('GitHub Releases check returned HTTP ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('GitHub Releases network check skipped/failed: $e');
      }

      if (latestTag == null || latestTag.isEmpty) {
        return null;
      }

      // 1. Get client version
      String clientVer = AppVersion.current;
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        if (packageInfo.version.isNotEmpty) {
          clientVer = packageInfo.version;
        }
      } catch (_) {}

      // 2. Get server version
      String? serverVer;
      try {
        final serverMeta = await SystemApi.getVersion();
        serverVer = serverMeta['version'] as String?;
      } catch (_) {
        // Fallback to health check if getVersion fails
        try {
          final health = await SystemApi.testConnection();
          if (health['success'] == true) {
            serverVer = health['version'] as String?;
          }
        } catch (_) {}
      }

      final cleanLatest = cleanSemver(latestTag);
      final cleanClient = cleanSemver(clientVer);
      final cleanServer = serverVer != null ? cleanSemver(serverVer) : null;

      final clientNeedsUpdate = isNewer(cleanLatest, cleanClient);
      final serverNeedsUpdate = cleanServer != null && isNewer(cleanLatest, cleanServer);

      _lastStatus = UpdateStatus(
        currentClientVersion: clientVer,
        currentServerVersion: serverVer,
        latestReleaseVersion: cleanLatest,
        releaseUrl: releaseUrl,
        releaseNotes: releaseNotes,
        clientNeedsUpdate: clientNeedsUpdate,
        serverNeedsUpdate: serverNeedsUpdate,
      );

      return _lastStatus;
    } catch (e) {
      debugPrint('Error evaluating update status: $e');
      return null;
    }
  }
}
