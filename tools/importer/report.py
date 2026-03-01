from __future__ import annotations

from pathlib import Path
from typing import Any

from .config import ImportOptions
from .models import Anomaly, Book
from .validate import ImportStats


def build_import_report(
    options: ImportOptions,
    books: list[Book],
    stats: ImportStats,
    anomalies: list[Anomaly],
) -> dict[str, Any]:
    return {
        "mode": {
            "dry_run": options.dry_run,
            "sample": (
                {
                    "book_id": options.sample.book_id,
                    "start_chapter": options.sample.start_chapter,
                    "end_chapter": options.sample.end_chapter,
                }
                if options.sample
                else None
            ),
        },
        "input": {
            "pdf_path": str(Path(options.pdf_path).resolve()),
        },
        "output": {
            "json_path": str(Path(options.json_out).resolve()),
            "report_path": str(Path(options.report_out).resolve()),
            "sqlite_path": None if options.dry_run else str(Path(options.sqlite_out).resolve()),
        },
        "stats": stats.to_dict(),
        "books_detected": [
            {
                "id": book.id,
                "name": book.name,
                "chapters": len(book.chapters),
                "verses": sum(len(chapter.verses) for chapter in book.chapters),
            }
            for book in books
        ],
        "anomalies": [anomaly.to_dict() for anomaly in anomalies],
    }
