/// Single Source of Truth for MSchool Client Application Versioning.
class AppVersion {
  /// Current application version matching pubspec.yaml and Git tag.
  static const String current = '1.1.2';

  /// GitHub repository information for release checks.
  static const String githubOwner = 'Starry03';
  static const String githubRepo = 'mschool';

  static String get formatted => 'v$current';
}
