# Angela_Deesse
## Angela Déesse - Application Mobile Couture & Gestion d'Atelier (Flutter)

Version **interface uniquement** : aucun back-end (pas de base de données, de synchro cloud, de notifications système ni de PDF).
Les écrans fonctionnent avec des données de démonstration en mémoire (`lib/data/store.dart`).

## Lancer
```bash
cd angela_dress
flutter create . --platforms=android --org com.digitalvision --project-name angela_dress
flutter pub get
flutter run
```
(`flutter create .` génère le dossier `android/` sans toucher à `lib/` ni aux assets.)

## Design
- Cobalt + orange, texte encre marine, police **Manrope** (menus, titres, corps) et **Fraunces** (nom de l'atelier). Polices et logos sont dans `assets/`.
- Menu latéral (Drawer) : Accueil, Commandes, Clients / Gestion : Finance, Apprentis, Modèles / Atelier : Galerie, Notifications, Paramètres.
- Pilule flottante : Accueil, Commandes, Clients + bouton orange `+` (ajout rapide).
- Couleurs et rayons : `lib/core/theme.dart`. Composants (en-tête, cartes, puces, champs) : `lib/widgets/common.dart`.

## Ce qui est factice
- Photos : tuiles dégradées « demo:N » (ajout de photo simulé).
- Historique des 6 mois de l'écran Finance : valeurs fictives (sauf le mois en cours).
- Reçu apprenti : aperçu visuel, pas de PDF ni de partage WhatsApp.
- Écran de verrouillage : aperçu (Paramètres > Code d'accès), n'importe quel code l'ouvre.
- Interrupteurs de rappels : visuels uniquement.

## Brancher le back-end plus tard
Tous les écrans passent par `AppStore` (`lib/data/store.dart`). Il suffira de remplacer ses listes en mémoire par la base locale, sans toucher aux écrans.
