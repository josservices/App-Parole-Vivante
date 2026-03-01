from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any


@dataclass
class Verse:
    id: str
    book_id: str
    chapter_number: int
    verse_number: int
    text: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "book_id": self.book_id,
            "chapter_number": self.chapter_number,
            "verse_number": self.verse_number,
            "text": self.text,
        }


@dataclass
class Chapter:
    id: str
    book_id: str
    number: int
    verses: list[Verse] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "book_id": self.book_id,
            "number": self.number,
            "verses": [verse.to_dict() for verse in self.verses],
        }


@dataclass
class Book:
    id: str
    ord: int
    name: str
    slug: str
    chapters: list[Chapter] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "ord": self.ord,
            "name": self.name,
            "slug": self.slug,
            "chapters": [chapter.to_dict() for chapter in self.chapters],
        }


@dataclass
class Anomaly:
    code: str
    message: str
    context: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "code": self.code,
            "message": self.message,
            "context": self.context,
        }
