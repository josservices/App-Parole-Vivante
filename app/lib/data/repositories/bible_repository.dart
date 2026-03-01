import '../../domain/bible_models.dart';
import '../bible_data_source.dart';
import '../bible_data_source_factory.dart';
import '../db/app_database.dart';

class BibleRepository {
  BibleRepository({AppDatabase? database, BibleDataSource? dataSource})
      : _dataSource = dataSource ??
            createBibleDataSource(database: database ?? AppDatabase.instance);

  final BibleDataSource _dataSource;

  bool get usesSimpleSearch => _dataSource.usesSimpleSearch;

  Future<List<BibleBook>> getBooks() {
    return _dataSource.getBooks();
  }

  Future<List<int>> getChapterNumbers(String bookId) {
    return _dataSource.getChapters(bookId);
  }

  Future<List<BibleVerse>> getVerses(String bookId, int chapterNumber) {
    return _dataSource.getVerses(bookId, chapterNumber);
  }

  Future<BibleVerse?> getVerseById(String verseId) async {
    final parsed = _parseVerseId(verseId);
    if (parsed == null) {
      return null;
    }

    return _dataSource.getVerseByRef(
      parsed.bookId,
      parsed.chapterNumber,
      parsed.verseNumber,
    );
  }

  Future<BibleVerse?> getVerseByRef(
    String bookId,
    int chapterNumber,
    int verseNumber,
  ) {
    return _dataSource.getVerseByRef(bookId, chapterNumber, verseNumber);
  }

  Future<void> saveReadingProgress(String bookId, int chapterNumber) async {
    await _dataSource.saveReadingProgress(bookId, chapterNumber);
  }

  Future<ReadingProgress?> getReadingProgress() {
    return _dataSource.getReadingProgress();
  }

  _VerseRef? _parseVerseId(String verseId) {
    final tokens = verseId.split('-');
    if (tokens.length < 3) {
      return null;
    }

    final verseNumber = int.tryParse(tokens.last);
    final chapterNumber = int.tryParse(tokens[tokens.length - 2]);
    if (verseNumber == null || chapterNumber == null) {
      return null;
    }

    final bookId = tokens.sublist(0, tokens.length - 2).join('-');
    if (bookId.isEmpty) {
      return null;
    }
    return _VerseRef(
      bookId: bookId,
      chapterNumber: chapterNumber,
      verseNumber: verseNumber,
    );
  }
}

class _VerseRef {
  const _VerseRef({
    required this.bookId,
    required this.chapterNumber,
    required this.verseNumber,
  });

  final String bookId;
  final int chapterNumber;
  final int verseNumber;
}
