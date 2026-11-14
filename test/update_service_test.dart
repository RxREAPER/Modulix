import 'package:flutter_test/flutter_test.dart';
import 'package:modulix/config/app_metadata.dart';
import 'package:modulix/services/update_service.dart';

void main() {
  group('AppMetadata Tests', () {
    test('AppMetadata holds valid semantic version', () {
      expect(AppMetadata.appName, equals('Modulix'));
      expect(AppMetadata.currentVersion, matches(r'^\d+\.\d+\.\d+$'));
      expect(AppMetadata.buildNumber, isPositive);
      expect(AppMetadata.websiteUrl, startsWith('https://'));
      expect(AppMetadata.githubRepoUrl, contains('RxREAPER/Modulix'));
      expect(AppMetadata.latestReleaseApiUrl, contains('releases/latest'));
    });

    test('fullVersionString includes version and build number', () {
      expect(
        AppMetadata.fullVersionString,
        equals('v${AppMetadata.currentVersion} (Build ${AppMetadata.buildNumber})'),
      );
    });
  });

  group('UpdateService Semantic Comparison Tests', () {
    test('Detects newer remote patch version', () {
      const current = '1.38.0';
      const remote = '1.38.1';
      final isNewer = UpdateService.isVersionGreaterForTesting(remote, current);
      expect(isNewer, isTrue);
    });

    test('Detects newer remote minor version', () {
      const current = '1.38.0';
      const remote = '1.39.0';
      final isNewer = UpdateService.isVersionGreaterForTesting(remote, current);
      expect(isNewer, isTrue);
    });

    test('Detects newer remote major version', () {
      const current = '1.38.0';
      const remote = '2.0.0';
      final isNewer = UpdateService.isVersionGreaterForTesting(remote, current);
      expect(isNewer, isTrue);
    });

    test('Identifies identical version as not newer', () {
      const current = '1.38.0';
      const remote = '1.38.0';
      final isNewer = UpdateService.isVersionGreaterForTesting(remote, current);
      expect(isNewer, isFalse);
    });

    test('Identifies older remote version as not newer', () {
      const current = '1.38.0';
      const remote = '1.37.9';
      final isNewer = UpdateService.isVersionGreaterForTesting(remote, current);
      expect(isNewer, isFalse);
    });

    test('Handles malformed or empty remote version safely', () {
      const current = '1.38.0';
      expect(UpdateService.isVersionGreaterForTesting('', current), isFalse);
      expect(UpdateService.isVersionGreaterForTesting('invalid', current), isFalse);
    });
  });
}
