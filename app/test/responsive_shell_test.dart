import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:parole_vivante_nt/data/repositories/bible_repository.dart';
import 'package:parole_vivante_nt/domain/bible_models.dart';
import 'package:parole_vivante_nt/features/shell/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fakeBibleRepository = _FakeBibleRepository();

  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.reset();
  });

  testWidgets('width 400 displays BottomNavigationBar', (tester) async {
    await _pumpShellWithWidth(
      tester,
      width: 400,
      initialIndex: 4,
      bibleRepository: fakeBibleRepository,
    );

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('width 1200 displays NavigationRail', (tester) async {
    await _pumpShellWithWidth(
      tester,
      width: 1200,
      initialIndex: 4,
      bibleRepository: fakeBibleRepository,
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('desktop books tab displays 3 reader panels', (tester) async {
    await _pumpShellWithWidth(
      tester,
      width: 1200,
      initialIndex: 1,
      bibleRepository: fakeBibleRepository,
    );

    expect(find.byKey(const Key('desktop-panel-books')), findsOneWidget);
    expect(find.byKey(const Key('desktop-panel-chapters')), findsOneWidget);
    expect(find.byKey(const Key('desktop-panel-reader')), findsOneWidget);
  });

  testWidgets('desktop chapters panel updates with selected book', (
    tester,
  ) async {
    await _pumpShellWithWidth(
      tester,
      width: 1200,
      initialIndex: 1,
      bibleRepository: fakeBibleRepository,
    );

    await tester.tap(find.text('Matthieu'));
    await tester.pumpAndSettle();
    expect(find.text('28'), findsOneWidget);
    expect(find.text('16'), findsOneWidget);

    await tester.tap(find.text('Marc'));
    await tester.pumpAndSettle();
    expect(find.text('16'), findsOneWidget);
    expect(find.text('28'), findsNothing);

    await tester.tap(find.text('Apocalypse'));
    await tester.pumpAndSettle();
    expect(find.text('22'), findsOneWidget);
    expect(find.text('28'), findsNothing);
  });
}

Future<void> _pumpShellWithWidth(
  WidgetTester tester, {
  required double width,
  required int initialIndex,
  required BibleRepository bibleRepository,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, 800);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    Provider<BibleRepository>.value(
      value: bibleRepository,
      child: MaterialApp(
        home: AppShell(initialIndex: initialIndex),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeBibleRepository extends BibleRepository {
  _FakeBibleRepository();

  static const _matthieu = BibleBook(
    id: 'matthieu',
    ord: 1,
    name: 'Matthieu',
    slug: 'matthieu',
  );
  static const _marc = BibleBook(
    id: 'marc',
    ord: 2,
    name: 'Marc',
    slug: 'marc',
  );
  static const _apocalypse = BibleBook(
    id: 'apocalypse',
    ord: 27,
    name: 'Apocalypse',
    slug: 'apocalypse',
  );

  @override
  Future<List<BibleBook>> getBooks() async {
    return const [_matthieu, _marc, _apocalypse];
  }

  @override
  Future<List<int>> getChapterNumbers(String bookId) async {
    final chaptersByBook = <String, int>{
      'matthieu': 28,
      'marc': 16,
      'apocalypse': 22,
    };
    final total = chaptersByBook[bookId] ?? 0;
    if (total <= 0) {
      return const <int>[];
    }
    return List<int>.generate(total, (index) => index + 1);
  }

  @override
  Future<List<BibleVerse>> getVerses(String bookId, int chapterNumber) async {
    return <BibleVerse>[
      BibleVerse(
        id: '$bookId-$chapterNumber-1',
        bookId: bookId,
        chapterNumber: chapterNumber,
        verseNumber: 1,
        text: 'placeholder',
      ),
    ];
  }

  @override
  Future<ReadingProgress?> getReadingProgress() async {
    return null;
  }

  @override
  Future<void> saveReadingProgress(String bookId, int chapterNumber) async {}
}
