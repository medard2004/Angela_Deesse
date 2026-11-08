# Notes de Version et Architecture du Moteur d'Alarmes

## Angela Déesse - Version 2.0 (Moteur d'Alarme et Notifications Fiables)

### 1. Vue d'ensemble architecturale
Le système de rappels et d'alarmes d'Angela Déesse a été entièrement restructuré pour garantir une fiabilité absolue sur le terrain (notamment sur les appareils Android populaires au Togo : Tecno, Infinix, Samsung, Xiaomi) tout en respectant une séparation stricte des responsabilités :
- **Dart (Application)** : Seul planificateur et seul écrivain dans la base SQLite locale (Drift). Calcule le plan de rappels selon les règles métier et les préférences de l'artisan.
- **Natif Kotlin (Moteur Réveil)** : Reçoit le plan d'alarmes sous forme d'instants UTC et paramètres textuels publics, planifie via `AlarmManager.setAlarmClock()`, et prend le relais complet lorsque l'app est fermée ou le téléphone verrouillé.
- **100 % Local et Hors-Ligne** : Aucun serveur, aucune dépendance cloud, aucun Firebase Cloud Messaging (FCM).

### 2. Fonctionnalités et Garanties
1. **Alarmes Réveil Plein Écran (`AlarmActivity`)** :
   - Déclenchées par `AlarmReceiver` via `AlarmManager.setAlarmClock()`.
   - Lance `AlarmService` (Foreground Service de type `mediaPlayback`) qui joue la mélodie douce en boucle sur `STREAM_ALARM` et fait vibrer le téléphone.
   - Affiche `AlarmActivity` avec `showWhenLocked` et `turnScreenOn`.
   - Boutons « ARRÊTER » et « REPORTER 10m » traités nativement sans charger le moteur Flutter.
   - Arrêt automatique au bout de 5 minutes avec requalification en alarme manquée (`missed`).
2. **Confidentialité et Sécurité sur Écran Verrouillé** :
   - `MainActivity` ne possède pas `showWhenLocked` : après déverrouillage de l'alarme, le téléphone reste verrouillé par son PIN système ou le code PIN interne de l'atelier.
   - Les titres et textes visibles sur l'écran d'alarme et dans la notification publique sont anonymisés (ex. « Livraison demain · 2 commandes » sans afficher les noms de clients, titres de commandes ou montants).
3. **Bandeau In-App et Dédoublonnage Strict** :
   - Quand l'application est active et déverrouillée au moment d'un rappel, un bandeau in-app élégant (`InAppNotificationBanner`) est affiché.
   - Le push OS est immédiatement annulé pour éviter tout doublon visuel ou sonore.
   - Si l'écran de PIN est affiché, l'app est considérée en arrière-plan et la notification système normale est maintenue.
4. **Centre de Notifications à Deux Sections (`NotificationsScreen`)** :
   - **« À faire »** : Liste exhaustive des alertes en cours calculées par `AlertEngine` (commandes en retard, livraisons, essayages, échéances d'apprentis, soldes dus).
   - **« Historique (30 jours) »** : Journal de toutes les alarmes et notifications passées, synchronisé depuis la boîte de réception native vers la table Drift `notification_logs`.
   - Les **alarmes manquées** (`outcome: 'missed'`) sont mises en avant en tête de liste avec un fond rouge clair et un badge d'avertissement.
   - Bouton « Tout marquer comme vu » pour acquitter simultanément les alertes et l'historique.

### 3. Migration Base de Données (Drift Schéma v2)
- Schéma Drift passé de v1 à v2.
- Ajout de la table locale non synchronisée `notification_logs` (16 colonnes, index sur `scheduled_at` et `outcome`, purge automatique au-delà de 30 jours).
- Zéro écriture dans `sync_outbox` pour préserver l'intégrité de la synchronisation locale.

### 4. Tests et Validation
- Tests unitaires et d'intégration Dart : 171/171 tests au vert.
- Tests unitaires natifs Kotlin (`AlarmEngineTest`) : 4/4 tests au vert (encodage, persistance, snooze 10m, boîte aux lettres d'événements).
- Analyse statique `dart analyze` : 0 avertissement, 0 erreur.
