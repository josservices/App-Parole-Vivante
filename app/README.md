# Parole Vivante NT (Flutter)

## Sources de données
- Android/Linux: `assets/bible.db` (SQLite local)
- Web/PWA: `assets/bible.parolevivante.nt.json` (JSON local)

## Commandes
```bash
flutter pub get
flutter test
flutter run -d linux --dart-define=LICENSE_OK=false
flutter run -d chrome --dart-define=LICENSE_OK=false
flutter build web --release --dart-define=LICENSE_OK=false
flutter build apk --debug --dart-define=LICENSE_OK=false
```

## Netlify (PWA)
```bash
flutter build web --release --dart-define=LICENSE_OK=false
```
Déployer `build/web` sur Netlify.

## Légal
- `LEGAL_GUARD` actif
- `LICENSE_OK=false` par défaut
