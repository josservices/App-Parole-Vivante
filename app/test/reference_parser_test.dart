import 'package:flutter_test/flutter_test.dart';

import 'package:parole_vivante_nt/services/reference_parser.dart';

void main() {
  group('ReferenceParser', () {
    final parser = ReferenceParser();

    test('parse Matthieu 5:3', () {
      final ref = parser.parse('Matthieu 5:3');
      expect(ref?.bookId, 'matthieu');
      expect(ref?.chapter, 5);
      expect(ref?.verse, 3);
    });

    test('parse 1 Corinthiens 13:4', () {
      final ref = parser.parse('1 Corinthiens 13:4');
      expect(ref?.bookId, '1-corinthiens');
      expect(ref?.chapter, 13);
      expect(ref?.verse, 4);
    });

    test('parse sans verset', () {
      final ref = parser.parse('Jean 3');
      expect(ref?.bookId, 'jean');
      expect(ref?.chapter, 3);
      expect(ref?.verse, isNull);
    });

    test('retourne null si format invalide', () {
      expect(parser.parse('abc'), isNull);
    });
  });
}
