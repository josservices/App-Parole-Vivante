import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/search_repository.dart';
import '../../domain/bible_models.dart';
import '../common/async_state_view.dart';
import '../reader/chapter_reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const Duration _searchTimeout = Duration(seconds: 8);
  static const int _searchResultLimit = SearchRepository.defaultSearchLimit;
  final _controller = TextEditingController();
  List<SearchResultVerse> _results = const [];
  bool _loading = false;
  bool _hasSearched = false;
  bool _showSimpleLimitHint = false;
  String? _errorMessage;
  Object? _error;
  StackTrace? _stackTrace;

  Future<void> _search() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _results = const [];
        _hasSearched = false;
        _showSimpleLimitHint = false;
        _errorMessage = null;
        _error = null;
        _stackTrace = null;
      });
      return;
    }

    final repository = context.read<SearchRepository>();

    setState(() {
      _loading = true;
      _errorMessage = null;
      _error = null;
      _stackTrace = null;
    });

    try {
      final ref = await repository.searchReference(input).timeout(_searchTimeout);
      if (ref != null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _hasSearched = true;
          _showSimpleLimitHint = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChapterReaderScreen(
              bookId: ref.bookId,
              chapterNumber: ref.chapterNumber,
            ),
          ),
        );
        return;
      }

      final rows = await repository
          .fullTextSearch(input, limit: _searchResultLimit)
          .timeout(_searchTimeout);
      if (!mounted) return;

      setState(() {
        _results = rows;
        _loading = false;
        _hasSearched = true;
        _showSimpleLimitHint =
            repository.usesSimpleSearch && rows.length >= _searchResultLimit;
      });
    } on TimeoutException catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _loading = false;
        _hasSearched = true;
        _showSimpleLimitHint = false;
        _errorMessage = 'La recherche a expiré. Vérifiez la base locale puis réessayez.';
        _error = error;
        _stackTrace = stackTrace;
      });
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _loading = false;
        _hasSearched = true;
        _showSimpleLimitHint = false;
        _errorMessage = 'Impossible d’exécuter la recherche.';
        _error = error;
        _stackTrace = stackTrace;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Ex: Matthieu 5:3 ou mot-clé',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _search,
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_hasSearched && _showSimpleLimitHint)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                'Mode Web JSON: recherche simple limitée aux $_searchResultLimit premiers résultats.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error != null) {
                  return AsyncStateView(
                    title: 'Erreur de recherche',
                    message: _errorMessage ?? 'Impossible d’exécuter la recherche.',
                    onRetry: _search,
                    error: _error,
                    stackTrace: _stackTrace,
                  );
                }
                if (_hasSearched && _results.isEmpty) {
                  return AsyncStateView(
                    icon: Icons.search_off,
                    title: 'Aucun résultat',
                    message: 'Aucun résultat trouvé (DB vide ou requête incorrecte).',
                    onRetry: _search,
                  );
                }
                return ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return ListTile(
                      title: Text('${item.bookId} ${item.chapterNumber}:${item.verseNumber}'),
                      subtitle: Text(item.text),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChapterReaderScreen(
                              bookId: item.bookId,
                              chapterNumber: item.chapterNumber,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
