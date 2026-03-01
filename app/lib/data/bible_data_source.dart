import '../domain/bible_models.dart';

abstract class BibleDataSource {
  bool get usesSimpleSearch;

  Future<List<BibleBook>> getBooks();

  Future<List<int>> getChapters(String bookId);

  Future<List<BibleVerse>> getVerses(String bookId, int chapterNumber);

  Future<BibleVerse?> getVerseByRef(
    String bookId,
    int chapterNumber,
    int verseNumber,
  );

  Future<List<SearchResultVerse>> search(String query, {int limit = 100});

  Future<void> saveReadingProgress(String bookId, int chapterNumber);

  Future<ReadingProgress?> getReadingProgress();
}
