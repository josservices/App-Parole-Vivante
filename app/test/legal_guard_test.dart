import 'package:flutter_test/flutter_test.dart';

import 'package:parole_vivante_nt/legal/legal_guard.dart';

void main() {
  test('refuse partage si extrait trop long', () {
    final longText = 'a' * 600;
    expect(
      () => LegalGuard.ensureShareExcerptAllowed(longText),
      throwsStateError,
    );
  });

  test('refuse distribution si LICENSE_OK=false', () {
    expect(
      () => LegalGuard.ensureDistributionAllowed('export complet'),
      throwsStateError,
    );
  });
}
