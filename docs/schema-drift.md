# Schéma de la Base de Données Locale (Drift SQLite)

Ce document décrit le schéma complet de la base de données locale sous Drift pour l'application **Angela Couture**.

> **Note importante** : Le schéma actuel correspond à `schemaVersion = 1`. Si une base v1 précédente a déjà été installée sur un appareil ou simulateur de test lors des premiers essais préliminaires, il convient de **désinstaller complètement l'application** afin de recréer une base vierge avec les dernières contraintes et tables.

---

## 1. Principes d'architecture & Décisions validées

1. **Identifiants** : Clés primaires en texte sous forme d'**UUIDv7**, générés côté client de manière synchrone et testable via l'interface `IdGenerator` (`UuidV7IdGenerator`). Aucun `AUTOINCREMENT` SQLite n'est utilisé.
2. **Horodatages, Dates & Conventions temporelles** : 
   - Toutes les colonnes temporelles sont stockées sous forme d'**entiers SQLite (`INTEGER`) en millisecondes UTC depuis l'époque Unix** via un `TypeConverter` dédié (`DateTimeConverter` et `NullableDateTimeConverter`).
   - Deux conventions sémantiques strictes régissent les dates :
     - **« instant »** : moment précis dans le temps (UTC epoch ms), utilisé pour les horodatages techniques et événements réels (`created_at`, `updated_at`, `deleted_at`, `paid_at`, `voided_at`, `delivered_at`, `taken_at`, `fitting_date` préservant l'heure d'essayage).
     - **« jour calendaire (UTC minuit) »** : date sans composante horaire liée au calendrier civil (`delivery_date`, `start_date`, `next_due`), systématiquement normalisée à `DateTime.utc(year, month, day, 0, 0, 0)`. Cela garantit un aller-retour exact et invariant quel que soit le fuseau horaire de l'appareil (`Africa/Lagos` UTC+1, `America/New_York` UTC-5). Les calculs d'échéances et de retards (tableau de bord) s'effectuent côté Dart avec les bornes locales de l'utilisateur.
   - *Comportement Drift par défaut* : Drift stocke par défaut les `DateTime` en secondes Unix tronquées (`~/ 1000`). L'utilisation systématique de nos convertisseurs garantit la préservation exacte des millisecondes requises pour les résolutions de conflits et tris de synchronisation.
3. **Suppression logique & Règle d'or Outbox** :
   - Toutes les entités synchronisables portent `deleted_at` (nullable).
   - **Interdiction absolue du DELETE physique** sur les tables synchronisables : aucune ligne n'est supprimée par un `DELETE FROM ...`. Une suppression s'effectue toujours par une mise à jour renseignant `deleted_at = now`.
   - Dans `sync_outbox`, l'opération `op = 'delete'` signifie strictement **suppression logique** (la ligne reste en base locale avec `deleted_at` valorisé).
4. **Monnaie & Montants** : Tous les montants sont représentés en entiers FCFA (`INTEGER`), sans décimales.
5. **Reçus, Compteurs & Annulations** :
   - Les tables `client_payments` et `apprentice_payments` possèdent une colonne `receipt_number INTEGER NOT NULL` dotée d'un index `UNIQUE`.
   - Les compteurs de reçus sont stockés dans la table locale non synchronisée `receipt_counters` et incrémentés dans la même transaction que l'écriture du versement.
   - La méthode `AppDatabase.reconcileReceiptCounters()` recalcule `last_value = max(last_value, MAX(receipt_number))` après tout pull ou restauration de données (versements annulés inclus).
   - Les versements ne sont ni modifiés ni supprimés : l'annulation s'effectue via `voided_at` + `void_reason`. Les versements annulés sont exclus des totaux de paiement et du solde restant. Leur numéro de reçu n'est jamais réutilisé.
6. **Gestion des photos & Table `order_photos`** :
   - Les entités disposant d'une photo principale portent `photo_path` (acceptant la convention `demo:N` ou chemin local relatif `photos/<hash>.jpg`), `photo_hash` (nullable) et `photo_upload_state` (`none`, `pending`, `uploaded`, `failed`). Le schéma SQLite lui-même ne change pas dans cette tranche : les trois colonnes étaient déjà prévues.
   - Les photos multiples d'une commande sont stockées dans la table dédiée `order_photos` pour gérer individuellement l'état d'upload et le positionnement de chaque cliché. Toutes les photos réelles partagent le même dossier local de stockage dédoublonné par hash SHA-256 sans duplication physique de fichier.
7. **Contraintes CHECK** :
   - `client_payments.amount > 0`
   - `client_payments.balance_after >= 0`
   - `apprentice_payments.amount > 0`
   - `apprentice_payments.balance_after >= 0`
   - `orders.price >= 0`
   - `apprentices.total_fee >= 0`
   - `photo_upload_state IN ('none', 'pending', 'uploaded', 'failed')` sur `modeles`, `orders`, `order_photos`, `realisations`
   - `sync_outbox.op IN ('upsert', 'delete')`
   - *(Note : aucun CHECK sur `orders.status` pour permettre l'évolution libre des statuts métier)*
8. **État du Schéma** : Le schéma Drift SQLite (`schemaVersion = 1`, dump v1 à jour dans `drift_schemas/drift_schema_v1.json`) est validé, durci par contraintes CHECK exhaustives, et est prêt pour le gel. Toute base antérieure de test doit être réinstallée pour intégrer ces contraintes.
9. **Atomicité Outbox** : La méthode utilitaire `AppDatabase.writeWithOutbox` encapsule la modification métier et l'insertion dans `sync_outbox` dans une transaction SQLite unique (rollback intégral en cas d'échec).
10. **Sécurité** : Aucun hash de code PIN ni clé d'appareil n'est stocké dans cette base SQLite.

---

## 2. Inventaire des Tables

### 2.1 Table `clients`
Table des clients de l'atelier.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `name` | `TEXT` | `String` | Non | - | Nom complet du client |
| `phone` | `TEXT` | `String` | Non | Défaut `''` | Téléphone |
| `notes` | `TEXT` | `String` | Non | Défaut `''` | Remarques / notes |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Index** :
  - `idx_clients_name` sur `(name)`
  - `idx_clients_updated_at` sur `(updated_at)`
  - `idx_clients_deleted_at` sur `(deleted_at)`

---

### 2.2 Table `measurements`
Fiches de mesures prises pour un client.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `client_id` | `TEXT` | `String` | Non | FK `clients(id)` | Référence du client |
| `taken_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de prise de mesure |
| `measures` | `TEXT` | `Map<String, double>` | Non | JSON String | Valeurs des mensurations (cm) |
| `note` | `TEXT` | `String` | Non | Défaut `''` | Note facultative |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Clé étrangère** : `client_id` -> `clients(id)`
- **Index** :
  - `idx_measurements_client_id` sur `(client_id)`
  - `idx_measurements_taken_at` sur `(taken_at)`
  - `idx_measurements_updated_at` sur `(updated_at)`
  - `idx_measurements_deleted_at` sur `(deleted_at)`

---

### 2.3 Table `modeles`
Modèles du catalogue de l'atelier.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `name` | `TEXT` | `String` | Non | - | Nom du modèle |
| `description` | `TEXT` | `String` | Non | Défaut `''` | Description |
| `photo_path` | `TEXT` | `String?` | Oui | - | Chemin d'image (ex. `demo:1`) |
| `photo_hash` | `TEXT` | `String?` | Oui | - | Hash SHA256 de la photo |
| `photo_upload_state` | `TEXT` | `String` | Non | Défaut `'none'` | État upload photo |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Index** :
  - `idx_modeles_name` sur `(name)`
  - `idx_modeles_updated_at` sur `(updated_at)`
  - `idx_modeles_deleted_at` sur `(deleted_at)`

---

### 2.4 Table `orders`
Commandes de confections passées par les clients.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `client_id` | `TEXT` | `String` | Non | FK `clients(id)` | Référence du client |
| `modele_id` | `TEXT` | `String?` | Oui | FK `modeles(id)` | Référence du modèle choisi |
| `title` | `TEXT` | `String` | Non | - | Intitulé de la commande |
| `fabric` | `TEXT` | `String` | Non | Défaut `''` | Tissu fourni/décrit |
| `price` | `INTEGER` | `int` | Non | `CHECK (price >= 0)` | Prix total convenu (FCFA) |
| `delivery_date` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | jour calendaire (UTC minuit) — Date limite de livraison |
| `fitting_date` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant (UTC epoch ms) — Date et heure d'essayage |
| `status` | `TEXT` | `String` | Non | Défaut `'attente'` | `attente`, `cours`, `prete`, `livree` |
| `delivered_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date réelle de livraison (statut 'livree') |
| `photo_path` | `TEXT` | `String?` | Oui | - | Photo principale |
| `photo_hash` | `TEXT` | `String?` | Oui | - | Hash SHA256 |
| `photo_upload_state` | `TEXT` | `String` | Non | Défaut `'none'` | État d'upload |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Contrainte CHECK** : `CHECK (price >= 0)`
- **Clés étrangères** :
  - `client_id` -> `clients(id)`
  - `modele_id` -> `modeles(id)`
- **Index** :
  - `idx_orders_client_id` sur `(client_id)`
  - `idx_orders_modele_id` sur `(modele_id)`
  - `idx_orders_delivery_date` sur `(delivery_date)`
  - `idx_orders_status` sur `(status)`
  - `idx_orders_delivered_at` sur `(delivered_at)`
  - `idx_orders_updated_at` sur `(updated_at)`
  - `idx_orders_deleted_at` sur `(deleted_at)`

---

### 2.5 Table `order_photos`
Galerie de photos complémentaires associées à une commande.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `order_id` | `TEXT` | `String` | Non | FK `orders(id)` | Référence de la commande |
| `photo_path` | `TEXT` | `String` | Non | - | Chemin de l'image |
| `photo_hash` | `TEXT` | `String?` | Oui | - | Hash SHA256 |
| `photo_upload_state` | `TEXT` | `String` | Non | Défaut `'none'` | `none`, `pending`, `uploaded`, `failed` |
| `position` | `INTEGER` | `int` | Non | Défaut `0` | Ordre d'affichage |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Clé étrangère** : `order_id` -> `orders(id)`
- **Index** :
  - `idx_order_photos_order_id` sur `(order_id)`
  - `idx_order_photos_updated_at` sur `(updated_at)`
  - `idx_order_photos_deleted_at` sur `(deleted_at)`

---

### 2.6 Table `client_payments`
Paiements / acomptes versés par les clients sur une commande.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `order_id` | `TEXT` | `String` | Non | FK `orders(id)` | Référence de la commande |
| `amount` | `INTEGER` | `int` | Non | `CHECK (amount > 0)` | Montant versé (FCFA) |
| `paid_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date du versement |
| `note` | `TEXT` | `String` | Non | Défaut `''` | Note / méthode de versement |
| `receipt_number` | `INTEGER` | `int` | Non | **UNIQUE** | Numéro séquentiel de reçu |
| `order_price_at_payment` | `INTEGER` | `int` | Non | - | Prix de commande au moment du versement (immuable) |
| `balance_after` | `INTEGER` | `int` | Non | `CHECK (balance_after >= 0)` | Solde restant après ce versement (immuable) |
| `voided_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date d'annulation |
| `void_reason` | `TEXT` | `String?` | Oui | - | Motif d'annulation |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Contrainte CHECK** : `CHECK (amount > 0)`, `CHECK (balance_after >= 0)`
- **Clé étrangère** : `order_id` -> `orders(id)`
- **Index** :
  - `idx_client_payments_receipt_number` **UNIQUE** sur `(receipt_number)`
  - `idx_client_payments_order_id` sur `(order_id)`
  - `idx_client_payments_paid_at` sur `(paid_at)`
  - `idx_client_payments_voided_at` sur `(voided_at)`
  - `idx_client_payments_updated_at` sur `(updated_at)`
  - `idx_client_payments_deleted_at` sur `(deleted_at)`

---

### 2.7 Table `apprentices`
Apprentis en formation au sein de l'atelier.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `name` | `TEXT` | `String` | Non | - | Nom de l'apprenti |
| `phone` | `TEXT` | `String` | Non | Défaut `''` | Téléphone |
| `start_date` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | jour calendaire (UTC minuit) — Date de début de formation |
| `total_fee` | `INTEGER` | `int` | Non | `CHECK (total_fee >= 0)` | Frais totaux convenus (FCFA) |
| `next_due` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | jour calendaire (UTC minuit) — Date de prochaine échéance |
| `notes` | `TEXT` | `String` | Non | Défaut `''` | Remarques |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Contrainte CHECK** : `CHECK (total_fee >= 0)`
- **Index** :
  - `idx_apprentices_name` sur `(name)`
  - `idx_apprentices_next_due` sur `(next_due)`
  - `idx_apprentices_updated_at` sur `(updated_at)`
  - `idx_apprentices_deleted_at` sur `(deleted_at)`

---

### 2.8 Table `apprentice_payments`
Versements d'écolage effectués par un apprenti.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `apprentice_id` | `TEXT` | `String` | Non | FK `apprentices(id)` | Référence de l'apprenti |
| `amount` | `INTEGER` | `int` | Non | `CHECK (amount > 0)` | Montant versé (FCFA) |
| `paid_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date du versement |
| `note` | `TEXT` | `String` | Non | Défaut `''` | Note / motif |
| `receipt_number` | `INTEGER` | `int` | Non | **UNIQUE** | Numéro séquentiel de reçu |
| `total_fee_at_payment` | `INTEGER` | `int` | Non | - | Frais de formation au moment du versement (immuable) |
| `balance_after` | `INTEGER` | `int` | Non | `CHECK (balance_after >= 0)` | Solde restant après ce versement (immuable) |
| `voided_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date d'annulation |
| `void_reason` | `TEXT` | `String?` | Oui | - | Motif d'annulation |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Contrainte CHECK** : `CHECK (amount > 0)`, `CHECK (balance_after >= 0)`
- **Clé étrangère** : `apprentice_id` -> `apprentices(id)`
- **Index** :
  - `idx_apprentice_payments_receipt_number` **UNIQUE** sur `(receipt_number)`
  - `idx_apprentice_payments_apprentice_id` sur `(apprentice_id)`
  - `idx_apprentice_payments_paid_at` sur `(paid_at)`
  - `idx_apprentice_payments_voided_at` sur `(voided_at)`
  - `idx_apprentice_payments_updated_at` sur `(updated_at)`
  - `idx_apprentice_payments_deleted_at` sur `(deleted_at)`

---

### 2.9 Table `realisations`
Réalisations de la galerie (photos des tenues confectionnées).

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant unique |
| `category` | `TEXT` | `String` | Non | Défaut `'Autre'` | Catégorie de tenue |
| `client_id` | `TEXT` | `String?` | Oui | FK `clients(id)` | Référence facultative du client |
| `caption` | `TEXT` | `String` | Non | Défaut `''` | Légende / description |
| `photo_path` | `TEXT` | `String` | Non | - | Chemin d'accès à l'image |
| `photo_hash` | `TEXT` | `String?` | Oui | - | Hash SHA256 de l'image |
| `photo_upload_state` | `TEXT` | `String` | Non | Défaut `'none'` | État d'upload |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |
| `deleted_at` | `INTEGER` | `DateTime?` | Oui | Millisecondes UTC | instant — Date de suppression logique |

- **Clé primaire** : `(id)`
- **Clé étrangère** : `client_id` -> `clients(id)`
- **Index** :
  - `idx_realisations_category` sur `(category)`
  - `idx_realisations_client_id` sur `(client_id)`
  - `idx_realisations_updated_at` sur `(updated_at)`
  - `idx_realisations_deleted_at` sur `(deleted_at)`

---

### 2.10 Table `settings`
Paramètres applicatifs clés/valeurs synchronisables (nom de l'atelier, etc.).

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (= `key`) | Identifiant (identique à `key`) |
| `key` | `TEXT` | `String` | Non | **UNIQUE** | Nom du paramètre (ex. `atelier_name`) |
| `value` | `TEXT` | `String` | Non | - | Valeur texte (ou JSON) |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de création |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de dernière mise à jour |

- **Clé primaire** : `(id)`
- **Index** :
  - `idx_settings_key` **UNIQUE** sur `(key)`
  - `idx_settings_updated_at` sur `(updated_at)`
- **Règle de gestion** : L'identifiant est rigoureusement identique à la clé (ex: `id = 'atelier_name'`) pour éviter tout doublon ou violation d'unicité lors d'une restauration. Une setting n'est jamais supprimée (aucun `deleted_at`).

---

### 2.11 Table `receipt_counters`
Compteurs séquentiels de numérotation des reçus (local uniquement, non synchronisé).

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `counter_name` | `TEXT` | `String` | Non | Clé primaire | Nom du compteur (`clients`, `apprentices`) |
| `last_value` | `INTEGER` | `int` | Non | Défaut `0` | Dernier numéro attribué |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Horodatage de l'incrémentation |

- **Clé primaire** : `(counter_name)`

---

### 2.12 Table `sync_outbox`
File d'attente locale des modifications à pousser vers le serveur de synchronisation.

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `id` | `TEXT` | `String` | Non | Clé primaire (UUIDv7) | Identifiant de l'événement |
| `entity` | `TEXT` | `String` | Non | - | Nom de la table cible (ex. `clients`) |
| `entity_id` | `TEXT` | `String` | Non | - | Identifiant de la ligne modifiée |
| `op` | `TEXT` | `String` | Non | - | Opération : `'upsert'` ou `'delete'` |
| `created_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Date de mise en file d'attente |
| `attempts` | `INTEGER` | `int` | Non | Défaut `0` | Nombre de tentatives d'envoi |
| `last_error` | `TEXT` | `String?` | Oui | - | Message d'erreur de la dernière tentative |

- **Clé primaire** : `(id)`
- **Index** :
  - `idx_sync_outbox_created_at` sur `(created_at)`
  - `idx_sync_outbox_entity_entity_id` sur `(entity, entity_id)`

*Remarque architecturale* : La table n'embarque aucun payload JSON. Lors de l'envoi au serveur, l'agent de synchronisation relit l'état courant de la ligne ciblée dans sa table respective.

---

### 2.13 Table `sync_state`
Table d'état technique local (non synchronisée avec le serveur).

| Colonne | Type SQLite | Type Dart | Nullable | Contrainte / Défaut | Description |
|---|---|---|---|---|---|
| `key` | `TEXT` | `String` | Non | Clé primaire | Clé d'état (ex: `pull_cursor`, `demo_seeded`) |
| `value` | `TEXT` | `String` | Non | - | Valeur stockée |
| `updated_at` | `INTEGER` | `DateTime` | Non | Millisecondes UTC | instant — Horodatage de mise à jour |

- **Clé primaire** : `(key)`

---

## 3. Mécanisme de Migration & Dumps

- **Version actuelle** : `schemaVersion = 1`
- **Activation des Clés Étrangères** : Configurée dans `beforeOpen` de la `MigrationStrategy` via `await customStatement('PRAGMA foreign_keys = ON;');`.
- **Fichier de dump du schéma** : `drift_schemas/drift_schema_v1.json`, généré via `drift_dev schema dump` pour les tests automatisés de migration future.
