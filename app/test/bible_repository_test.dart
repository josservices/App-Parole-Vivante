import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:parole_vivante_nt/data/db/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final docsDirectory = Directory(
    p.join(Directory.systemTemp.path, 'parole_vivante_nt_test_docs'),
  );
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await docsDirectory.create(recursive: true);
    messenger.setMockMethodCallHandler(pathProviderChannel, (call) async {
      switch (call.method) {
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
        case 'getLibraryDirectory':
        case 'getTemporaryDirectory':
          return docsDirectory.path;
        default:
          return docsDirectory.path;
      }
    });
  });

  tearDownAll(() async {
    await AppDatabase.instance.close();
    messenger.setMockMethodCallHandler(pathProviderChannel, null);
    if (await docsDirectory.exists()) {
      await docsDirectory.delete(recursive: true);
    }
  });

  setUp(() async {
    await AppDatabase.instance.close();
    final dbFile = File(p.join(docsDirectory.path, 'bible.db'));
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  });

  test('offline DB seed integrity (books/matthieu/verses)', () async {
    final db = await AppDatabase.instance.database;

    final booksCountRows = await db.rawQuery('SELECT COUNT(*) AS c FROM books');
    final booksCount = _countFromRows(
      booksCountRows,
      reason: 'Unable to read books count (table "books" missing or invalid).',
    );
    expect(
      booksCount,
      27,
      reason: 'Expected 27 NT books, found $booksCount.',
    );

    final mattRows = await db.rawQuery(
      "SELECT id FROM books WHERE id = 'matthieu' LIMIT 1",
    );
    expect(
      mattRows,
      isNotEmpty,
      reason: 'Book "matthieu" not found in table "books".',
    );

    final versesRows = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM verses WHERE book_id = 'matthieu' AND chapter_number = 1",
    );
    final versesCount = _countFromRows(
      versesRows,
      reason: 'Unable to read verses count for matthieu chapitre 1.',
    );
    expect(
      versesCount,
      greaterThan(0),
      reason: 'No verses found for matthieu chapitre 1.',
    );

    Future<int> chapterCountFor(String bookId) async {
      final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM chapters WHERE book_id = ?',
        [bookId],
      );
      return _countFromRows(
        rows,
        reason: 'Unable to read chapter count for "$bookId".',
      );
    }

    expect(
      await chapterCountFor('matthieu'),
      28,
      reason: 'Expected 28 chapters for matthieu.',
    );
    expect(
      await chapterCountFor('marc'),
      16,
      reason: 'Expected 16 chapters for marc.',
    );
    expect(
      await chapterCountFor('apocalypse'),
      22,
      reason: 'Expected 22 chapters for apocalypse.',
    );
  });
}

int _countFromRows(
  List<Map<String, Object?>> rows, {
  required String reason,
}) {
  if (rows.isEmpty || rows.first.isEmpty) {
    fail(reason);
  }
  final value = rows.first.values.first;
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  fail('$reason Got value type: ${value.runtimeType}');
}
