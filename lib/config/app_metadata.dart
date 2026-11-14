/// Single source of truth for Modulix application metadata,
/// versioning, release checkpoints, and official ecosystem endpoints.
class AppMetadata {
  AppMetadata._();

  /// User-facing application title.
  static const String appName = 'Modulix';

  /// Semantic version of the client application.
  static const String currentVersion = '1.38.0';

  /// Incremental integer build number.
  static const int buildNumber = 140;

  /// Full formatted version string (e.g. 'v1.38.0 (Build 140)').
  static const String fullVersionString = 'v$currentVersion (Build $buildNumber)';

  /// Active build checkpoint ledger ID.
  static const String checkpoint = 'CKPT-140';

  /// Official landing page & account portal URL.
  static const String websiteUrl = 'https://modulix.pages.dev';

  /// Official GitHub repository.
  static const String githubRepo = 'RxREAPER/Modulix';

  /// GitHub repository web URL.
  static const String githubRepoUrl = 'https://github.com/$githubRepo';

  /// Public GitHub Releases page.
  static const String githubReleasesUrl = 'https://github.com/$githubRepo/releases';

  /// REST endpoint to check the latest published release.
  static const String latestReleaseApiUrl =
      'https://api.github.com/repos/$githubRepo/releases/latest';

  /// Official support inquiries email.
  static const String supportEmail = 'support@modulix.app';

  /// Official privacy & data inquiries email.
  static const String privacyEmail = 'privacy@modulix.app';
}
