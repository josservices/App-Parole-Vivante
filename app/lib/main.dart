import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'data/bible_data_source.dart';
import 'data/bible_data_source_factory.dart';
import 'data/db/app_database.dart';
import 'data/repositories/bible_repository.dart';
import 'data/repositories/favorites_repository.dart';
import 'data/repositories/highlights_repository.dart';
import 'data/repositories/notes_repository.dart';
import 'data/repositories/search_repository.dart';
import 'features/shell/app_shell.dart';
import 'features/settings/reading_preferences_controller.dart';
import 'services/reference_parser.dart';
import 'services/share_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final readingController = ReadingPreferencesController();
  await readingController.load();

  final appDatabase = AppDatabase.instance;
  final bibleDataSource = createBibleDataSource(database: appDatabase);
  final bibleRepository = BibleRepository(
    database: appDatabase,
    dataSource: bibleDataSource,
  );

  runApp(
    ChangeNotifierProvider.value(
      value: readingController,
      child: ParoleVivanteApp(
        appDatabase: appDatabase,
        bibleDataSource: bibleDataSource,
        bibleRepository: bibleRepository,
      ),
    ),
  );
}

class ParoleVivanteApp extends StatelessWidget {
  const ParoleVivanteApp({
    super.key,
    required this.appDatabase,
    required this.bibleDataSource,
    required this.bibleRepository,
  });

  final AppDatabase appDatabase;
  final BibleDataSource bibleDataSource;
  final BibleRepository bibleRepository;

  @override
  Widget build(BuildContext context) {
    final reading = context.watch<ReadingPreferencesController>();

    final textTheme = GoogleFonts.sourceSerif4TextTheme();

    return MultiProvider(
      providers: [
        Provider.value(value: appDatabase),
        Provider.value(value: bibleDataSource),
        Provider.value(value: bibleRepository),
        Provider(create: (_) => FavoritesRepository(database: appDatabase, bibleRepository: bibleRepository)),
        Provider(create: (_) => NotesRepository(database: appDatabase)),
        Provider(create: (_) => HighlightsRepository(database: appDatabase)),
        Provider(create: (_) => ReferenceParser()),
        Provider(
          create: (_) => SearchRepository(
            database: appDatabase,
            dataSource: bibleDataSource,
            bibleRepository: bibleRepository,
          ),
        ),
        Provider(create: (_) => ShareService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Parole Vivante (NT)',
        themeMode: reading.themeMode,
        theme: AppTheme.lightTheme(textTheme),
        darkTheme: AppTheme.darkTheme(textTheme),
        home: const AppShell(),
      ),
    );
  }
}
