from __future__ import annotations

import re
import unicodedata


COLON_MARKER_RE = re.compile(r"^\s*:[:\s]{3,}\s*$")
PAGE_NUMBER_RE = re.compile(r"^\s*\d{1,4}\s*$")

# Conservative removal of footnote markers (typically superscripts in the PDF extraction).
FOOTNOTE_RE = re.compile(r"(?<=[A-Za-zÀ-ÖØ-öø-ÿ\)])\s+\d{2,4}(?=(?:[\]\)\.,;:!?]|\s|$))")
MULTISPACE_RE = re.compile(r"\s+")


def normalize_for_match(text: str) -> str:
    text = text.replace("\u00a0", " ")
    text = text.replace("\f", " ")
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = text.lower()
    text = MULTISPACE_RE.sub(" ", text)
    return text.strip()


def normalize_line(text: str) -> str:
    text = text.replace("\u00a0", " ")
    text = text.replace("\f", "")
    text = text.replace("\u2019", "'")
    text = text.replace("\u2018", "'")
    text = text.replace("\u2013", "-")
    text = text.replace("\u2014", "—")
    text = text.replace("\u2009", " ")
    text = text.replace("\u202f", " ")
    text = text.replace("\t", " ")
    return text.strip()


def clean_verse_text(text: str) -> str:
    text = FOOTNOTE_RE.sub("", text)
    text = MULTISPACE_RE.sub(" ", text)
    return text.strip()


def append_text(existing: str, incoming: str) -> str:
    if not incoming:
        return existing
    if not existing:
        return incoming

    if existing.endswith("-") and incoming and incoming[0].isalpha():
        return f"{existing[:-1]}{incoming}"

    return f"{existing} {incoming}"


def is_colon_marker(line: str) -> bool:
    return bool(COLON_MARKER_RE.match(line))


def is_page_number(line: str) -> bool:
    return bool(PAGE_NUMBER_RE.match(line))
