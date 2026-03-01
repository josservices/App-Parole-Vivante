from __future__ import annotations

import unittest

from tools.importer.config import SampleFilter
from tools.importer.parse_nt import apply_sample_filter, parse_nt_text


def _join(lines: list[str]) -> str:
    return "\n".join(lines)


class ParserRulesTest(unittest.TestCase):
    def test_01_detects_first_book_from_boundary_heading(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 Tableau généalogique.",
                "2 Abraham eut pour descendant Isaac.",
            ]
        )
        books, _ = parse_nt_text(raw)
        self.assertEqual(len(books), 1)
        self.assertEqual(books[0].id, "matthieu")

    def test_02_chapter_detected_with_number_only_line(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 A",
                "2 B",
                "3 C",
                "4 D",
                "5 E",
                "6 F",
                "2",
                "1 Nouveau chapitre",
            ]
        )
        books, _ = parse_nt_text(raw)
        self.assertEqual(len(books[0].chapters), 2)
        self.assertEqual(books[0].chapters[1].number, 2)

    def test_03_chapter_detected_with_inline_number(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 A",
                "2 B",
                "3 C",
                "4 D",
                "5 E",
                "6 F",
                "2    Jésus naquit à Bethléhem.",
            ]
        )
        books, _ = parse_nt_text(raw)
        chapter_2 = books[0].chapters[1]
        self.assertEqual(chapter_2.number, 2)
        self.assertEqual(chapter_2.verses[0].verse_number, 1)
        self.assertIn("Jésus naquit", chapter_2.verses[0].text)

    def test_04_verse_start_then_continuation_is_concatenated(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 Ceci est un verset",
                "qui continue sur la ligne suivante.",
            ]
        )
        books, _ = parse_nt_text(raw)
        text = books[0].chapters[0].verses[0].text
        self.assertIn("ligne suivante", text)

    def test_05_dialogue_line_is_kept_in_current_verse(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 Jésus dit :",
                "— Suis-moi.",
            ]
        )
        books, _ = parse_nt_text(raw)
        self.assertIn("— Suis-moi", books[0].chapters[0].verses[0].text)

    def test_06_inline_verse_marker_after_sentence_is_split(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 Premier texte. 2 Deuxième texte.",
            ]
        )
        books, _ = parse_nt_text(raw)
        verses = books[0].chapters[0].verses
        self.assertEqual(len(verses), 2)
        self.assertEqual(verses[1].verse_number, 2)

    def test_07_footnote_marker_is_removed_from_text(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 Un texte avec marqueur 1234.",
            ]
        )
        books, _ = parse_nt_text(raw)
        text = books[0].chapters[0].verses[0].text
        self.assertNotIn("1234", text)

    def test_08_section_heading_is_ignored(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 Verset un",
                "Réfugiés",
                "2 Verset deux",
            ]
        )
        books, _ = parse_nt_text(raw)
        first = books[0].chapters[0].verses[0].text
        self.assertNotIn("Réfugiés", first)

    def test_09_hyphenated_line_break_is_joined_without_extra_hyphen(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 Saint-",
                "Esprit",
            ]
        )
        books, _ = parse_nt_text(raw)
        text = books[0].chapters[0].verses[0].text
        self.assertIn("SaintEsprit", text)

    def test_10_sample_filter_keeps_requested_book_and_range(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 V1",
                "2 V2",
                "3 V3",
                "4 V4",
                "5 V5",
                "6 V6",
                "2",
                "1 C2V1",
                "2 C2V2",
                "3",
                "1 C3V1",
            ]
        )
        books, _ = parse_nt_text(raw)
        filtered = apply_sample_filter(books, SampleFilter(book_id="matthieu", start_chapter=2, end_chapter=3))
        self.assertEqual(len(filtered), 1)
        self.assertEqual([c.number for c in filtered[0].chapters], [2, 3])

    def test_11_sample_filter_supports_alias(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 V1",
            ]
        )
        books, _ = parse_nt_text(raw)
        filtered = apply_sample_filter(books, SampleFilter(book_id="matthieu", start_chapter=1, end_chapter=1))
        self.assertEqual(filtered[0].id, "matthieu")

    def test_12_missing_books_anomaly_present_on_short_input(self) -> None:
        raw = _join(
            [
                "::::",
                "La vie de Jésus racontée par",
                "Matthieu",
                "1",
                "1 A",
            ]
        )
        _, anomalies = parse_nt_text(raw)
        codes = {a.code for a in anomalies}
        self.assertIn("missing_books", codes)


if __name__ == "__main__":
    unittest.main()
