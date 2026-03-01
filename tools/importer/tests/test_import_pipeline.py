from __future__ import annotations

import sqlite3
import tempfile
import unittest
from pathlib import Path

from tools.importer.models import Book, Chapter, Verse
from tools.importer.sqlite_seed import seed_sqlite


def make_sample_books() -> list[Book]:
    book = Book(id="matthieu", ord=1, name="Matthieu", slug="matthieu", chapters=[])

    chapter1 = Chapter(id="matthieu-1", book_id="matthieu", number=1, verses=[])
    chapter1.verses.extend(
        [
            Verse(id="matthieu-1-1", book_id="matthieu", chapter_number=1, verse_number=1, text="Au commencement."),
            Verse(id="matthieu-1-2", book_id="matthieu", chapter_number=1, verse_number=2, text="Abraham eut pour descendant Isaac."),
            Verse(id="matthieu-1-3", book_id="matthieu", chapter_number=1, verse_number=3, text="Juda eut pour descendants.") ,
        ]
    )

    chapter2 = Chapter(id="matthieu-2", book_id="matthieu", number=2, verses=[])
    chapter2.verses.extend(
        [
            Verse(id="matthieu-2-1", book_id="matthieu", chapter_number=2, verse_number=1, text="Jesus naquit a Bethlehem."),
            Verse(id="matthieu-2-2", book_id="matthieu", chapter_number=2, verse_number=2, text="Ou est le roi des Juifs."),
            Verse(id="matthieu-2-3", book_id="matthieu", chapter_number=2, verse_number=3, text="Quand Herode apprit la nouvelle."),
        ]
    )

    book.chapters.extend([chapter1, chapter2])
    return [book]


class ImportPipelineDbTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = Path(self.temp_dir.name) / "bible.db"
        seed_sqlite(make_sample_books(), self.db_path)

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def _connect(self) -> sqlite3.Connection:
        return sqlite3.connect(self.db_path)

    def test_01_schema_tables_exist(self) -> None:
        with self._connect() as con:
            rows = con.execute(
                "SELECT name FROM sqlite_master WHERE type IN ('table','view')"
            ).fetchall()
        names = {name for (name,) in rows}
        self.assertIn("books", names)
        self.assertIn("chapters", names)
        self.assertIn("verses", names)
        self.assertIn("verses_fts", names)

    def test_02_required_indexes_exist(self) -> None:
        with self._connect() as con:
            verse_indexes = {name for (_, name, *_rest) in con.execute("PRAGMA index_list('verses')").fetchall()}
            chapter_indexes = {name for (_, name, *_rest) in con.execute("PRAGMA index_list('chapters')").fetchall()}
        self.assertIn("idx_verses_ref", verse_indexes)
        self.assertIn("idx_chapters", chapter_indexes)

    def test_03_counts_match_seed(self) -> None:
        with self._connect() as con:
            books = con.execute("SELECT COUNT(*) FROM books").fetchone()[0]
            chapters = con.execute("SELECT COUNT(*) FROM chapters").fetchone()[0]
            verses = con.execute("SELECT COUNT(*) FROM verses").fetchone()[0]
        self.assertEqual(books, 1)
        self.assertEqual(chapters, 2)
        self.assertEqual(verses, 6)

    def test_04_reference_query_returns_ordered_verses(self) -> None:
        with self._connect() as con:
            rows = con.execute(
                """
                SELECT verse_number, text
                FROM verses
                WHERE book_id = ? AND chapter_number = ?
                ORDER BY verse_number
                """,
                ("matthieu", 1),
            ).fetchall()
        self.assertEqual([r[0] for r in rows], [1, 2, 3])

    def test_05_fts_query_returns_expected_verse(self) -> None:
        with self._connect() as con:
            rows = con.execute(
                """
                SELECT v.id
                FROM verses_fts f
                JOIN verses v ON v.rowid = f.rowid
                WHERE verses_fts MATCH ?
                ORDER BY rank
                """,
                ("Bethlehem",),
            ).fetchall()
        self.assertTrue(any(row[0] == "matthieu-2-1" for row in rows))

    def test_06_favorites_table_accepts_existing_verse_id(self) -> None:
        with self._connect() as con:
            con.execute("PRAGMA foreign_keys = ON")
            con.execute("INSERT INTO favorites(verse_id) VALUES (?)", ("matthieu-1-1",))
            count = con.execute("SELECT COUNT(*) FROM favorites").fetchone()[0]
        self.assertEqual(count, 1)


if __name__ == "__main__":
    unittest.main()
