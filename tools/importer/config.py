from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
import re


@dataclass(frozen=True)
class SampleFilter:
    book_id: str
    start_chapter: int | None = None
    end_chapter: int | None = None


@dataclass(frozen=True)
class ImportOptions:
    pdf_path: Path
    json_out: Path
    report_out: Path
    sqlite_out: Path
    dry_run: bool = False
    sample: SampleFilter | None = None


_SAMPLE_RE = re.compile(r"^\s*([\w\-\séèêëàâäîïôöùûüç']+?)(?::(\d+)(?:-(\d+))?)?\s*$", re.IGNORECASE)


def parse_sample_filter(raw: str) -> SampleFilter:
    """
    Parse formats:
    - matthieu
    - matthieu:1
    - matthieu:1-3
    """
    match = _SAMPLE_RE.match(raw)
    if not match:
        raise ValueError(
            "Format --sample invalide. Utilisez 'matthieu', 'matthieu:1' ou 'matthieu:1-3'."
        )

    book_part = match.group(1).strip().lower().replace(" ", "-")
    start = int(match.group(2)) if match.group(2) else None
    end = int(match.group(3)) if match.group(3) else None

    if start is not None and end is None:
        end = start

    if start is not None and end is not None and end < start:
        raise ValueError("Intervalle de chapitres invalide: la fin doit être >= au début.")

    return SampleFilter(book_id=book_part, start_chapter=start, end_chapter=end)
