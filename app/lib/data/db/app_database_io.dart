import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const String _dbFileName = 'bible.db';
  static const Set<String> _requiredSeedTables = <String>{
    'books',
    'chapters',
    'verses',
  };

  Database? _db;
  bool _databaseFactoryConfigured = false;

  Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }
    _db = await _open();
    return _db!;
  }

  Future<String> get databasePath async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, _dbFileName);
  }

  Future<Database> _open() async {
    _configureDatabaseFactoryIfNeeded();
    final dbPath = await databasePath;
    debugPrint('[AppDatabase] dbPath=$dbPath');
    await _logFileState(dbPath, label: 'before-open');

    await _prepareBundledDatabase(dbPath);

    Database db;
    try {
      db = await _openDatabaseAtPath(dbPath);
    } catch (error, stackTrace) {
      debugPrint('[AppDatabase] openDatabase failed, forcing recopy: $error');
      debugPrint('$stackTrace');
      await _copyBundledDatabase(dbPath, reason: 'open failure');
      db = await _openDatabaseAtPath(dbPath);
    }

    final hasSeedTables = await _hasRequiredSeedTables(db);
    if (!hasSeedTables) {
      debugPrint('[AppDatabase] Seed tables missing, recreating bundled DB.');
      await db.close();
      await _deleteDbFile(dbPath);
      await _copyBundledDatabase(dbPath, reason: 'missing required tables');
      db = await _openDatabaseAtPath(dbPath);
      if (!await _hasRequiredSeedTables(db)) {
        await db.close();
        throw StateError(
          'Bundled database invalid: required tables '
          '${_requiredSeedTables.join(', ')} missing.',
        );
      }
    }

    await healthCheck(db: db);
    return db;
  }

  void _configureDatabaseFactoryIfNeeded() {
    if (_databaseFactoryConfigured) {
      return;
    }
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      debugPrint('[AppDatabase] Using sqflite_common_ffi databaseFactory.');
    }
    _databaseFactoryConfigured = true;
  }

  Future<void> _prepareBundledDatabase(String dbPath) async {
    final file = File(dbPath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    if (!exists) {
      await _copyBundledDatabase(dbPath, reason: 'db file missing');
      return;
    }
    if (size == 0) {
      await _copyBundledDatabase(dbPath, reason: 'db file is empty');
    }
  }

  Future<Database> _openDatabaseAtPath(String dbPath) {
    return openDatabase(
      dbPath,
      version: 1,
      onOpen: (db) async {
        await _ensureAuxTables(db);
      },
    );
  }

  Future<void> _copyBundledDatabase(String dbPath, {required String reason}) async {
    debugPrint('[AppDatabase] Copying bundled database ($reason).');
    ByteData bytes;
    try {
      bytes = await rootBundle.load('assets/$_dbFileName');
    } catch (error, stackTrace) {
      debugPrint('[AppDatabase] rootBundle.load failed: $error');
      debugPrint('$stackTrace');
      throw StateError(
        'Unable to load asset assets/$_dbFileName. '
        'Verify flutter/assets in pubspec.yaml.',
      );
    }
    final buffer = bytes.buffer;
    await File(dbPath).parent.create(recursive: true);
    await File(dbPath).writeAsBytes(
      buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      flush: true,
    );
    await _logFileState(dbPath, label: 'after-copy');
  }

  Future<void> _deleteDbFile(String dbPath) async {
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
      debugPrint('[AppDatabase] Deleted invalid DB file at $dbPath');
    }
  }

  Future<void> _logFileState(String dbPath, {required String label}) async {
    final file = File(dbPath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    debugPrint(
      '[AppDatabase] $label exists=$exists size=$size bytes path=$dbPath',
    );
  }

  Future<bool> _hasRequiredSeedTables(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    final names = rows
        .map((row) => row['name'])
        .whereType<String>()
        .toSet();
    debugPrint('[AppDatabase] sqlite tables: ${names.join(', ')}');

    final missing = _requiredSeedTables.difference(names);
    if (missing.isNotEmpty) {
      debugPrint('[AppDatabase] Missing required tables: ${missing.join(', ')}');
      return false;
    }
    return true;
  }

  Future<void> healthCheck({Database? db}) async {
    final database = db ?? await this.database;
    final count = Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM books'),
        ) ??
        0;
    debugPrint('[AppDatabase] healthCheck books count=$count');
    if (count == 0) {
      throw StateError('DB seeded but empty');
    }
  }

  Future<int> _countRows(Database db, String table) async {
    final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table'),
        ) ??
        0;
    return count;
  }

  Future<AppDatabaseDiagnostics> collectDiagnostics() async {
    final dbPath = await databasePath;
    final file = File(dbPath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;

    try {
      final db = await database;
      final books = await _countRows(db, 'books');
      final chapters = await _countRows(db, 'chapters');
      final verses = await _countRows(db, 'verses');
      return AppDatabaseDiagnostics(
        path: dbPath,
        exists: exists,
        sizeBytes: size,
        booksCount: books,
        chaptersCount: chapters,
        versesCount: verses,
      );
    } catch (error) {
      return AppDatabaseDiagnostics(
        path: dbPath,
        exists: exists,
        sizeBytes: size,
        booksCount: -1,
        chaptersCount: -1,
        versesCount: -1,
        error: error.toString(),
      );
    }
  }

  Future<void> close() async {
    if (_db == null) {
      return;
    }
    await _db!.close();
    _db = null;
  }

  Future<void> _ensureAuxTables(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS favorites('
      'verse_id TEXT PRIMARY KEY, '
      'created_at TEXT DEFAULT CURRENT_TIMESTAMP)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS highlights('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'verse_id TEXT NOT NULL, '
      'color TEXT NOT NULL, '
      'created_at TEXT DEFAULT CURRENT_TIMESTAMP)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS notes('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'verse_id TEXT NOT NULL, '
      'content TEXT NOT NULL, '
      'created_at TEXT DEFAULT CURRENT_TIMESTAMP, '
      'updated_at TEXT DEFAULT CURRENT_TIMESTAMP)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reading_progress('
      'id INTEGER PRIMARY KEY CHECK(id = 1), '
      'book_id TEXT NOT NULL, '
      'chapter_number INTEGER NOT NULL, '
      'updated_at TEXT DEFAULT CURRENT_TIMESTAMP)',
    );
  }
}

class AppDatabaseDiagnostics {
  const AppDatabaseDiagnostics({
    required this.path,
    required this.exists,
    required this.sizeBytes,
    required this.booksCount,
    required this.chaptersCount,
    required this.versesCount,
    this.error,
  });

  final String path;
  final bool exists;
  final int sizeBytes;
  final int booksCount;
  final int chaptersCount;
  final int versesCount;
  final String? error;

  String toMultilineText() {
    final lines = <String>[
      'path: $path',
      'exists: $exists',
      'sizeBytes: $sizeBytes',
      'books: $booksCount',
      'chapters: $chaptersCount',
      'verses: $versesCount',
    ];
    if (error != null) {
      lines.add('error: $error');
    }
    return lines.join('\n');
  }
}
