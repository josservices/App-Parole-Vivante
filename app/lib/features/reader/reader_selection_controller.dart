import 'package:flutter/foundation.dart';

import '../../domain/bible_models.dart';

class ReaderSelectionController extends ChangeNotifier {
  BibleBook? _selectedBook;
  int? _selectedChapter;

  BibleBook? get selectedBook => _selectedBook;
  String? get selectedBookId => _selectedBook?.id;
  String? get selectedBookName => _selectedBook?.name;
  int? get selectedChapter => _selectedChapter;

  void selectBook(BibleBook book) {
    final changed = _selectedBook?.id != book.id;
    _selectedBook = book;
    if (changed) {
      _selectedChapter = null;
    }
    notifyListeners();
  }

  void selectChapter(int chapterNumber) {
    if (_selectedChapter == chapterNumber) {
      return;
    }
    _selectedChapter = chapterNumber;
    notifyListeners();
  }

  void clearSelection() {
    _selectedBook = null;
    _selectedChapter = null;
    notifyListeners();
  }
}
