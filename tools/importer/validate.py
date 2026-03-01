from __future__ import annotations

from dataclasses import dataclass

from .models import Anomaly, Book
from .nt_books import get_book_by_id


@dataclass(frozen=True)
class ImportStats:
    books: int
    chapters: int
    verses: int
    anomalies: int

    def to_dict(self) -> dict[str, int]:
        return {
            "books": self.books,
            "chapters": self.chapters,
            "verses": self.verses,
            "anomalies": self.anomalies,
        }


def _append_anomaly(anomalies: list[Anomaly], code: str, message: str, **context: object) -> None:
    anomalies.append(Anomaly(code=code, message=message, context=context))


def validate_books(books: list[Book], anomalies: list[Anomaly]) -> tuple[ImportStats, list[Anomaly]]:
    out = list(anomalies)

    chapter_count_total = 0
    verse_count_total = 0

    for book in books:
        if not book.chapters:
            _append_anomaly(
                out,
                "empty_book",
                "Livre détecté sans chapitre.",
                book_id=book.id,
                book_name=book.name,
            )
            continue

        chapter_count_total += len(book.chapters)

        expected = get_book_by_id(book.id)
        if expected and len(book.chapters) != expected.chapter_count:
            _append_anomaly(
                out,
                "chapter_count_mismatch",
                "Nombre de chapitres différent du canon attendu.",
                book_id=book.id,
                expected=expected.chapter_count,
                actual=len(book.chapters),
            )

        chapter_numbers = [chapter.number for chapter in book.chapters]
        expected_sequence = list(range(1, max(chapter_numbers) + 1))
        if chapter_numbers != expected_sequence:
            missing = sorted(set(expected_sequence) - set(chapter_numbers))
            if missing:
                _append_anomaly(
                    out,
                    "chapter_gaps",
                    "Trous détectés dans la numérotation des chapitres.",
                    book_id=book.id,
                    missing=missing,
                )

        for chapter in book.chapters:
            if not chapter.verses:
                _append_anomaly(
                    out,
                    "empty_chapter",
                    "Chapitre sans versets.",
                    book_id=book.id,
                    chapter_number=chapter.number,
                )
                continue

            verse_count_total += len(chapter.verses)

            verse_numbers = [verse.verse_number for verse in chapter.verses]
            if verse_numbers != sorted(verse_numbers):
                _append_anomaly(
                    out,
                    "verse_order_invalid",
                    "Numérotation des versets non triée.",
                    book_id=book.id,
                    chapter_number=chapter.number,
                )

            for prev, curr in zip(verse_numbers, verse_numbers[1:]):
                if curr <= prev:
                    _append_anomaly(
                        out,
                        "verse_not_increasing",
                        "Numérotation des versets non strictement croissante.",
                        book_id=book.id,
                        chapter_number=chapter.number,
                        previous=prev,
                        current=curr,
                    )
                elif curr != prev + 1:
                    _append_anomaly(
                        out,
                        "verse_gap",
                        "Trou détecté dans la numérotation des versets.",
                        book_id=book.id,
                        chapter_number=chapter.number,
                        previous=prev,
                        current=curr,
                    )

            if len(chapter.verses) < 5:
                _append_anomaly(
                    out,
                    "chapter_short",
                    "Chapitre contenant moins de 5 versets (vérification recommandée).",
                    book_id=book.id,
                    chapter_number=chapter.number,
                    verse_count=len(chapter.verses),
                )

    stats = ImportStats(
        books=len(books),
        chapters=chapter_count_total,
        verses=verse_count_total,
        anomalies=len(out),
    )
    return stats, out
