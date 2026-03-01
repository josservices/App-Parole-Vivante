from __future__ import annotations

from pathlib import Path
import shutil
import subprocess


class PdfExtractionError(RuntimeError):
    pass


def extract_text_from_pdf(pdf_path: Path) -> str:
    if not pdf_path.exists():
        raise PdfExtractionError(f"Fichier PDF introuvable: {pdf_path}")

    pdftotext_bin = shutil.which("pdftotext")
    if not pdftotext_bin:
        raise PdfExtractionError(
            "La commande 'pdftotext' est introuvable. Installez poppler-utils localement."
        )

    cmd = [pdftotext_bin, "-layout", str(pdf_path), "-"]
    try:
        completed = subprocess.run(
            cmd,
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
    except subprocess.CalledProcessError as exc:
        stderr = (exc.stderr or "").strip()
        raise PdfExtractionError(f"Echec extraction PDF avec pdftotext: {stderr}") from exc

    output = completed.stdout
    if not output.strip():
        raise PdfExtractionError("Extraction PDF vide: aucun texte détecté.")
    return output
