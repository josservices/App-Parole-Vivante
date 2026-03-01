import '../../domain/bible_models.dart';
import '../../services/reference_parser.dart';
import '../bible_data_source.dart';
import '../bible_data_source_factory.dart';
import '../db/app_database.dart';
import 'bible_repository.dart';

class SearchRepository {
  SearchRepository._({
    required BibleDataSource dataSource,
    required BibleRepository bibleRepository,
    required ReferenceParser referenceParser,
  })  : _dataSource = dataSource,
        _bibleRepository = bibleRepository,
        _referenceParser = referenceParser;

  factory SearchRepository({
    AppDatabase? database,
    BibleDataSource? dataSource,
    BibleRepository? bibleRepository,
    ReferenceParser? referenceParser,
  }) {
    final resolvedDatabase = database ?? AppDatabase.instance;
    final resolvedDataSource =
        dataSource ?? createBibleDataSource(database: resolvedDatabase);
    final resolvedBibleRepository =
        bibleRepository ??
        BibleRepository(
          database: resolvedDatabase,
          dataSource: resolvedDataSource,
        );

    return SearchRepository._(
      dataSource: resolvedDataSource,
      bibleRepository: resolvedBibleRepository,
      referenceParser: referenceParser ?? ReferenceParser(),
    );
  }

  static const int defaultSearchLimit = 100;

  final BibleDataSource _dataSource;
  final BibleRepository _bibleRepository;
  final ReferenceParser _referenceParser;

  bool get usesSimpleSearch => _dataSource.usesSimpleSearch;

  Future<List<SearchResultVerse>> fullTextSearch(
    String query, {
    int limit = defaultSearchLimit,
  }) async {
    final cleaned = query.trim();
    if (cleaned.isEmpty) {
      return const [];
    }
    return _dataSource.search(cleaned, limit: limit);
  }

  Future<BibleVerse?> searchReference(String input) async {
    final parsed = _referenceParser.parse(input);
    if (parsed == null) {
      return null;
    }

    if (parsed.verse != null) {
      return _dataSource.getVerseByRef(
        parsed.bookId,
        parsed.chapter,
        parsed.verse!,
      );
    }

    final verses = await _bibleRepository.getVerses(parsed.bookId, parsed.chapter);
    if (verses.isEmpty) {
      return null;
    }
    return verses.first;
  }
}
