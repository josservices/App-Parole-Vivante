# Scripts et Déploiement - Parole Vivante (NT)

Ce répertoire contient les guides et astuces pour le build et le déploiement.

## 1. Déploiement Web sur Netlify (PWA)

### Build Local
Pour générer la version Web prête au déploiement :
```bash
cd app
flutter build web --release --dart-define=LICENSE_OK=false
```
(Le paramètre `--dart-define=LICENSE_OK=false` garantit que les verrous légaux sont actifs).

### Déploiement sur Netlify
1.  Connectez-vous à votre console Netlify.
2.  Ajoutez un nouveau site.
3.  Si déploiement manuel : glissez-déposez le dossier `app/build/web`.
4.  Si lié à GitHub : Netlify lira le fichier `netlify.toml` à la racine pour connaître le répertoire de publication (`app/build/web`) et la commande de build.

### Installation de la PWA sur Mobile
1.  Ouvrez l'URL de votre site Netlify sur Android (via Chrome) ou iOS (via Safari).
2.  **Sur Chrome Android** : Cliquez sur les trois petits points verticalement et sélectionnez "Ajouter à l'écran d'accueil" ou "Installer l'application".
3.  **Sur Safari iOS** : Cliquez sur l'icône de partage, puis "Sur l'écran d'accueil".
4.  Une fois installée, l'application fonctionne à 100% hors-ligne grâce aux Service Workers de Flutter et au chargement de la Bible via le fichier JSON.

## 2. Build Android (APK)

Un workflow automatique est en place sur GitHub Actions.
1.  Poussez une balise (tag) commençant par `v` (ex: `v1.0.0`).
2.  Le workflow compile l'APK et l'attache à une nouvelle "Release" sur GitHub.
3.  Vous pouvez alors télécharger l'APK et l'envoyer directement aux testeurs/utilisateurs.

### Installation Manuel de l'APK
1.  Téléchargez l'APK sur votre téléphone Android.
2.  Ouvrez-le. Autorisez l'installation depuis "Sources Inconnues" si demandé.
3.  Cette version utilise le stockage SQLite local par défaut.

## 3. Débogage

- **Web** : Pour tester en local avec Chrome :
  ```bash
  cd app
  flutter run -d chrome --dart-define=LICENSE_OK=false
  ```
- **Linux** :
  ```bash
  cd app
  flutter run -d linux
  ```
