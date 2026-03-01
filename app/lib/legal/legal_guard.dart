import '../config/app_config.dart';

class LegalGuard {
  static const int maxShareCharacters = 500;

  static bool get licenseOk => AppConfig.licenseOk;

  static void ensureDistributionAllowed(String featureName) {
    if (!licenseOk) {
      throw StateError(
        'Feature blocked by LEGAL_GUARD: $featureName. '
        'Activez manuellement LICENSE_OK=true après obtention de licence.',
      );
    }
  }

  static void ensureShareExcerptAllowed(String excerpt) {
    if (excerpt.trim().isEmpty) {
      throw StateError('Extrait vide: partage annulé.');
    }
    if (excerpt.length > maxShareCharacters) {
      throw StateError(
        'Partage limité à un petit extrait ($maxShareCharacters caractères max).',
      );
    }
  }
}
