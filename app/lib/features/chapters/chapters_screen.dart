import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/bible_repository.dart';
import '../../domain/bible_models.dart';
import '../common/async_state_view.dart';
import '../reader/chapter_reader_screen.dart';

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({
    super.key,
    required this.book,
    this.onSelectChapter,
    this.selectedChapterNumber,
    this.showScaffold = true,
  });

  final BibleBook book;
  final ValueChanged<int>? onSelectChapter;
  final int? selectedChapterNumber;
  final bool showScaffold;

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  static const Duration _loadTimeout = Duration(seconds: 8);
  late Future<List<int>> _chaptersFuture;

  @override
  void initState() {
    super.initState();
    _chaptersFuture = _loadChapters();
  }

  Future<List<int>> _loadChapters() {
    final repo = context.read<BibleRepository>();
    return repo.getChapterNumbers(widget.book.id).timeout(_loadTimeout);
  }

  void _retry() {
    setState(() {
      _chaptersFuture = _loadChapters();
    });
  }

  @override
  void didUpdateWidget(covariant ChaptersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      setState(() {
        _chaptersFuture = _loadChapters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<int>>(
      future: _chaptersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AsyncStateView(
            title: 'Erreur de chargement',
            message: 'Impossible de charger les chapitres.',
            onRetry: _retry,
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
        }

        final chapters = snapshot.data;
        if (chapters == null || chapters.isEmpty) {
          return AsyncStateView(
            icon: Icons.grid_view_outlined,
            title: 'Aucun chapitre trouvé',
            message: 'Aucun chapitre trouvé (DB vide ou requête incorrecte).',
            onRetry: _retry,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 520
                ? 5
                : width >= 380
                    ? 4
                    : 3;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.2,
              ),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final number = chapters[index];
                final isSelected = widget.selectedChapterNumber == number;
                final colorScheme = Theme.of(context).colorScheme;
                return Tooltip(
                  message: 'Chapitre $number',
                  child: Material(
                    elevation: isSelected ? 1 : 0,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (widget.onSelectChapter != null) {
                          widget.onSelectChapter!(number);
                          return;
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChapterReaderScreen(
                              bookId: widget.book.id,
                              chapterNumber: number,
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 44,
                            minWidth: 44,
                          ),
                          child: Center(
                            child: Text(
                              number.toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onPrimaryContainer,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (!widget.showScaffold) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.name)),
      body: body,
    );
  }
}
