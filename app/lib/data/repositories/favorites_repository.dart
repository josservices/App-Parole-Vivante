import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/bible_models.dart';
import '../db/app_database.dart';
import 'bible_repository.dart';

class FavoritesRepository {
  FavoritesRepository({AppDatabase? database, BibleRepository? bibleRepository})
    : _database = database ?? AppDatabase.instance,
      _bibleRepository = bibleRepository ?? BibleRepository(database: database);

  final AppDatabase _database;
  final BibleRepository _bibleRepository;
  final Set<String> _webFavorites = <String>{};

  Future<Database> get _db async => _database.database;

  Future<bool> isFavorite(String verseId) async {
    if (kIsWeb) {
      return _webFavorites.contains(verseId);
    }
    final rows = await (await _db).query('favorites', where: 'verse_id = ?', whereArgs: [verseId], limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> toggleFavorite(String verseId) async {
    if (kIsWeb) {
      if (_webFavorites.contains(verseId)) {
        _webFavorites.remove(verseId);
      } else {
        _webFavorites.add(verseId);
      }
      return;
    }

    final db = await _db;
    if (await isFavorite(verseId)) {
      await db.delete('favorites', where: 'verse_id = ?', whereArgs: [verseId]);
      return;
    }
    await db.insert('favorites', {'verse_id': verseId});
  }

  Future<List<BibleVerse>> listFavorites() async {
    if (kIsWeb) {
      final verseIds = _webFavorites.toList(growable: false).reversed;
      final verses = <BibleVerse>[];
      for (final verseId in verseIds) {
        final verse = await _bibleRepository.getVerseById(verseId);
        if (verse != null) {
          verses.add(verse);
        }
      }
      return verses;
    }

    final rows = await (await _db).rawQuery(
      '''
      SELECT v.*
      FROM favorites f
      JOIN verses v ON v.id = f.verse_id
      ORDER BY f.created_at DESC
      ''',
    );

    return rows
        .map(
          (row) => BibleVerse(
            id: row['id'] as String,
            bookId: row['book_id'] as String,
            chapterNumber: (row['chapter_number'] as num).toInt(),
            verseNumber: (row['verse_number'] as num).toInt(),
            text: row['text'] as String,
          ),
        )
        .toList(growable: false);
  }
}
