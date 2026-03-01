import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/bible_repository.dart';
import '../../domain/bible_models.dart';
import '../chapters/chapters_screen.dart';
import '../common/async_state_view.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({
    super.key,
    this.onSelectBook,
    this.showScaffold = true,
  });

  final ValueChanged<BibleBook>? onSelectBook;
  final bool showScaffold;

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const Duration _loadTimeout = Duration(seconds: 8);
  late Future<List<BibleBook>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = _loadBooks();
  }

  Future<List<BibleBook>> _loadBooks() {
    final repo = context.read<BibleRepository>();
    return repo.getBooks().timeout(_loadTimeout);
  }

  void _retry() {
    setState(() {
      _booksFuture = _loadBooks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<BibleBook>>(
      future: _booksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return AsyncStateView(
            title: 'Erreur de chargement',
            message: 'Impossible de charger les livres du NT.',
            onRetry: _retry,
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
        }

        final books = snapshot.data;
        if (books == null || books.isEmpty) {
          return AsyncStateView(
            icon: Icons.menu_book_outlined,
            title: 'Aucun livre trouvé',
            message: 'Aucun livre trouvé (DB vide ou requête incorrecte).',
            onRetry: _retry,
          );
        }
        return ListView.separated(
          itemCount: books.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final book = books[index];
            return ListTile(
              leading: CircleAvatar(child: Text(book.ord.toString())),
              title: Text(book.name),
              subtitle: Text(book.id),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                if (widget.onSelectBook != null) {
                  widget.onSelectBook!(book);
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChaptersScreen(book: book),
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
      appBar: AppBar(title: const Text('Livres du Nouveau Testament')),
      body: body,
    );
  }
}
