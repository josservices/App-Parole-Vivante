import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/favorites_repository.dart';
import '../../data/repositories/highlights_repository.dart';
import '../../data/repositories/notes_repository.dart';
import '../../domain/bible_models.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bibliothèque personnelle'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Favoris'),
              Tab(text: 'Notes'),
              Tab(text: 'Surlignages'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FavoritesTab(),
            _NotesTab(),
            _HighlightsTab(),
          ],
        ),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<FavoritesRepository>();
    return FutureBuilder<List<BibleVerse>>(
      future: repo.listFavorites(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return const Center(child: Text('Aucun favori.'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final verse = rows[index];
            return ListTile(
              title: Text('${verse.bookId} ${verse.chapterNumber}:${verse.verseNumber}'),
              subtitle: Text(verse.text),
            );
          },
        );
      },
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<NotesRepository>();
    return FutureBuilder<List<NoteItem>>(
      future: repo.listNotes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return const Center(child: Text('Aucune note.'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final note = rows[index];
            return ListTile(
              title: Text(note.verseId),
              subtitle: Text(note.content),
            );
          },
        );
      },
    );
  }
}

class _HighlightsTab extends StatelessWidget {
  const _HighlightsTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HighlightsRepository>();
    return FutureBuilder<List<HighlightItem>>(
      future: repo.listHighlights(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) {
          return const Center(child: Text('Aucun surlignage.'));
        }
        return ListView.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final item = rows[index];
            return ListTile(
              title: Text(item.verseId),
              subtitle: Text('Couleur: ${item.color}'),
            );
          },
        );
      },
    );
  }
}
