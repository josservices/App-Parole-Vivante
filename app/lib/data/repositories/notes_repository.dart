import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/bible_models.dart';
import '../db/app_database.dart';

class NotesRepository {
  NotesRepository({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  final Map<String, _WebNoteRecord> _webNotes = <String, _WebNoteRecord>{};
  int _webAutoId = 0;

  Future<Database> get _db async => _database.database;

  Future<void> upsertNote(String verseId, String content) async {
    if (kIsWeb) {
      final trimmed = content.trim();
      final now = DateTime.now();
      final existing = _webNotes[verseId];
      _webNotes[verseId] = _WebNoteRecord(
        id: existing?.id ?? ++_webAutoId,
        content: trimmed,
        updatedAt: now,
      );
      return;
    }

    final db = await _db;
    final existing = await db.query('notes', where: 'verse_id = ?', whereArgs: [verseId], limit: 1);

    if (existing.isEmpty) {
      await db.insert('notes', {'verse_id': verseId, 'content': content.trim()});
      return;
    }

    await db.update(
      'notes',
      {'content': content.trim(), 'updated_at': DateTime.now().toIso8601String()},
      where: 'verse_id = ?',
      whereArgs: [verseId],
    );
  }

  Future<String?> getNoteContent(String verseId) async {
    if (kIsWeb) {
      return _webNotes[verseId]?.content;
    }

    final rows = await (await _db).query('notes', where: 'verse_id = ?', whereArgs: [verseId], limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['content'] as String;
  }

  Future<List<NoteItem>> listNotes() async {
    if (kIsWeb) {
      final entries = _webNotes.entries.toList(growable: false)
        ..sort((a, b) => b.value.updatedAt.compareTo(a.value.updatedAt));
      return entries
          .map(
            (entry) => NoteItem(
              id: entry.value.id,
              verseId: entry.key,
              content: entry.value.content,
              createdAt: entry.value.updatedAt,
            ),
          )
          .toList(growable: false);
    }

    final rows = await (await _db).query('notes', orderBy: 'updated_at DESC');
    return rows
        .map(
          (row) => NoteItem(
            id: (row['id'] as num).toInt(),
            verseId: row['verse_id'] as String,
            content: row['content'] as String,
            createdAt: DateTime.tryParse((row['updated_at'] as String?) ?? '') ?? DateTime.now(),
          ),
        )
        .toList(growable: false);
  }
}

class _WebNoteRecord {
  const _WebNoteRecord({
    required this.id,
    required this.content,
    required this.updatedAt,
  });

  final int id;
  final String content;
  final DateTime updatedAt;
}
