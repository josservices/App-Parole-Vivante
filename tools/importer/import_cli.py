#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
import traceback

if __package__ in (None, ""):
    repo_root = Path(__file__).resolve().parents[2]
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))
    from tools.importer.config import ImportOptions, parse_sample_filter
    from tools.importer.parse_nt import apply_sample_filter, parse_nt_text
    from tools.importer.pdf_extract import PdfExtractionError, extract_text_from_pdf
    from tools.importer.report import build_import_report
    from tools.importer.sqlite_seed import seed_sqlite
    from tools.importer.validate import validate_books
else:
    from .config import ImportOptions, parse_sample_filter
    from .parse_nt import apply_sample_filter, parse_nt_text
    from .pdf_extract import PdfExtractionError, extract_text_from_pdf
    from .report import build_import_report
    from .sqlite_seed import seed_sqlite
    from .validate import validate_books


def _serialize_books(books):
    return [book.to_dict() for book in books]


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        prog="parole-vivante-import",
        description="Import local/offline du PDF Parole Vivante NT vers JSON + SQLite.",
    )
    parser.add_argument("--pdf", required=True, help="Chemin du PDF source")
    parser.add_argument(
        "--json-out",
        default="tools/importer/output/bible.parolevivante.nt.json",
        help="Sortie JSON structurée",
    )
    parser.add_argument(
        "--report-out",
        default="tools/importer/output/import_report.json",
        help="Sortie rapport d'import",
    )
    parser.add_argument(
        "--sqlite-out",
        default="app/assets/bible.db",
        help="Sortie SQLite (ignoré en --dry-run)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Génère JSON + rapport sans écrire la base SQLite.",
    )
    parser.add_argument(
        "--sample",
        help="Import partiel pour debug (ex: matthieu:1-3).",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv if argv is not None else sys.argv[1:])

    try:
        sample = parse_sample_filter(args.sample) if args.sample else None
        options = ImportOptions(
            pdf_path=Path(args.pdf),
            json_out=Path(args.json_out),
            report_out=Path(args.report_out),
            sqlite_out=Path(args.sqlite_out),
            dry_run=bool(args.dry_run),
            sample=sample,
        )

        raw_text = extract_text_from_pdf(options.pdf_path)
        books, parser_anomalies = parse_nt_text(raw_text)
        books = apply_sample_filter(books, options.sample)

        stats, anomalies = validate_books(books, parser_anomalies)

        json_payload = {
            "books": _serialize_books(books),
            "stats": stats.to_dict(),
            "anomalies": [anomaly.to_dict() for anomaly in anomalies],
        }

        options.json_out.parent.mkdir(parents=True, exist_ok=True)
        with options.json_out.open("w", encoding="utf-8") as handle:
            json.dump(json_payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")

        if not options.dry_run:
            seed_sqlite(books, options.sqlite_out)

        report_payload = build_import_report(
            options=options,
            books=books,
            stats=stats,
            anomalies=anomalies,
        )
        options.report_out.parent.mkdir(parents=True, exist_ok=True)
        with options.report_out.open("w", encoding="utf-8") as handle:
            json.dump(report_payload, handle, ensure_ascii=False, indent=2)
            handle.write("\n")

        print(
            f"Import terminé. Livres={stats.books}, chapitres={stats.chapters}, versets={stats.verses}, anomalies={stats.anomalies}"
        )
        if options.dry_run:
            print("Mode dry-run: SQLite non écrit.")
        else:
            print(f"SQLite écrit: {options.sqlite_out}")
        return 0

    except (PdfExtractionError, ValueError, OSError) as exc:
        print(f"ERREUR: {exc}", file=sys.stderr)
        return 2
    except Exception as exc:  # explicit crash path with clear traceback for debugging
        print(f"ERREUR INATTENDUE: {exc}", file=sys.stderr)
        traceback.print_exc()
        return 3


if __name__ == "__main__":
    raise SystemExit(main())
