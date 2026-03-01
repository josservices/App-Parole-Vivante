import 'package:flutter/foundation.dart';

import 'bible_data_source.dart';
import 'db/app_database.dart';
import 'json_bible_data_source.dart';
import 'sqlite_bible_data_source.dart';

BibleDataSource createBibleDataSource({AppDatabase? database}) {
  if (kIsWeb) {
    return JsonBibleDataSource();
  }
  return SqliteBibleDataSource(database: database);
}
