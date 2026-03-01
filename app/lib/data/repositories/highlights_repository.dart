import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/bible_models.dart';
import '../db/app_database.dart';

class HighlightsRepository {
  HighlightsRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  final List<HighlightItem> _webHighlights = <HighlightItem>[];
  int _webAutoId = 0;

  Future<Database> get _db async => _database.database;

  Future<void> highlightVerse(String verseId, {String color = '#FFE082'}) async {
    if (kIsWeb) {
      _webHighlights.add(
        HighlightItem(
          id: ++_webAutoId,
          verseId: verseId,
          color: color,
          createdAt: DateTime.now(),
        ),
      );
      return;
    }

    final db = await _db;
    await db.insert('highlights', {'verse_id': verseId, 'color': color});
  }

  Future<List<HighlightItem>> listHighlights() async {
    if (kIsWeb) {
      final highlights = _webHighlights.toList(growable: false)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return highlights;
    }

    final rows = await (await _db).query('highlights', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => HighlightItem(
            id: (row['id'] as num).toInt(),
            verseId: row['verse_id'] as String,
            color: row['color'] as String,
            createdAt: DateTime.tryParse((row['created_at'] as String?) ?? '') ?? DateTime.now(),
          ),
        )
        .toList(growable: false);
  }
}
