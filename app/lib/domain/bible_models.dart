class BibleBook {
  const BibleBook({
    required this.id,
    required this.ord,
    required this.name,
    required this.slug,
  });

  final String id;
  final int ord;
  final String name;
  final String slug;
}

class BibleVerse {
  const BibleVerse({
    required this.id,
    required this.bookId,
    required this.chapterNumber,
    required this.verseNumber,
    required this.text,
  });

  final String id;
  final String bookId;
  final int chapterNumber;
  final int verseNumber;
  final String text;

  String get reference => '$bookId $chapterNumber:$verseNumber';
}

class SearchResultVerse extends BibleVerse {
  const SearchResultVerse({
    required super.id,
    required super.bookId,
    required super.chapterNumber,
    required super.verseNumber,
    required super.text,
    required this.highlight,
  });

  final String highlight;
}

class NoteItem {
  const NoteItem({
    required this.id,
    required this.verseId,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final String verseId;
  final String content;
  final DateTime createdAt;
}

class HighlightItem {
  const HighlightItem({
    required this.id,
    required this.verseId,
    required this.color,
    required this.createdAt,
  });

  final int id;
  final String verseId;
  final String color;
  final DateTime createdAt;
}

class ReadingProgress {
  const ReadingProgress({required this.bookId, required this.chapterNumber});

  final String bookId;
  final int chapterNumber;
}

class ParsedReference {
  const ParsedReference({
    required this.bookId,
    required this.chapter,
    this.verse,
  });

  final String bookId;
  final int chapter;
  final int? verse;
}
