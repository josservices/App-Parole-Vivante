import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../books/books_screen.dart';
import '../chapters/chapters_screen.dart';
import 'chapter_reader_screen.dart';
import 'reader_selection_controller.dart';

class DesktopReaderShell extends StatelessWidget {
  const DesktopReaderShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _DesktopPanel(
            key: const Key('desktop-panel-books'),
            title: 'Livres',
            child: BooksScreen(
              showScaffold: false,
              onSelectBook: (book) {
                context.read<ReaderSelectionController>().selectBook(book);
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: _DesktopPanel(
            key: const Key('desktop-panel-chapters'),
            title: 'Chapitres',
            child: Selector<ReaderSelectionController, String?>(
              selector: (_, selection) => selection.selectedBookId,
              builder: (context, selectedBookId, _) {
                if (selectedBookId == null) {
                  return const _DesktopPlaceholder(
                    icon: Icons.menu_book_outlined,
                    message:
                        'Sélectionnez un livre pour afficher les chapitres.',
                  );
                }
                final selection = context.read<ReaderSelectionController>();
                final selectedBook = selection.selectedBook;
                if (selectedBook == null) {
                  return const _DesktopPlaceholder(
                    icon: Icons.menu_book_outlined,
                    message:
                        'Sélectionnez un livre pour afficher les chapitres.',
                  );
                }
                return Selector<ReaderSelectionController, int?>(
                  selector: (_, selection) => selection.selectedChapter,
                  builder: (context, selectedChapter, _) {
                    return ChaptersScreen(
                      key: ValueKey(selectedBookId),
                      book: selectedBook,
                      selectedChapterNumber: selectedChapter,
                      showScaffold: false,
                      onSelectChapter: (chapterNumber) {
                        context
                            .read<ReaderSelectionController>()
                            .selectChapter(chapterNumber);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: Selector<ReaderSelectionController,
              ({String? bookId, String? bookName, int? chapter})>(
            selector: (_, selection) => (
              bookId: selection.selectedBookId,
              bookName: selection.selectedBookName,
              chapter: selection.selectedChapter,
            ),
            builder: (context, value, _) {
              return _DesktopPanel(
                key: const Key('desktop-panel-reader'),
                title: _readerTitle(value.bookName, value.chapter),
                child: _readerContent(
                  selectedBookId: value.bookId,
                  selectedChapter: value.chapter,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _readerTitle(String? bookName, int? chapter) {
    if (bookName == null || chapter == null) {
      return 'Lecture';
    }
    return '$bookName $chapter';
  }

  Widget _readerContent({
    required String? selectedBookId,
    required int? selectedChapter,
  }) {
    if (selectedBookId == null || selectedChapter == null) {
      return const _DesktopPlaceholder(
        icon: Icons.chrome_reader_mode_outlined,
        message: 'Sélectionnez un chapitre pour ouvrir la lecture.',
      );
    }
    return ChapterReaderScreen(
      key: ValueKey('$selectedBookId:$selectedChapter'),
      bookId: selectedBookId,
      chapterNumber: selectedChapter,
      showScaffold: false,
    );
  }
}

class _DesktopPanel extends StatelessWidget {
  const _DesktopPanel({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}

class _DesktopPlaceholder extends StatelessWidget {
  const _DesktopPlaceholder({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
