import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/bible_models.dart';
import 'bible_data_source.dart';
import 'db/app_database.dart';

class SqliteBibleDataSource implements BibleDataSource {
  SqliteBibleDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<Database> get _db async => _database.database;

  @override
  bool get usesSimpleSearch => false;

  @override
  Future<List<BibleBook>> getBooks() async {
    debugPrint('[SqliteBibleDataSource] getBooks start');
    final rows = await (await _db).rawQuery(
      'SELECT id, ord, name, slug FROM books ORDER BY ord',
    );

    return rows
        .map(
          (row) => BibleBook(
            id: row['id'] as String,
            ord: (row['ord'] as num).toInt(),
            name: row['name'] as String,
            slug: row['slug'] as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<int>> getChapters(String bookId) async {
    final db = await _db;
    try {
      final rows = await db.rawQuery(
        'SELECT number FROM chapters WHERE book_id = ? ORDER BY number',
        [bookId],
      );
      if (rows.isNotEmpty) {
        return rows
            .map((row) => (row['number'] as num).toInt())
            .toList(growable: false);
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[SqliteBibleDataSource] getChapters fallback to verses: $error',
      );
      debugPrint('$stackTrace');
    }

    final fallbackRows = await db.rawQuery(
      'SELECT DISTINCT chapter_number AS number '
      'FROM verses '
      'WHERE book_id = ? '
      'ORDER BY chapter_number',
      [bookId],
    );
    return fallbackRows
        .map((row) => (row['number'] as num).toInt())
        .toList(growable: false);
  }

  @override
  Future<List<BibleVerse>> getVerses(String bookId, int chapterNumber) async {
    final rows = await (await _db).query(
      'verses',
      where: 'book_id = ? AND chapter_number = ?',
      whereArgs: [bookId, chapterNumber],
      orderBy: 'verse_number ASC',
    );
    return rows.map(_verseFromRow).toList(growable: false);
  }

  @override
  Future<BibleVerse?> getVerseByRef(
    String bookId,
    int chapterNumber,
    int verseNumber,
  ) async {
    final rows = await (await _db).query(
      'verses',
      where: 'book_id = ? AND chapter_number = ? AND verse_number = ?',
      whereArgs: [bookId, chapterNumber, verseNumber],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _verseFromRow(rows.first);
  }

  @override
  Future<List<SearchResultVerse>> search(String query, {int limit = 100}) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) {
      return const [];
    }

    final rows = await (await _db).rawQuery(
      '''
      SELECT
        v.id,
        v.book_id,
        v.chapter_number,
        v.verse_number,
        v.text,
        snippet(verses_fts, 0, '<b>', '</b>', ' … ', 10) AS excerpt
      FROM verses_fts f
      JOIN verses v ON v.rowid = f.rowid
      WHERE verses_fts MATCH ?
      ORDER BY rank
      LIMIT ?
      ''',
      [cleaned, limit],
    );

    return rows
        .map(
          (row) => SearchResultVerse(
            id: row['id'] as String,
            bookId: row['book_id'] as String,
            chapterNumber: (row['chapter_number'] as num).toInt(),
            verseNumber: (row['verse_number'] as num).toInt(),
            text: row['text'] as String,
            highlight: (row['excerpt'] as String?) ?? row['text'] as String,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveReadingProgress(String bookId, int chapterNumber) async {
    await (await _db).insert(
      'reading_progress',
      {
        'id': 1,
        'book_id': bookId,
        'chapter_number': chapterNumber,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<ReadingProgress?> getReadingProgress() async {
    final rows = await (await _db).query(
      'reading_progress',
      where: 'id = 1',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return ReadingProgress(
      bookId: row['book_id'] as String,
      chapterNumber: (row['chapter_number'] as num).toInt(),
    );
  }

  BibleVerse _verseFromRow(Map<String, Object?> row) {
    return BibleVerse(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      chapterNumber: (row['chapter_number'] as num).toInt(),
      verseNumber: (row['verse_number'] as num).toInt(),
      text: row['text'] as String,
    );
  }
}
