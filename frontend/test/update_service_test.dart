import 'package:flutter_test/flutter_test.dart';
import 'package:mschool/services/update_service.dart';

void main() {
  group('UpdateService semver tests', () {
    test('cleanSemver removes prefixes and metadata', () {
      expect(UpdateService.cleanSemver('v1.1.0'), '1.1.0');
      expect(UpdateService.cleanSemver('v.1.1.0'), '1.1.0');
      expect(UpdateService.cleanSemver('1.1.0+1'), '1.1.0');
      expect(UpdateService.cleanSemver('v1.1.0-beta.1'), '1.1.0');
      expect(UpdateService.cleanSemver('  1.1.0  '), '1.1.0');
    });

    test('compareSemver compares versions correctly', () {
      expect(UpdateService.compareSemver('1.1.0', '1.0.13'), 1);
      expect(UpdateService.compareSemver('1.0.13', '1.1.0'), -1);
      expect(UpdateService.compareSemver('1.1.0', '1.1.0'), 0);
      expect(UpdateService.compareSemver('v1.1.0', '1.1.0+1'), 0);
      expect(UpdateService.compareSemver('2.0.0', '1.9.9'), 1);
      expect(UpdateService.compareSemver('1.0.0', '1.0.1'), -1);
    });

    test('isNewer returns true only for strictly higher versions', () {
      expect(UpdateService.isNewer('1.1.0', '1.0.13'), isTrue);
      expect(UpdateService.isNewer('1.0.13', '1.1.0'), isFalse);
      expect(UpdateService.isNewer('1.1.0', '1.1.0'), isFalse);
    });
  });
}
