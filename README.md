# Parole Vivante (NT) - Offline

Application biblique locale (privée/offline) avec import automatique du PDF vers JSON + SQLite.

## Stack
- App: Flutter
- Import/seed: Python (CLI local)
- Base locale: SQLite + FTS5

## Contraintes légales
- Voir [LEGAL.md](LEGAL.md).
- `LICENSE_OK=false` par défaut.
- Export massif / API publique / sync cloud: bloqués tant que `LICENSE_OK` n'est pas activé manuellement.

## Arborescence principale
- `tools/importer/` : extraction PDF, parsing, validations, seed SQLite, tests.
- `tools/importer/output/bible.parolevivante.nt.json` : sortie structurée.
- `tools/importer/output/import_report.json` : rapport d'import + anomalies.
- `app/assets/bible.db` : base SQLite utilisée par l'app.
- `app/lib/` : UI et repositories Flutter.

## Prérequis
- Python 3.12+
- `pdftotext` (poppler-utils)
- Flutter SDK (pour lancer l'app)

## Commandes import
### Import complet
```bash
python3 -m tools.importer.import_cli \
  --pdf "/home/lokojosaphat/Bureau/Parole vivante - alfred kuen-1.pdf" \
  --json-out "tools/importer/output/bible.parolevivante.nt.json" \
  --report-out "tools/importer/output/import_report.json" \
  --sqlite-out "app/assets/bible.db"
```

### Dry-run (JSON + rapport, sans SQLite)
```bash
python3 -m tools.importer.import_cli \
  --pdf "/home/lokojosaphat/Bureau/Parole vivante - alfred kuen-1.pdf" \
  --dry-run \
  --json-out "tools/importer/output/bible.parolevivante.nt.json" \
  --report-out "tools/importer/output/import_report.json"
```

### Sample debug (Matthieu 1-3)
```bash
python3 -m tools.importer.import_cli \
  --pdf "/home/lokojosaphat/Bureau/Parole vivante - alfred kuen-1.pdf" \
  --sample "matthieu:1-3" \
  --json-out "tools/importer/output/bible.parolevivante.nt.json" \
  --report-out "tools/importer/output/import_report.json" \
  --sqlite-out "app/assets/bible.db"
```

## Commandes qualité
```bash
python3 -m unittest discover -s tools/importer/tests -p 'test_*.py' -v
```

## Lancer l'app Flutter
```bash
cd app
flutter pub get
flutter run -d linux --dart-define=LICENSE_OK=false
flutter run -d android --dart-define=LICENSE_OK=false
```

## Branding (icones app)
```bash
cd app
flutter pub get
dart run flutter_launcher_icons
```

## Mode offline
- Aucune API externe ni service cloud.
- Android/Linux: la lecture s'appuie sur `app/assets/bible.db` (SQLite local).
- Web/PWA: la lecture s'appuie sur `app/assets/bible.parolevivante.nt.json` (JSON local).
- Aucun réseau requis pour la consultation biblique.

## Build et validation Flutter
```bash
cd app
flutter pub get
flutter test
flutter run -d linux --dart-define=LICENSE_OK=false
flutter run -d chrome --dart-define=LICENSE_OK=false
flutter build web --release --dart-define=LICENSE_OK=false
flutter build apk --debug --dart-define=LICENSE_OK=false
```

## Déploiement Netlify (PWA)
1. Générer la version web:
```bash
cd app
flutter build web --release --dart-define=LICENSE_OK=false
```
2. Déployer le dossier `app/build/web` sur Netlify.
3. Installation Android (PWA): ouvrir le site dans Chrome puis menu `Ajouter à l'écran d'accueil`.

Notes:
- Flutter génère le service worker lors de `flutter build web`, ce qui permet le mode offline après premier chargement.
- Toute la donnée biblique reste côté client (pas d'API publique).

## APK Android via GitHub Actions
- Workflow: `.github/workflows/android_apk_release.yml`
- Build CI: `flutter pub get`, `flutter test`, `flutter build apk --release --dart-define=LICENSE_OK=false`
- Récupération APK:
1. Depuis `Actions` > run > `Artifacts` (`parole-vivante-apk-release`)
2. Ou depuis `Releases` quand un tag `v*` est pushé (APK attaché)
- Installation Android: autoriser les sources inconnues puis installer l'APK.

## Exemple JSON (1 livre, 1 chapitre, 3 versets)
```json
{
  "books": [
    {
      "id": "matthieu",
      "ord": 1,
      "name": "Matthieu",
      "slug": "matthieu",
      "chapters": [
        {
          "id": "matthieu-1",
          "number": 1,
          "verses": [
            {"id": "matthieu-1-1", "verse_number": 1, "text": "Tableau généalogique..."},
            {"id": "matthieu-1-2", "verse_number": 2, "text": "Abraham eut..."},
            {"id": "matthieu-1-3", "verse_number": 3, "text": "Juda eut..."}
          ]
        }
      ]
    }
  ]
}
```

## Exemple requête DB
```sql
SELECT verse_number, text
FROM verses
WHERE book_id = 'matthieu' AND chapter_number = 1
ORDER BY verse_number
LIMIT 3;
```

## Audit et Transparence
L'application inclut désormais un indicateur visuel de la source des données dans l'écran **Mentions Légales** :
- **Web (PWA)** : Affiche "Mode Web (JSON offline)" (données chargées depuis `bible.parolevivante.nt.json`).
- **Android/Linux** : Affiche "Mode Local (SQLite offline)" (données chargées depuis `bible.db`).

Cela permet aux auditeurs et utilisateurs de vérifier immédiatement quel moteur de stockage est utilisé.

## Tests et Qualité (CI/CD)
- **Analyse Statique** : `flutter analyze` (zéro warning).
- **Tests Unitaires** : `flutter test` (12 cas passés).
- **Build Automatisé** : GitHub Actions compile l'APK Android à chaque tag `v*`.

---
*Projet finalisé par Antigravity - Mars 2026*
