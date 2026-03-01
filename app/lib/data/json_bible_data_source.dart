import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import '../domain/bible_models.dart';
import 'bible_data_source.dart';

class JsonBibleDataSource implements BibleDataSource {
  static const String _assetPath = 'assets/bible.parolevivante.nt.json';

  final List<BibleBook> _books = <BibleBook>[];
  final Map<String, List<int>> _chaptersByBook = <String, List<int>>{};
  final Map<String, Map<int, List<BibleVerse>>> _versesByBookChapter =
      <String, Map<int, List<BibleVerse>>>{};
  final Map<String, BibleVerse> _verseByRef = <String, BibleVerse>{};
  final List<_SearchEntry> _searchEntries = <_SearchEntry>[];

  Future<void>? _loadFuture;
  ReadingProgress? _readingProgress;

  @override
  bool get usesSimpleSearch => true;

  Future<void> _ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON Bible invalide: racine non supportée.');
    }

    final booksNode = decoded['books'];
    if (booksNode is! List) {
      throw const FormatException('JSON Bible invalide: clé "books" absente.');
    }

    var order = 0;
    for (final bookNode in booksNode) {
      if (bookNode is! Map<String, dynamic>) {
        continue;
      }
      final bookId = _asString(bookNode['id']);
      if (bookId.isEmpty) {
        continue;
      }

      final book = BibleBook(
        id: bookId,
        ord: _asInt(bookNode['ord'], fallback: ++order),
        name: _asString(bookNode['name']),
        slug: _asString(bookNode['slug']),
      );
      _books.add(book);

      final chapters = <int>[];
      final chapterMap = <int, List<BibleVerse>>{};
      final chaptersNode = bookNode['chapters'];
      if (chaptersNode is List) {
        for (final chapterNode in chaptersNode) {
          if (chapterNode is! Map<String, dynamic>) {
            continue;
          }

          final chapterNumber = _asInt(chapterNode['number']);
          if (chapterNumber <= 0) {
            continue;
          }

          final verses = <BibleVerse>[];
          final versesNode = chapterNode['verses'];
          if (versesNode is List) {
            for (final verseNode in versesNode) {
              if (verseNode is! Map<String, dynamic>) {
                continue;
              }

              final verseNumber =
                  _asInt(verseNode['verse_number']) > 0
                      ? _asInt(verseNode['verse_number'])
                      : 0;
              if (verseNumber <= 0) {
                continue;
              }

              final verseBookId = _asString(verseNode['book_id']);
              final normalizedBookId =
                  verseBookId.isNotEmpty ? verseBookId : bookId;
              final normalizedChapter =
                  _asInt(verseNode['chapter_number']) > 0
                      ? _asInt(verseNode['chapter_number'])
                      : chapterNumber;

              final verse = BibleVerse(
                id: _asString(verseNode['id']),
                bookId: normalizedBookId,
                chapterNumber: normalizedChapter,
                verseNumber: verseNumber,
                text: _asString(verseNode['text']),
              );

              verses.add(verse);
              _verseByRef[_refKey(
                verse.bookId,
                verse.chapterNumber,
                verse.verseNumber,
              )] = verse;
              _searchEntries.add(
                _SearchEntry(
                  verse: verse,
                  normalizedText: verse.text.toLowerCase(),
                  canonicalIndex: _searchEntries.length,
                ),
              );
            }
          }

          verses.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
          chapters.add(chapterNumber);
          chapterMap[chapterNumber] = List<BibleVerse>.unmodifiable(verses);
        }
      }

      chapters.sort();
      _chaptersByBook[bookId] = List<int>.unmodifiable(chapters);
      _versesByBookChapter[bookId] = chapterMap;
    }

    _books.sort((a, b) => a.ord.compareTo(b.ord));
  }

  @override
  Future<List<BibleBook>> getBooks() async {
    await _ensureLoaded();
    return List<BibleBook>.unmodifiable(_books);
  }

  @override
  Future<List<int>> getChapters(String bookId) async {
    await _ensureLoaded();
    return _chaptersByBook[bookId] ?? const <int>[];
  }

  @override
  Future<List<BibleVerse>> getVerses(String bookId, int chapterNumber) async {
    await _ensureLoaded();
    final chapterMap = _versesByBookChapter[bookId];
    if (chapterMap == null) {
      return const <BibleVerse>[];
    }
    return chapterMap[chapterNumber] ?? const <BibleVerse>[];
  }

  @override
  Future<BibleVerse?> getVerseByRef(
    String bookId,
    int chapterNumber,
    int verseNumber,
  ) async {
    await _ensureLoaded();
    return _verseByRef[_refKey(bookId, chapterNumber, verseNumber)];
  }

  @override
  Future<List<SearchResultVerse>> search(String query, {int limit = 100}) async {
    await _ensureLoaded();

    final cleaned = query.trim().toLowerCase();
    if (cleaned.isEmpty) {
      return const <SearchResultVerse>[];
    }

    final hits = <_SearchHit>[];
    for (final entry in _searchEntries) {
      final matchIndex = entry.normalizedText.indexOf(cleaned);
      if (matchIndex < 0) {
        continue;
      }
      hits.add(_SearchHit(entry: entry, score: matchIndex));
    }

    hits.sort((a, b) {
      final byScore = a.score.compareTo(b.score);
      if (byScore != 0) {
        return byScore;
      }
      return a.entry.canonicalIndex.compareTo(b.entry.canonicalIndex);
    });

    return hits
        .take(limit)
        .map(
          (hit) => SearchResultVerse(
            id: hit.entry.verse.id,
            bookId: hit.entry.verse.bookId,
            chapterNumber: hit.entry.verse.chapterNumber,
            verseNumber: hit.entry.verse.verseNumber,
            text: hit.entry.verse.text,
            highlight: _buildExcerpt(hit.entry.verse.text, cleaned, hit.score),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveReadingProgress(String bookId, int chapterNumber) async {
    _readingProgress = ReadingProgress(
      bookId: bookId,
      chapterNumber: chapterNumber,
    );
  }

  @override
  Future<ReadingProgress?> getReadingProgress() async {
    return _readingProgress;
  }

  int _asInt(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  String _asString(Object? value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  String _refKey(String bookId, int chapterNumber, int verseNumber) {
    return '$bookId-$chapterNumber-$verseNumber';
  }

  String _buildExcerpt(String text, String query, int matchIndex) {
    if (text.length <= 140 || matchIndex < 0) {
      return text;
    }

    final start = math.max(0, matchIndex - 50);
    final end = math.min(text.length, matchIndex + query.length + 50);
    final prefix = start > 0 ? '... ' : '';
    final suffix = end < text.length ? ' ...' : '';

    return '$prefix${text.substring(start, end)}$suffix';
  }
}

class _SearchEntry {
  const _SearchEntry({
    required this.verse,
    required this.normalizedText,
    required this.canonicalIndex,
  });

  final BibleVerse verse;
  final String normalizedText;
  final int canonicalIndex;
}

class _SearchHit {
  const _SearchHit({required this.entry, required this.score});

  final _SearchEntry entry;
  final int score;
}
