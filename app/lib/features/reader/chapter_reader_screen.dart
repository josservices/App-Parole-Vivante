import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/bible_repository.dart';
import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/highlights_repository.dart';
import '../../data/repositories/notes_repository.dart';
import '../../domain/bible_models.dart';
import '../../services/share_service.dart';
import '../common/async_state_view.dart';
import '../settings/reading_preferences_controller.dart';
import '../settings/reading_settings_sheet.dart';

class ChapterReaderScreen extends StatefulWidget {
  const ChapterReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
    this.showScaffold = true,
  });

  final String bookId;
  final int chapterNumber;
  final bool showScaffold;

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  static const Duration _loadTimeout = Duration(seconds: 8);
  late int _chapterNumber;
  late Future<List<BibleVerse>> _versesFuture;
  List<int> _allChapters = const [];

  @override
  void initState() {
    super.initState();
    _chapterNumber = widget.chapterNumber;
    _loadChapterMetadata();
    _versesFuture = _loadVersesWithTimeout();
  }

  @override
  void didUpdateWidget(covariant ChapterReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.chapterNumber != widget.chapterNumber) {
      _chapterNumber = widget.chapterNumber;
      _loadChapterMetadata();
      _versesFuture = _loadVersesWithTimeout();
    }
  }

  Future<void> _loadChapterMetadata() async {
    final repo = context.read<BibleRepository>();
    try {
      final chapters = await repo
          .getChapterNumbers(widget.bookId)
          .timeout(_loadTimeout);
      if (mounted) {
        setState(() {
          _allChapters = chapters;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('[ChapterReaderScreen] _loadChapterMetadata failed: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<List<BibleVerse>> _loadVerses() async {
    final repo = context.read<BibleRepository>();
    final verses = await repo.getVerses(widget.bookId, _chapterNumber);
    await repo.saveReadingProgress(widget.bookId, _chapterNumber);
    return verses;
  }

  bool get _hasPrev => _allChapters.contains(_chapterNumber - 1);
  bool get _hasNext => _allChapters.contains(_chapterNumber + 1);

  Future<List<BibleVerse>> _loadVersesWithTimeout() {
    return _loadVerses().timeout(_loadTimeout);
  }

  void _retryVerses() {
    setState(() {
      _versesFuture = _loadVersesWithTimeout();
    });
  }

  void _goToChapter(int chapter) {
    setState(() {
      _chapterNumber = chapter;
      _versesFuture = _loadVersesWithTimeout();
    });
  }

  Future<void> _showVerseActions(BibleVerse verse) async {
    final favorites = context.read<FavoritesRepository>();
    final notes = context.read<NotesRepository>();
    final highlights = context.read<HighlightsRepository>();
    final shareService = context.read<ShareService>();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copier'),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: '${verse.reference} ${verse.text}'),
                  );
                  if (!mounted || !context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Verset copié.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite),
                title: const Text('Favori'),
                onTap: () async {
                  await favorites.toggleFavorite(verse.id);
                  if (!mounted || !context.mounted) return;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.highlight),
                title: const Text('Surligner'),
                onTap: () async {
                  await highlights.highlightVerse(verse.id);
                  if (!mounted || !context.mounted) return;
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_alt),
                title: const Text('Note'),
                onTap: () async {
                  Navigator.pop(context);
                  final existing = await notes.getNoteContent(verse.id) ?? '';
                  if (!mounted) return;
                  final controller = TextEditingController(text: existing);
                  final save = await showDialog<bool>(
                    context: this.context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Note sur le verset'),
                        content: TextField(
                          controller: controller,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            hintText: 'Votre note...'
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Enregistrer'),
                          ),
                        ],
                      );
                    },
                  );
                  if (save == true) {
                    await notes.upsertNote(verse.id, controller.text);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Partager (extrait)'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await shareService.shareVerseExcerpt(verse);
                  } catch (error) {
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(content: Text(error.toString())),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<ReadingPreferencesController>();

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: _hasPrev ? () => _goToChapter(_chapterNumber - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Center(
                  child: Text('Chapitre $_chapterNumber', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              IconButton(
                onPressed: _hasNext ? () => _goToChapter(_chapterNumber + 1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<BibleVerse>>(
            future: _versesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return AsyncStateView(
                  title: 'Erreur de lecture',
                  message: 'Impossible de charger ce chapitre.',
                  onRetry: _retryVerses,
                  error: snapshot.error,
                  stackTrace: snapshot.stackTrace,
                );
              }

              final verses = snapshot.data;
              if (verses == null || verses.isEmpty) {
                return AsyncStateView(
                  icon: Icons.menu_book_outlined,
                  title: 'Aucun verset trouvé',
                  message: 'Aucun verset trouvé (DB vide ou requête incorrecte).',
                  onRetry: _retryVerses,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: verses.length,
                itemBuilder: (context, index) {
                  final verse = verses[index];
                  return InkWell(
                    onTap: () => _showVerseActions(verse),
                    onLongPress: () => _showVerseActions(verse),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: prefs.textSize,
                                height: prefs.lineHeight,
                              ),
                          children: [
                            TextSpan(
                              text: '${verse.verseNumber} ',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextSpan(text: verse.text),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookId} $_chapterNumber'),
        actions: [
          IconButton(
            tooltip: 'Réglages lecture',
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ReadingSettingsSheet(),
              );
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: body,
    );
  }
}
