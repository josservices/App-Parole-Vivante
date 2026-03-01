from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Iterable

from .text_normalize import normalize_for_match


@dataclass(frozen=True)
class BookSpec:
    id: str
    ord: int
    name: str
    chapter_count: int
    heading_patterns: tuple[str, ...]
    aliases: tuple[str, ...] = ()

    def matches_heading(self, heading_snippet: str) -> bool:
        normalized = normalize_for_match(heading_snippet)
        for pattern in self.heading_patterns:
            if re.search(pattern, normalized):
                return True
        return False


BOOK_SPECS: tuple[BookSpec, ...] = (
    BookSpec(
        id="matthieu",
        ord=1,
        name="Matthieu",
        chapter_count=28,
        heading_patterns=(r"la vie de jesus racontee par\s+matthieu",),
        aliases=("matthieu",),
    ),
    BookSpec(
        id="marc",
        ord=2,
        name="Marc",
        chapter_count=16,
        heading_patterns=(r"la vie de jesus racontee par\s+marc",),
        aliases=("marc",),
    ),
    BookSpec(
        id="luc",
        ord=3,
        name="Luc",
        chapter_count=24,
        heading_patterns=(r"la vie de jesus racontee par\s+luc",),
        aliases=("luc",),
    ),
    BookSpec(
        id="jean",
        ord=4,
        name="Jean",
        chapter_count=21,
        heading_patterns=(r"la vie de jesus racontee par\s+jean",),
        aliases=("jean",),
    ),
    BookSpec(
        id="actes",
        ord=5,
        name="Actes",
        chapter_count=28,
        heading_patterns=(r"actes d[’']?apotres", r"eglise primitive.*actes"),
        aliases=("actes", "actes-dapotres", "actes-d-apotres"),
    ),
    BookSpec(
        id="romains",
        ord=6,
        name="Romains",
        chapter_count=16,
        heading_patterns=(r"lettre aux chretiens de\s+rome",),
        aliases=("romains", "rome"),
    ),
    BookSpec(
        id="1-corinthiens",
        ord=7,
        name="1 Corinthiens",
        chapter_count=16,
        heading_patterns=(r"premiere lettre aux chretiens de\s+corinthe",),
        aliases=("1-corinthiens", "premiere-corinthiens", "1corinthiens"),
    ),
    BookSpec(
        id="2-corinthiens",
        ord=8,
        name="2 Corinthiens",
        chapter_count=13,
        heading_patterns=(r"deuxieme lettre aux chretiens de\s+corinthe",),
        aliases=("2-corinthiens", "deuxieme-corinthiens", "2corinthiens"),
    ),
    BookSpec(
        id="galates",
        ord=9,
        name="Galates",
        chapter_count=6,
        heading_patterns=(r"lettre aux eglises de la\s+galatie",),
        aliases=("galates",),
    ),
    BookSpec(
        id="ephesiens",
        ord=10,
        name="Éphésiens",
        chapter_count=6,
        heading_patterns=(r"lettre aux eglises de la region d[’']?ephese",),
        aliases=("ephesiens", "ephesiens", "ephese"),
    ),
    BookSpec(
        id="philippiens",
        ord=11,
        name="Philippiens",
        chapter_count=4,
        heading_patterns=(r"lettre a l[’']?eglise de\s+philippes",),
        aliases=("philippiens", "philippes"),
    ),
    BookSpec(
        id="colossiens",
        ord=12,
        name="Colossiens",
        chapter_count=4,
        heading_patterns=(r"lettre a l[’']?eglise de\s+colosses",),
        aliases=("colossiens", "colosses"),
    ),
    BookSpec(
        id="1-thessaloniciens",
        ord=13,
        name="1 Thessaloniciens",
        chapter_count=5,
        heading_patterns=(r"premiere lettre a l[’']?eglise de\s+thessalonique",),
        aliases=("1-thessaloniciens", "1thessaloniciens", "premiere-thessaloniciens"),
    ),
    BookSpec(
        id="2-thessaloniciens",
        ord=14,
        name="2 Thessaloniciens",
        chapter_count=3,
        heading_patterns=(r"deuxieme lettre a l[’']?eglise de\s+thessalonique",),
        aliases=("2-thessaloniciens", "2thessaloniciens", "deuxieme-thessaloniciens"),
    ),
    BookSpec(
        id="1-timothee",
        ord=15,
        name="1 Timothée",
        chapter_count=6,
        heading_patterns=(r"premiere lettre a\s+timothee",),
        aliases=("1-timothee", "1timothee", "premiere-timothee"),
    ),
    BookSpec(
        id="2-timothee",
        ord=16,
        name="2 Timothée",
        chapter_count=4,
        heading_patterns=(r"deuxieme lettre a\s+timothee",),
        aliases=("2-timothee", "2timothee", "deuxieme-timothee"),
    ),
    BookSpec(
        id="tite",
        ord=17,
        name="Tite",
        chapter_count=3,
        heading_patterns=(r"lettre a son collaborateur\s+tite",),
        aliases=("tite",),
    ),
    BookSpec(
        id="philemon",
        ord=18,
        name="Philémon",
        chapter_count=1,
        heading_patterns=(r"lettre a son ami\s+philemon",),
        aliases=("philemon",),
    ),
    BookSpec(
        id="hebreux",
        ord=19,
        name="Hébreux",
        chapter_count=13,
        heading_patterns=(r"une lettre anonyme a des chretiens\s+hebreux",),
        aliases=("hebreux",),
    ),
    BookSpec(
        id="jacques",
        ord=20,
        name="Jacques",
        chapter_count=5,
        heading_patterns=(r"une lettre de\s+jacques",),
        aliases=("jacques",),
    ),
    BookSpec(
        id="1-pierre",
        ord=21,
        name="1 Pierre",
        chapter_count=5,
        heading_patterns=(r"premiere lettre de l[’']?apotre\s+pierre",),
        aliases=("1-pierre", "1pierre", "premiere-pierre"),
    ),
    BookSpec(
        id="2-pierre",
        ord=22,
        name="2 Pierre",
        chapter_count=3,
        heading_patterns=(r"deuxieme lettre de l[’']?apotre\s+pierre",),
        aliases=("2-pierre", "2pierre", "deuxieme-pierre"),
    ),
    BookSpec(
        id="1-jean",
        ord=23,
        name="1 Jean",
        chapter_count=5,
        heading_patterns=(r"premiere lettre de l[’']?apotre\s+jean",),
        aliases=("1-jean", "1jean", "premiere-jean"),
    ),
    BookSpec(
        id="2-jean",
        ord=24,
        name="2 Jean",
        chapter_count=1,
        heading_patterns=(r"deuxieme lettre de l[’']?apotre\s+jean",),
        aliases=("2-jean", "2jean", "deuxieme-jean"),
    ),
    BookSpec(
        id="3-jean",
        ord=25,
        name="3 Jean",
        chapter_count=1,
        heading_patterns=(r"troisieme lettre de l[’']?apotre\s+jean",),
        aliases=("3-jean", "3jean", "troisieme-jean"),
    ),
    BookSpec(
        id="jude",
        ord=26,
        name="Jude",
        chapter_count=1,
        heading_patterns=(r"une lettre de\s+jude",),
        aliases=("jude",),
    ),
    BookSpec(
        id="apocalypse",
        ord=27,
        name="Apocalypse",
        chapter_count=22,
        heading_patterns=(r"la fin des temps.*apocalypse", r"\bapocalypse\b"),
        aliases=("apocalypse", "apoc"),
    ),
)


_BOOK_BY_ID = {book.id: book for book in BOOK_SPECS}


def iter_books() -> Iterable[BookSpec]:
    return BOOK_SPECS


def get_book_by_id(book_id: str) -> BookSpec | None:
    return _BOOK_BY_ID.get(book_id)


def resolve_book_alias(raw_book: str) -> BookSpec | None:
    key = normalize_for_match(raw_book).replace(" ", "-")
    key = key.replace("'", "")
    for book in BOOK_SPECS:
        all_aliases = {book.id, *book.aliases, normalize_for_match(book.name).replace(" ", "-")}
        if key in {alias.replace("'", "") for alias in all_aliases}:
            return book
    return None
