import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Future<Database> get database async {
    throw UnsupportedError(
      'SQLite n\'est pas disponible sur Web. Utilisez JsonBibleDataSource.',
    );
  }

  Future<String> get databasePath async => 'web-json-mode';

  Future<void> healthCheck({Database? db}) async {}

  Future<AppDatabaseDiagnostics> collectDiagnostics() async {
    return const AppDatabaseDiagnostics(
      path: 'web-json-mode',
      exists: false,
      sizeBytes: 0,
      booksCount: -1,
      chaptersCount: -1,
      versesCount: -1,
      error: 'Diagnostic SQLite indisponible en mode Web JSON.',
    );
  }

  Future<void> close() async {}
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
