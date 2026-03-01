PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS books(
  id TEXT PRIMARY KEY,
  ord INTEGER NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS chapters(
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  number INTEGER NOT NULL,
  FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS verses(
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  chapter_number INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  text TEXT NOT NULL,
  FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_verses_ref ON verses(book_id, chapter_number, verse_number);
CREATE INDEX IF NOT EXISTS idx_chapters ON chapters(book_id, number);

CREATE TABLE IF NOT EXISTS favorites(
  verse_id TEXT PRIMARY KEY,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(verse_id) REFERENCES verses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS highlights(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(verse_id) REFERENCES verses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  verse_id TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(verse_id) REFERENCES verses(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reading_progress(
  id INTEGER PRIMARY KEY CHECK(id = 1),
  book_id TEXT NOT NULL,
  chapter_number INTEGER NOT NULL,
  updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
);

CREATE VIRTUAL TABLE IF NOT EXISTS verses_fts USING fts5(
  text,
  content='verses',
  content_rowid='rowid',
  tokenize='unicode61 remove_diacritics 2'
);

CREATE TRIGGER IF NOT EXISTS verses_ai AFTER INSERT ON verses BEGIN
  INSERT INTO verses_fts(rowid, text) VALUES(new.rowid, new.text);
END;

CREATE TRIGGER IF NOT EXISTS verses_ad AFTER DELETE ON verses BEGIN
  INSERT INTO verses_fts(verses_fts, rowid, text) VALUES('delete', old.rowid, old.text);
END;

CREATE TRIGGER IF NOT EXISTS verses_au AFTER UPDATE ON verses BEGIN
  INSERT INTO verses_fts(verses_fts, rowid, text) VALUES('delete', old.rowid, old.text);
  INSERT INTO verses_fts(rowid, text) VALUES(new.rowid, new.text);
END;
