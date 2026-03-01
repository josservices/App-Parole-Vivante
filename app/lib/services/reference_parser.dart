import '../domain/bible_models.dart';

class ReferenceParser {
  ReferenceParser();

  static final Map<String, String> _bookAliases = <String, String>{
    'matthieu': 'matthieu',
    'marc': 'marc',
    'luc': 'luc',
    'jean': 'jean',
    'actes': 'actes',
    'romains': 'romains',
    '1 corinthiens': '1-corinthiens',
    'premiere corinthiens': '1-corinthiens',
    '2 corinthiens': '2-corinthiens',
    'deuxieme corinthiens': '2-corinthiens',
    'galates': 'galates',
    'ephesiens': 'ephesiens',
    'philippiens': 'philippiens',
    'colossiens': 'colossiens',
    '1 thessaloniciens': '1-thessaloniciens',
    '2 thessaloniciens': '2-thessaloniciens',
    '1 timothee': '1-timothee',
    '2 timothee': '2-timothee',
    'tite': 'tite',
    'philemon': 'philemon',
    'hebreux': 'hebreux',
    'jacques': 'jacques',
    '1 pierre': '1-pierre',
    '2 pierre': '2-pierre',
    '1 jean': '1-jean',
    '2 jean': '2-jean',
    '3 jean': '3-jean',
    'jude': 'jude',
    'apocalypse': 'apocalypse',
  };

  ParsedReference? parse(String raw) {
    final normalized = _normalize(raw);
    final pattern = RegExp(r'^(.+?)\s+(\d+)(?::(\d+))?$');
    final match = pattern.firstMatch(normalized);
    if (match == null) {
      return null;
    }

    final bookPart = match.group(1)!.trim();
    final chapter = int.tryParse(match.group(2)!);
    final verse = match.group(3) == null ? null : int.tryParse(match.group(3)!);
    if (chapter == null) {
      return null;
    }

    final bookId = _bookAliases[bookPart];
    if (bookId == null) {
      return null;
    }

    return ParsedReference(bookId: bookId, chapter: chapter, verse: verse);
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r"\s+"), ' ')
        .trim();
  }
}
