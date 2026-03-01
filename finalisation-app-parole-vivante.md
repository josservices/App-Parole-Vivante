# Finalisation App Parole Vivante

## Objectif
Achever le projet "App Parole Vivante" en assurant un design premium, une transparence sur la source des données (JSON/SQLite) et une documentation complète pour le déploiement.

## Tâches

### 1. Amélioration de l'esthétique Web (SEO & Chargement)
- [x] **Optimiser `app/web/index.html`** → Ajouter des méta-tags SEO complets et un écran de chargement élégant.
- [x] **Vérifier `app/web/manifest.json`** → Assurer la cohérence des noms et des couleurs.

### 2. Indicateur de Source de Données (Audit)
- [x] **Mettre à jour `app/lib/features/legal/legal_screen.dart`** → Afficher l'indicateur "Mode Web (JSON offline)" ou "Mode Local (SQLite offline)" de façon permanente et lisible.

### 3. Finalisation des Assets & Branding
- [x] **S'assurer que `app/assets/branding` est correctement intégré** → Vérifier l'appel à `wordmark.png` et `logo_mark.png` dans l'UI.

### 4. Documentation & Qualité Finale
- [x] **Mettre à jour le `README.md` principal** → Inclure les liens vers les scripts et les commandes de build finales.
- [x] **Exécuter une analyse finale** → Lancer `flutter analyze` pour s'assurer qu'il n'y a pas d'erreurs ou de warnings bloquants.

## Terminé quand
- [x] L'application web affiche un écran de chargement premium.
- [x] L'indicateur de source de données est visible dans les mentions légales.
- [x] Le workflow de déploiement Netlify et GitHub Actions est validé.
