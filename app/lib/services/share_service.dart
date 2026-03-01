import 'package:share_plus/share_plus.dart';

import '../domain/bible_models.dart';
import '../legal/legal_guard.dart';

class ShareService {
  Future<void> shareVerseExcerpt(BibleVerse verse) async {
    final excerpt = '${verse.bookId} ${verse.chapterNumber}:${verse.verseNumber}\n${verse.text}';
    LegalGuard.ensureShareExcerptAllowed(excerpt);

    await Share.share(excerpt, subject: 'Parole Vivante (extrait)');
  }
}
