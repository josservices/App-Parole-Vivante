from __future__ import annotations

from dataclasses import dataclass
import re
from typing import Iterable

from .config import SampleFilter
from .models import Anomaly, Book, Chapter, Verse
from .nt_books import BookSpec, iter_books, resolve_book_alias
from .text_normalize import append_text, clean_verse_text, is_colon_marker, is_page_number, normalize_for_match, normalize_line


CHAPTER_ONLY_RE = re.compile(r"^\s*(\d{1,3})\s*$")
CHAPTER_INLINE_RE = re.compile(r"^\s*(\d{1,3})\s+(.+)$")
VERSE_START_RE = re.compile(r"^\s*(\d{1,3})\s+(.+)$")
DASHED_VERSE_START_RE = re.compile(r"^\s*—\s*(\d{1,3})\s+(.+)$")
INLINE_VERSE_RE = re.compile(r"(?<=[\.!?;:])\s+(\d{1,3})\s+(?=[A-ZÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸ«(—])")


@dataclass
class ParseState:
    books: list[Book]
    anomalies: list[Anomaly]
    current_book: Book | None = None
    current_book_spec: BookSpec | None = None
    current_chapter: Chapter | None = None
    current_verse: Verse | None = None
    expected_book_index: int = 0
    pending_book_boundary: bool = False

    def anomaly(self, code: str, message: str, **context: object) -> None:
        self.anomalies.append(Anomaly(code=code, message=message, context=context))

    @property
    def current_verse_number(self) -> int:
        if self.current_verse is None:
            return 0
        return self.current_verse.verse_number


def _chapter_start_is_plausible(
    candidate: int,
    state: ParseState,
    line: str,
    leading_spaces: int,
    is_inline: bool,
) -> bool:
    if candidate < 1 or candidate > 150:
        return False

    if state.current_book_spec is not None and candidate > state.current_book_spec.chapter_count:
        return False

    if state.current_chapter is None:
        return True

    current_chapter = state.current_chapter.number
    if candidate != current_chapter + 1:
        return False

    if state.current_verse_number >= 5:
        if is_inline:
            return leading_spaces <= 1
        return True

    # Inline chapter headings usually contain wider spacing after the chapter number.
    return bool(re.match(r"^\s*\d{1,3}\s{2,}\S", line)) and leading_spaces <= 1


def _lookahead_supports_new_chapter(lines: list[str], current_index: int) -> bool:
    """
    Extra guard for standalone chapter numbers.
    Accept if we quickly see verse 1 after optional short section headings.
    """
    for offset in range(current_index + 1, min(current_index + 8, len(lines))):
        probe = normalize_line(lines[offset])
        if not probe:
            continue
        if is_page_number(probe):
            continue
        if _is_short_section_heading(probe):
            continue

        verse_match = VERSE_START_RE.match(probe)
        if verse_match and int(verse_match.group(1)) == 1:
            return True

        # If content starts with dialogue or continuation immediately, this is
        # likely a page number, not a new chapter marker.
        if probe.startswith("—"):
            return False
        return False
    return False


def _is_short_section_heading(line: str) -> bool:
    if not line:
        return False
    if line.startswith("—"):
        return False
    if any(ch.isdigit() for ch in line):
        return False
    if any(p in line for p in ".,;:!?"):
        return False
    words = [w for w in line.split(" ") if w]
    if len(words) == 0:
        return False
    if len(words) <= 5 and len(line) <= 80:
        return True
    return False


def _split_inline_markers(text: str) -> list[tuple[int | None, str]]:
    markers = list(INLINE_VERSE_RE.finditer(text))
    if not markers:
        return [(None, text)] if text else []

    items: list[tuple[int | None, str]] = []
    cursor = 0
    for index, match in enumerate(markers):
        prefix = text[cursor : match.start()]
        if prefix.strip():
            items.append((None, prefix))

        verse_num = int(match.group(1))
        next_start = markers[index + 1].start() if index + 1 < len(markers) else len(text)
        verse_text = text[match.end() : next_start]
        items.append((verse_num, verse_text))
        cursor = next_start

    tail = text[cursor:]
    if tail.strip() and (not items or items[-1][0] is not None):
        items.append((None, tail))
    return items


def _start_book(state: ParseState, spec: BookSpec) -> None:
    state.current_book_spec = spec
    state.current_book = Book(
        id=spec.id,
        ord=spec.ord,
        name=spec.name,
        slug=spec.id,
        chapters=[],
    )
    state.books.append(state.current_book)
    state.current_chapter = None
    state.current_verse = None


def _start_chapter(state: ParseState, chapter_number: int, source_line: int) -> None:
    if state.current_book is None:
        state.anomaly(
            "chapter_without_book",
            "Chapitre détecté sans livre actif.",
            line=source_line,
            chapter_number=chapter_number,
        )
        return

    for chapter in state.current_book.chapters:
        if chapter.number == chapter_number:
            state.current_chapter = chapter
            state.current_verse = chapter.verses[-1] if chapter.verses else None
            state.anomaly(
                "duplicate_chapter",
                "Chapitre dupliqué détecté, réutilisation du chapitre existant.",
                line=source_line,
                book_id=state.current_book.id,
                chapter_number=chapter_number,
            )
            return

    chapter = Chapter(
        id=f"{state.current_book.id}-{chapter_number}",
        book_id=state.current_book.id,
        number=chapter_number,
        verses=[],
    )
    state.current_book.chapters.append(chapter)
    state.current_chapter = chapter
    state.current_verse = None


def _append_to_current_verse(state: ParseState, text: str, source_line: int) -> None:
    text = clean_verse_text(text)
    if not text:
        return

    if state.current_chapter is None:
        state.anomaly(
            "text_without_chapter",
            "Texte ignoré car aucun chapitre n'est actif.",
            line=source_line,
            text=text[:80],
        )
        return

    if state.current_verse is None:
        verse = Verse(
            id=f"{state.current_chapter.book_id}-{state.current_chapter.number}-1",
            book_id=state.current_chapter.book_id,
            chapter_number=state.current_chapter.number,
            verse_number=1,
            text=text,
        )
        state.current_chapter.verses.append(verse)
        state.current_verse = verse
        return

    state.current_verse.text = clean_verse_text(append_text(state.current_verse.text, text))


def _start_verse(state: ParseState, verse_number: int, text: str, source_line: int) -> None:
    if state.current_chapter is None:
        # Last-resort fallback: create chapter 1.
        _start_chapter(state, 1, source_line=source_line)
        state.anomaly(
            "implicit_chapter",
            "Chapitre implicite créé faute de chapitre détecté.",
            line=source_line,
            verse_number=verse_number,
        )

    if state.current_chapter is None:
        return

    if verse_number < 1 or verse_number > 200:
        state.anomaly(
            "invalid_verse_number",
            "Numéro de verset invalide ignoré.",
            line=source_line,
            verse_number=verse_number,
            chapter_number=state.current_chapter.number,
        )
        return

    if state.current_verse is not None and verse_number <= state.current_verse.verse_number:
        state.anomaly(
            "non_increasing_verse",
            "Numérotation de versets non strictement croissante.",
            line=source_line,
            book_id=state.current_chapter.book_id,
            chapter_number=state.current_chapter.number,
            previous_verse=state.current_verse.verse_number,
            current_verse=verse_number,
        )
        _append_to_current_verse(state, f"{verse_number} {text}", source_line=source_line)
        return

    verse = Verse(
        id=f"{state.current_chapter.book_id}-{state.current_chapter.number}-{verse_number}",
        book_id=state.current_chapter.book_id,
        chapter_number=state.current_chapter.number,
        verse_number=verse_number,
        text=clean_verse_text(text),
    )
    state.current_chapter.verses.append(verse)
    state.current_verse = verse


def _consume_verse_text_with_inline(state: ParseState, base_verse_number: int, text: str, source_line: int) -> None:
    fragments = _split_inline_markers(text)
    if not fragments:
        _start_verse(state, base_verse_number, text, source_line=source_line)
        return

    first_is_cont = fragments[0][0] is None
    if first_is_cont:
        _start_verse(state, base_verse_number, fragments[0][1], source_line=source_line)
        tail = fragments[1:]
    else:
        _start_verse(state, base_verse_number, "", source_line=source_line)
        tail = fragments

    for maybe_num, frag_text in tail:
        if maybe_num is None:
            _append_to_current_verse(state, frag_text, source_line=source_line)
        else:
            _start_verse(state, maybe_num, frag_text, source_line=source_line)


def _consume_continuation_or_inline(state: ParseState, line: str, source_line: int) -> None:
    fragments = _split_inline_markers(line)
    if not fragments:
        return
    for maybe_num, frag_text in fragments:
        if maybe_num is None:
            _append_to_current_verse(state, frag_text, source_line=source_line)
        else:
            _start_verse(state, maybe_num, frag_text, source_line=source_line)


def parse_nt_text(raw_text: str) -> tuple[list[Book], list[Anomaly]]:
    lines = raw_text.splitlines()
    state = ParseState(books=[], anomalies=[])
    expected_books = list(iter_books())

    for index, raw_line in enumerate(lines):
        line_no = index + 1
        raw_without_formfeed = raw_line.replace("\f", "")
        raw_without_formfeed = raw_without_formfeed.replace("\u00a0", " ")
        leading_spaces = len(raw_without_formfeed) - len(raw_without_formfeed.lstrip(" "))
        line = normalize_line(raw_line)

        if not line:
            continue

        if is_colon_marker(line):
            state.pending_book_boundary = True
            continue

        if state.pending_book_boundary:
            if state.expected_book_index >= len(expected_books):
                # End of biblical text (index / notes start right after Apocalypse marker).
                normalized = normalize_for_match(line)
                if "index des" in normalized or "cartes geographiques" in normalized:
                    break
            else:
                expected = expected_books[state.expected_book_index]
                snippet = " ".join(
                    normalize_line(lines[offset])
                    for offset in range(index, min(index + 3, len(lines)))
                    if normalize_line(lines[offset])
                )
                if expected.matches_heading(snippet):
                    _start_book(state, expected)
                    state.expected_book_index += 1
                    state.pending_book_boundary = False
                    continue

        if state.current_book is None:
            continue

        if state.current_book.id == "apocalypse" and "index des" in normalize_for_match(line):
            break

        # Chapter number alone on its own line.
        chapter_only = CHAPTER_ONLY_RE.match(line)
        if chapter_only:
            candidate = int(chapter_only.group(1))
            plausible = _chapter_start_is_plausible(
                candidate,
                state,
                line,
                leading_spaces=leading_spaces,
                is_inline=False,
            )
            if (
                not plausible
                and state.current_chapter is not None
                and candidate == state.current_chapter.number + 1
                and _lookahead_supports_new_chapter(lines, index)
            ):
                plausible = True
            if plausible:
                _start_chapter(state, candidate, source_line=line_no)
                continue

        # Chapter number + text on the same line (common in this PDF).
        chapter_inline = CHAPTER_INLINE_RE.match(line)
        if chapter_inline:
            candidate = int(chapter_inline.group(1))
            if _chapter_start_is_plausible(
                candidate,
                state,
                line,
                leading_spaces=leading_spaces,
                is_inline=True,
            ):
                _start_chapter(state, candidate, source_line=line_no)
                rest = chapter_inline.group(2).strip()
                if rest:
                    _start_verse(state, 1, rest, source_line=line_no)
                continue

        if is_page_number(line):
            continue

        if state.current_chapter is None:
            continue

        # Skip one-line section titles like "Réfugiés", "Envoi", etc.
        if _is_short_section_heading(line):
            if state.current_verse is None:
                continue
            should_skip_heading = False
            for look in range(index + 1, min(index + 6, len(lines))):
                probe = normalize_line(lines[look])
                if not probe:
                    continue
                if is_page_number(probe):
                    continue
                probe_verse = VERSE_START_RE.match(probe)
                if probe_verse and int(probe_verse.group(1)) > state.current_verse_number:
                    should_skip_heading = True
                break
            if should_skip_heading:
                continue
            if state.current_verse.text and not state.current_verse.text.endswith("-"):
                if state.current_verse.text.endswith((".", "!", "?", ":", "»")):
                    continue

        # Standard verse start at beginning of line.
        dashed_verse_match = DASHED_VERSE_START_RE.match(line)
        if dashed_verse_match:
            verse_number = int(dashed_verse_match.group(1))
            text_part = f"— {dashed_verse_match.group(2).strip()}"
            _consume_verse_text_with_inline(
                state,
                base_verse_number=verse_number,
                text=text_part,
                source_line=line_no,
            )
            continue

        verse_match = VERSE_START_RE.match(line)
        if verse_match:
            verse_number = int(verse_match.group(1))
            text_part = verse_match.group(2).strip()

            # Fallback for rare implicit new chapter when extraction loses chapter marker.
            if (
                state.current_chapter is not None
                and verse_number == 1
                and state.current_verse_number >= 5
                and state.current_book_spec is not None
                and state.current_chapter.number < state.current_book_spec.chapter_count
            ):
                _start_chapter(state, state.current_chapter.number + 1, source_line=line_no)

            _consume_verse_text_with_inline(
                state,
                base_verse_number=verse_number,
                text=text_part,
                source_line=line_no,
            )
            continue

        _consume_continuation_or_inline(state, line=line, source_line=line_no)

    if state.expected_book_index < len(expected_books):
        missing_ids = [book.id for book in expected_books[state.expected_book_index :]]
        state.anomaly(
            "missing_books",
            "Tous les livres du NT n'ont pas été détectés.",
            missing_books=missing_ids,
        )

    return state.books, state.anomalies


def apply_sample_filter(books: Iterable[Book], sample: SampleFilter | None) -> list[Book]:
    if sample is None:
        return list(books)

    resolved = resolve_book_alias(sample.book_id)
    if not resolved:
        raise ValueError(
            f"Livre inconnu pour --sample: '{sample.book_id}'. Exemple attendu: matthieu:1-3"
        )

    filtered: list[Book] = []
    for book in books:
        if book.id != resolved.id:
            continue

        kept_chapters: list[Chapter] = []
        for chapter in book.chapters:
            if sample.start_chapter is not None and chapter.number < sample.start_chapter:
                continue
            if sample.end_chapter is not None and chapter.number > sample.end_chapter:
                continue
            kept_chapters.append(chapter)

        filtered.append(
            Book(
                id=book.id,
                ord=book.ord,
                name=book.name,
                slug=book.slug,
                chapters=kept_chapters,
            )
        )

    if not filtered:
        raise ValueError(
            f"--sample '{sample.book_id}' ne correspond à aucun livre détecté dans le PDF."
        )

    return filtered
