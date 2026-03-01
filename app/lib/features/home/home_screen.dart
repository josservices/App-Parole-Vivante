import 'package:flutter/material.dart';

import '../../data/repositories/bible_repository.dart';
import '../books/books_screen.dart';
import '../legal/legal_screen.dart';
import '../library/library_screen.dart';
import '../reader/chapter_reader_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.bibleRepository});

  final BibleRepository bibleRepository;
  static const double _mobileBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    return Scaffold(
      appBar: AppBar(title: const Text('Parole Vivante (NT)')),
      body: FutureBuilder(
        future: bibleRepository.getReadingProgress(),
        builder: (context, snapshot) {
          final progress = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BrandingHeader(isMobile: isMobile),
              const SizedBox(height: 16),
              if (progress != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_fill),
                    title: const Text('Reprendre la lecture'),
                    subtitle: Text(
                        '${progress.bookId} chapitre ${progress.chapterNumber}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChapterReaderScreen(
                            bookId: progress.bookId,
                            chapterNumber: progress.chapterNumber,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BooksScreen()),
                  );
                },
                icon: const Icon(Icons.menu_book),
                label: const Text('Parcourir les livres'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchScreen()),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Recherche plein texte / référence'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LibraryScreen()),
                  );
                },
                icon: const Icon(Icons.bookmarks),
                label: const Text('Favoris, notes, surlignages'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LegalScreen()),
                  );
                },
                icon: const Icon(Icons.gavel),
                label: const Text('Mentions légales'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandingHeader extends StatelessWidget {
  const _BrandingHeader({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isMobile) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/branding/logo_mark.png',
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parole Vivante (NT)',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const _OfflineChip(),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Image.asset(
              'assets/branding/wordmark.png',
              height: 60,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const _OfflineChip(),
      ],
    );
  }
}

class _OfflineChip extends StatelessWidget {
  const _OfflineChip();

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.offline_bolt, size: 16),
      label: const Text('OFFLINE'),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}
