# Atelier Couture — Mémoire du projet

> Fichier de référence pour l'agent. À relire au début de chaque session. Si une décision change, mettre ce fichier à jour (section « Décisions »).

## 1. Le projet

Application mobile de gestion pour **un seul atelier de couture** (tailleur / créateur de mode), pensée pour le marché ouest-africain : prix en **FCFA**, tissus locaux (Wax, Bazin, Brocart), modèles culturels (Boubou, ensembles pagne), gestion des apprentis.

Valeur apportée :
- Remplacer le carnet de mesures papier.
- Suivre la production et les délais (essayages, livraisons).
- Maîtriser l'argent (acomptes, reliquats, trésorerie).
- Encadrer les apprentis (écolage, tranches, reçus).
- Vitrine : catalogue de modèles et galerie de réalisations.

**Utilisateur : une seule personne, un seul appareil, un seul atelier.** Pas de comptes, pas de multi-utilisateur, pas de multi-appareil.

## 2. Rôle de l'agent

- **Le design et l'UI Flutter sont terminés** (Material 3, animations, splash, reçu animé). Ne pas les refaire ni les redessiner.
- Le travail restant est le **backend** : persistance locale, sync serveur, et remplacement de tout ce qui est factice (mock) par du réel.
- Toutes les données actuelles sont des **mockdata** et tous les branchements (WhatsApp, appel, PDF, PIN, notifications, photos) sont **faux**. Les remplacer, pas les contourner.
- Garder `dart analyze` à 0 avertissement et `flutter test` au vert après chaque changement.

## 3. État actuel du code (Flutter)

- Flutter 3, Material 3. État : `ChangeNotifierProvider` avec un `AppStore` mono-état, **100 % en mémoire**, alimenté par `_seed()`.
- Entités : `Client`, `Order`, `Measurement`, `Apprentice`, etc., avec `toMap()` / `fromMap()` déjà écrits.
- Design system : `Pal.cobalt`, `Pal.orange`, polices Manrope et Fraunces, moteur d'animation dans `motion.dart`.
- Écrans : accueil (tableau de bord), commandes (+ détail), clients et mesures (12 mesures + custom), apprentis (+ détail), reçus (`ReceiptScreen`), finances, modèles, galerie, verrouillage PIN, réglages.

Ce qui est faux aujourd'hui :
- Synchronisation serveur (non commencée).
- Rappels et notifications locales (traités dans un prompt séparé).

## 4. Principe directeur : offline-first

**La base locale est la source de vérité.** L'UI lit et écrit uniquement dans SQLite, jamais directement sur le réseau. La synchronisation est un processus séparé, en arrière-plan. L'app doit être 100 % utilisable en mode avion. « Synchroniser à chaque fois » ne veut jamais dire « attendre le réseau ».

Le serveur est un **miroir de sauvegarde** : le téléphone écrit, le serveur reçoit. Un seul appareil, donc pas de vrais conflits à gérer.

## 5. Stack retenue

| Couche | Choix |
|---|---|
| App | Flutter 3 / Material 3 |
| Base locale | **Drift** (SQLite typé), streams réactifs vers `AppStore` |
| Serveur API | **Laravel** (hébergement à décider, voir §10) |
| Base serveur | **Supabase Postgres** (offre gratuite) |
| Photos serveur | Supabase Storage (1 Go gratuit par projet) |
| Packages Flutter à ajouter | `drift`, `image_picker`, `path_provider`, `url_launcher`, `pdf`, `printing`, `flutter_local_notifications`, `flutter_secure_storage`, `local_auth` (option), `connectivity_plus`, `workmanager` |

Migration progressive : garder `AppStore` comme façade au début avec Drift derrière, puis extraire des repositories (`OrderRepository`, `ClientRepository`, …) derrière des interfaces, testables avec une base en mémoire. Ne pas réécrire les ~15 écrans en une fois.

## 6. Règles de données (non négociables)

- **UUID générés côté client** (UUIDv7 de préférence). Jamais d'auto-increment.
- Colonnes sur chaque table synchronisable : `id`, `created_at`, `updated_at`, `deleted_at` (suppression logique, sinon une suppression ne se propage pas).
- **Montants en entiers FCFA** (pas de centimes). Jamais de `double` pour l'argent.
- **Versements = registre append-only.** Acomptes et tranches d'écolage sont des lignes immuables. Le reliquat est **calculé**, jamais stocké comme champ modifiable. Corriger une erreur = ajouter une ligne d'annulation.
- **Photos** : chemin local + hash + état d'upload. Pas de blob en base. Compression avant stockage et avant envoi (data mobile chère, connexions lentes).
- Les entités gardent `toMap()` / `fromMap()` : c'est la base de la sérialisation vers Drift et vers l'API.

## 7. Synchronisation

Côté téléphone :
- Table `sync_outbox` (entité, id, opération, date). Chaque écriture et son entrée d'outbox sont enregistrées **dans la même transaction**.
- Envoi déclenché : juste après l'écriture, au retour du réseau, à l'ouverture de l'app, périodiquement en arrière-plan.
- Envoi par lots, retry avec délai croissant, **idempotent** (chaque changement porte son UUID).
- Réglages : afficher « Dernière sauvegarde : il y a X min » et le nombre d'éléments en attente.
- Photos envoyées séparément, en arrière-plan, avec leur propre état d'upload.

Côté serveur (Laravel) :
- `POST /sync/push` : reçoit un lot de changements, applique en upsert.
- `GET /sync/pull?since=<curseur>` : renvoie tout ce qui a changé depuis le curseur (restauration sur un nouveau téléphone).
- `POST /photos` : envoi vers Supabase Storage.
- Curseur = séquence croissante serveur (`server_seq`), **pas** un timestamp (horloges des téléphones peu fiables).
- Conflits : le plus récent gagne (`updated_at`), sauf versements (append-only, donc sans conflit).
- Proposition de départ, à confirmer : une table générique `records` (`entity`, `entity_id`, `data jsonb`, `updated_at`, `deleted_at`, `server_seq`), pour ne pas migrer le serveur à chaque évolution du modèle Flutter. Passer à des tables typées seulement si des requêtes serveur sont nécessaires.

## 8. Sécurité

- **Le PIN à 4 chiffres est un verrou d'interface uniquement.** Stocké haché dans `flutter_secure_storage`, vérifié localement. Biométrie en option (`local_auth`). **Il ne doit jamais servir à authentifier l'API** (10 000 combinaisons, trivial à forcer).
- **Pas de comptes utilisateur**, mais **l'API est protégée** par une **clé d'appareil** :
  1. Un code d'activation long (32+ caractères aléatoires) est généré pour l'atelier. Laravel n'en garde que le hash.
  2. Il est saisi ou scanné (QR) dans l'app à la première configuration et stocké dans `flutter_secure_storage`.
  3. Chaque requête l'envoie en `Authorization: Bearer`. Laravel compare (`hash_equals`), sinon 401.
  4. HTTPS obligatoire + rate limiting sur toutes les routes.
- La clé **`service_role` de Supabase reste uniquement côté Laravel**, jamais dans l'app. Flutter ne parle jamais directement à Supabase.
- **Téléphone perdu** : le développeur révoque l'ancien code et en émet un nouveau (pas d'OTP ni de SMS). Le nouveau téléphone récupère tout via `/sync/pull`.
- Données sensibles (noms, téléphones, mensurations, finances) : isolation stricte, jamais de données renvoyées sans clé valide.
- Optionnel : chiffrer la base locale (SQLCipher), clé dans le stockage sécurisé.

## 9. Supabase gratuit : pause et sauvegardes

- Les projets gratuits sont **mis en pause après environ 7 jours d'activité faible**. Quelques requêtes par jour suffisent d'après la doc Supabase.
- **Keep-alive quotidien** (pas hebdomadaire) : une vraie requête SQL (`SELECT` via Laravel), planifiée par un cron GitHub Actions ou le scheduler Laravel si l'hébergeur ne s'endort pas. La synchro normale compte déjà comme activité.
- Un projet en pause reste restaurable pendant 1 an, mais est hors ligne tant qu'on ne le relance pas.
- **Pas de sauvegardes automatiques en offre gratuite** : prévoir un `pg_dump` planifié vers un autre stockage.
- Vérifier ces règles à jour avant la mise en production, elles évoluent.

## 10. Décisions ouvertes

- **Hébergement de Laravel** : à choisir (VPS, PaaS gratuit, ou Edge Functions Supabase comme portail à la place de Laravel). Éviter un hébergeur gratuit qui s'endort, car il casserait le keep-alive.
- Table serveur générique (`records` jsonb) ou tables typées.
- Chiffrement de la base locale : oui / non.
- Export/import de sauvegarde en fichier (partage WhatsApp) en complément de la sync : utile, à décider.
- Modèle économique (freemium, limite de 20 commandes actives, paiement Mobile Money) : **hors périmètre pour l'instant**, mais le schéma ne doit pas l'empêcher.

## 11. Plan par phases

1. **Local (TERMINÉ)** : schéma Drift sync-ready v1, 10 tables synchronisables, 3 tables techniques locales, repositories complets, atomisme outbox sur toutes les écritures, migration intégrale d'`AppStore`, DemoSeeder par entité, agrégats financiers et ponctualité réactifs.
2. **Fonctions réelles** : `image_picker` + `path_provider` (photos), `url_launcher` (appel, WhatsApp pré-rempli), vrai PIN (haché, secure storage).
3. **Utilitaires** : PDF réel des reçus (envoi WhatsApp), notifications locales d'essayage et de livraison (reprogrammées au démarrage depuis la base, Android les perd après un redémarrage).
4. **Serveur et sync** : Laravel + Supabase, clé d'appareil, outbox, `push` / `pull`, photos, keep-alive, `pg_dump`.
5. **Plus tard** : licences / abonnement, multi-appareil (non prévu).

## 12. Consignes de travail

- Ne jamais stocker un solde ou reliquat modifiable : le calculer à partir des versements.
- Ne jamais utiliser `double` pour un montant.
- Ne jamais mettre un secret (clé `service_role`, code d'activation) dans le code Flutter ni dans Git.
- Ne jamais faire dépendre l'UI du réseau.
- Une migration de schéma Drift à chaque changement de table, avec version incrémentée et test.
- Avant de toucher à l'UI existante, demander : le design est validé.
- En cas de doute sur une décision de ce fichier, la poser à l'utilisateur plutôt que d'improviser.

## 13. Avancement de la migration Drift (branche feat/local-db)

### Schéma Drift v1
- Tables créées : `clients`, `measurements`, `modeles`, `orders`, `order_photos`, `client_payments`, `apprentices`, `apprentice_payments`, `realisations`, `settings`, `receipt_counters`, `sync_outbox`, `sync_state`.
- Schema dump généré dans `drift_schemas/drift_schema_v1.json`.
- `settings.id = key` (sans colonne `deleted_at`).
- `order_photos` gère chaque photo avec son upload state et sa position.
- Contraintes CHECK sur montants positifs et prix >= 0.
- `reconcileReceiptCounters()` implémenté pour recalculer le max du compteur après pull serveur.

### Tranche 1 (Clients & Mesures) — Terminée
- **Repositories** : `ClientRepository` / `DriftClientRepository`, `MeasurementRepository` / `DriftMeasurementRepository`.
- **Écritures atomiques** : toutes les écritures passent par `AppDatabase.writeWithOutbox` ou transaction multi-tables générant les entrées outbox.
- **Suppression logique** : `deleted_at = now`, pas de DELETE physique sur les tables synchronisables.
- **Règle suppression client** : refusée si le client a des commandes actives. Si aucune commande, le client et ses fiches de mesures sont supprimés logiquement dans la même transaction avec entrées outbox distinctes.
- **Seeding** : `DemoSeeder` n'écrit AUCUNE entrée dans `sync_outbox`. Conditionné à `kDebugMode`, table clients vide et absence de clé `'demo_seeded:clients'`.
- **Façade AppStore** : `AppStore.init()` charge la base, écoute les streams Drift et met à jour les caches de clients et mesures.
- **Tris** : insensibles à la casse et aux accents (`compareCaseAndAccentInsensitive`).
- **Écran de démarrage** : `SplashScreen` initialise `AppStore.init()` pendant la vidéo/animation et gère un écran d'erreur minimaliste en cas d'échec d'ouverture SQLite.

### Tranche 2 (Modèles & Réalisations) — Terminée
- **Repositories** : `ModeleRepository` / `DriftModeleRepository`, `RealisationRepository` / `DriftRealisationRepository`.
- **Écritures atomiques** : modifications et suppressions logiques via `AppDatabase.writeWithOutbox` générant une entrée dans `sync_outbox` (`modeles`, `realisations`).
- **Règle de suppression d'un modèle** : suppression logique autorisée même si référencé par des commandes. Les commandes conservent leur `modele_id`. `AppStore.modeleById(id)` résout les modèles y compris supprimés (cache complet) afin que l'UI commande affiche toujours son nom. Le catalogue (`AppStore.modeles`) exclut rigoureusement les modèles supprimés.
- **Règle de suppression d'un client lié à des réalisations** : autorisée. La réalisation conserve son `client_id` en base ; l'UI affiche une valeur de repli (« Client supprimé ») sans plantage.
- **Photos** : convention `demo:N` préservée dans `photo_path`, `photo_hash = null`, `photo_upload_state = 'none'`.
- **DemoSeeder par entité & migration** : remplacement de la clé unique `'demo_seeded'` par trois clés distinctes (`'demo_seeded:clients'`, `'demo_seeded:modeles'`, `'demo_seeded:realisations'`). Si l'ancienne clé `'demo_seeded'` = '1' est détectée, elle est automatiquement convertie en `'demo_seeded:clients'` sans réinsérer les clients existants. Zéro écriture dans `sync_outbox`.
- **Tri et filtrage** : tri des modèles et filtre des réalisations insensibles à la casse et aux accents (`compareCaseAndAccentInsensitive`, `equalsCaseAndAccentInsensitive`).

### Tranche 3 (Commandes, Photos de commande, Versements clients & Reçus) — Terminée
- **Repositories** : `OrderRepository` / `DriftOrderRepository`, `PaymentRepository` / `DriftPaymentRepository`.
- **Écritures atomiques & Outbox** :
  - Création de commande avec acompte (`createWithDeposit`) en UNE transaction SQLite atomique : `orders` + `order_photos` + `client_payments` + attribution séquentielle du numéro de reçu via `receipt_counters('clients')` + entrées d'outbox respectives. Rollback intégral en cas d'erreur.
  - Diffing des photos de commande dans `saveOrder` : insertion des nouvelles photos, mise à jour de la `position` si changée, suppression logique (`deleted_at`) des photos retirées, avec outbox par ligne.
- **Règles de suppression & modification** :
  - Suppression d'une commande refusée si elle comporte au moins un versement NON annulé. Si tous les versements sont annulés, suppression logique de la commande et de ses `order_photos` (les versements restent conservés dans la base).
  - Modification de prix refusée si `price < total_versements_actifs`.
  - Suppression d'un client : la règle « au moins une commande active » vérifiée directement en SQL via `OrderRepository.hasNonDeletedOrdersForClient(clientId)`.
- **Versements & Annulation** :
  - Reliquat calculé dynamiquement : `prix - somme(versements actifs)`. Un seul accesseur central `activePaymentsOf(orderId)` dans `AppStore`.
  - Refus d'un versement dont le montant dépasse le reliquat restant.
  - Annulation (`voidClientPayment`) : pose `voided_at`, `void_reason`, `updated_at`, outbox `upsert`. Double annulation strictement rejetée. Jamais de suppression physique (`DELETE`) ni de modification de montant ou de date.
  - Versement annulé affiché en atténué avec mention « Annulé (motif) » dans l'historique.
- **Numéros de reçus & Affichage (Reçu = photographie immuable)** :
  - Numéro stocké sous forme d'entier séquentiel unique dans `receipt_number`.
  - Format d'affichage : préfixe distinctif `CMD-0001` pour les clients (différencié du format `0001` des apprentis).
  - Valeurs figées et immuables écrites dans la même transaction que le versement : `order_price_at_payment` et `balance_after` (`CHECK (balance_after >= 0)`).
  - Reçu en photographie immuable : `ReceiptScreen` affiche directement ces valeurs stockées. Annuler un versement plus ancien ou modifier le prix après coup ne modifie aucun reçu émis.
  - Tampon de reçu : « ANNULÉ » en rouge (`Pal.thread`) si le versement est annulé ; « SOLDÉ » si `balance_after == 0`, « VERSÉ » si `balance_after > 0` (aucun tampon « PAYÉ »).
  - Le reliquat courant de la commande reste dynamique (`prix - somme(versements actifs)`).
- **Statut de livraison & `delivered_at`** :
  - `orders.delivered_at` (instant UTC millisecondes nullable) : renseigné lors du passage au statut `'livree'`, remis à null en cas de retour à un statut antérieur, écrit dans la même transaction avec outbox.
- **Dates jour-seul vs instants & fuseaux horaires** :
  - Conventions documentées dans `docs/schema-drift.md` :
    - « instant » : point précis dans le temps UTC (`created_at`, `updated_at`, `deleted_at`, `paid_at`, `voided_at`, `delivered_at`, `taken_at`).
    - « jour calendaire (UTC minuit) » : date sans heure (`delivery_date`, `fitting_date`, `start_date`, `next_due`), normalisée en UTC calendaire (`DateTime.utc(year, month, day)`) garantissant un aller-retour exact sans décalage quel que soit le fuseau horaire (`Africa/Lagos` UTC+1, `America/New_York` UTC-5).
  - Les calculs de tableau de bord (délais, retards) restent en Dart avec bornes en heure locale.
- **DemoSeeder** :
  - Commandes + photos + versements démo insérés ensemble sous la clé `'demo_seeded:orders'` en debug uniquement, sans écriture dans `sync_outbox`.
  - Numéros de reçus séquentiels attribués aux versements démo et compteur `receipt_counters('clients')` calé dessus.
  - `reconcileReceiptCounters()` exécuté à l'initialisation de l'atelier pour garantir la cohérence continue des compteurs.

### Tranche 4 (Apprentis, Versements d'écolage & Reçus) — Terminée
- **Repositories** : `ApprenticeRepository` / `DriftApprenticeRepository`, `ApprenticePaymentRepository` / `DriftApprenticePaymentRepository`.
- **Écritures atomiques & Outbox** :
  - Sauvegarde et suppression logique (`deleted_at`) d'apprentis via `AppDatabase.writeWithOutbox` (entité `'apprentices'`).
  - Ajout de versement d'écolage (`addPayment`) en UNE transaction SQLite atomique : `apprentice_payments` + calcul immuable de `total_fee_at_payment` et `balance_after` + incrémentation du compteur `receipt_counters('apprentices')` + entrée d'outbox `'apprentice_payments'`. Rollback intégral en cas d'erreur sans trou dans la numérotation des reçus.
- **Règles métier & Contrôles** :
  - Suppression d'un apprenti refusée s'il possède au moins un versement NON annulé (`StateError`). Si tous ses versements sont annulés, suppression logique de l'apprenti autorisée (les versements sont conservés dans la base).
  - Modification de formation refusée si `totalFee < total_versements_actifs` (`ArgumentError`).
  - Refus d'un versement dont le montant dépasse le reliquat restant (`ArgumentError`).
- **Versements & Annulation** :
  - Reliquat calculé dynamiquement : `total_fee - somme(versements actifs)` via les accesseurs centralisés dans `AppStore` (`activePaymentsOfApprentice(id)`, `apprenticePaid(id)`, `apprenticeRemaining(id)`, `totalApprenticeRemaining`).
  - Annulation (`voidApprenticePayment`) : pose `voided_at`, `void_reason`, `updated_at`, outbox `upsert`. Double annulation rejetée. Jamais de suppression physique (`DELETE`).
  - Versement annulé affiché en atténué (opacité 0.55) avec badge « Annulé (motif) » dans la liste des versements. L'icône de corbeille est remplacée par l'icône de blocage « Annuler » ouvrant une boîte de dialogue avec saisie obligatoire d'un motif.
- **Numéros de reçus & Affichage (Reçu = photographie immuable)** :
  - Compteur dédié distinct dans `receipt_counters` sous la clé `'apprentices'`.
  - Format d'affichage : numéro séquentiel sur 4 chiffres `0001` (sans préfixe).
  - Reçu en photographie immuable : `ReceiptScreen` affiche directement `totalFeeAtPayment` et `balanceAfter` stockés lors du versement. Les tampons sont « VERSÉ » (reliquat > 0), « SOLDÉ » (reliquat == 0) et « ANNULÉ » en rouge si le versement est annulé. Annuler un versement plus ancien ou modifier le coût de formation ne modifie pas les reçus antérieurs déjà émis.
  - Libellé dynamique dans `ReceiptScreen` : « Total formation » pour les apprentis, « Prix total » pour les clients.
- **Dates jour-seul vs fuseaux horaires** :
  - `start_date` et `next_due` normalisés en « jour calendaire (UTC minuit) » via `normalizeDate`, garantissant la neutralité de fuseau horaire (`Africa/Lagos` UTC+1, `America/New_York` UTC-5).
  - Échéancier et retards calculés en Dart avec bornes en heure locale.
- **DemoSeeder** :
  - 3 apprentis ('a0', 'a1', 'a2') et 5 versements ('ap0'..'ap4') insérés ensemble sous la clé `'demo_seeded:apprentices'` en debug uniquement, sans écriture dans `sync_outbox`.
  - Compteur `receipt_counters('apprentices')` calé sur 5.
  - `reconcileReceiptCounters()` appelé à l'initialisation de l'atelier.

### Tranche 5A (Réglages persistés & Notifications) — Terminée
- **Repository** : `SettingsRepository` / `DriftSettingsRepository` sur la table `settings` (`id = key`, `value`, `created_at`, `updated_at`).
- **Écritures & Outbox** :
  - `upsert` par `AppDatabase.writeWithOutbox` (entité `'settings'`, `entityId = key`, `op = 'upsert'`).
  - Aucun `deleted_at`, aucune suppression physique.
  - Règle de sécurité : interdiction formelle de stocker le hash du PIN, la clé d'appareil ou le curseur de synchronisation dans `settings`.
- **Clés de réglages** :
  - `atelier_name` : nom de l'atelier (défaut : `"Atelier Angela"`).
  - `notif_delivery` : rappels de livraison (`'true'` / `'false'`, défaut `true`).
  - `notif_fitting` : rappels d'essayage (`'true'` / `'false'`, défaut `true`).
  - `notif_payments` : rappels de versements (`'true'` / `'false'`, défaut `true`).
  - `notif_late` : alertes de retard (`'true'` / `'false'`, défaut `true`).
- **Valeurs par défaut dans le code** : aucune ligne écrite en base tant que l'utilisateur ne modifie aucun paramètre. `DemoSeeder` n'écrit aucun réglage.
- **Façade AppStore** : getters synchrones réactifs alimentés par un stream `watchAll()`, mises à jour asynchrones (`setAtelierName`, `setNotifDelivery`, etc.).

### Tranche 5B (Finances agrégées & Ponctualité) — Terminée
- **Repository** : `FinanceRepository` / `DriftFinanceRepository` (lectures seules, streams réactifs Drift vers `AppStore`).
- **Recouvrement clients & apprentis** :
  - Recouvrement clients : somme sur les commandes non supprimées de `max(0, prix - versements actifs)`. Une commande livrée non soldée est comptabilisée comme dette. Jointure `LEFT OUTER JOIN` avec condition `voided_at IS NULL` dans le `ON` (pour conserver les commandes sans versement actif).
  - Recouvrement apprentis : somme sur les apprentis non supprimés de `max(0, total_fee - versements actifs)`.
  - Cohérence vérifiée par tests automatisés : la somme SQL égale rigoureusement la somme des reliquats de l'accesseur central Dart (`remainingOf`, `apprenticeRemaining`) sur le jeu de démo et sur graine pseudo-aléatoire (seed 42).
- **Encaissements du mois & Graphique 6 mois** :
  - Calculés en heure locale de l'appareil : bornes `[début du mois local, début du mois local suivant)` converties en millisecondes UTC.
  - Périmètre unifié : cumule versements clients actifs + versements apprentis actifs (aligné sur l'UI).
  - Versements annulés (`voided_at IS NOT NULL`) exclus de TOUS les totaux, y compris pour les mois passés.
  - Graphique : 6 derniers mois civils locaux glissants, mois courant inclus, du plus ancien au plus récent. Mois sans encaissement = 0. Les 5 anciennes valeurs codées en dur sont supprimées. La dernière barre égale rigoureusement le total du mois courant.
- **Taux de ponctualité révisé** :
  - Population : commandes non supprimées au statut `'livree'` avec `delivered_at` non nul, livrées dans les 90 derniers jours (fenêtre glissante `[now - 90 jours, now]`).
  - Commande « à temps » : jour calendaire local de `delivered_at` <= jour calendaire promis (`delivery_date`, normalisé à minuit UTC).
  - Taux = `(commandes à temps) / (commandes de la fenêtre)`, arrondi à l'entier pourcent.
  - Affichage : `${(rate * 100).round()} % dans les délais`, ou « — » si aucune commande n'a été livrée dans la fenêtre de 90 jours (évite toute division par zéro).
- **DemoSeeder** : `delivered_at` renseigné sur les 3 commandes démo livrées (`o12` et `o14` à temps, `o13` en retard de 1 jour).

### Tranche 5C (Nettoyage, audit outbox et clôture couche locale) — Terminée
- **Nettoyage** : suppression du code mort en mémoire, passage de `AppStore.init({bool seedDemo = true})` pour supporter l'initialisation sur base vierge sans seeding en test.
- **Éléments restant mock / volatils** :
  1. Partage et contact : boutons WhatsApp / SMS / appel (SnackBar au lieu d'`url_launcher`).
  2. Reçus : boutons PDF et impression thermique (SnackBar au lieu de `pdf` / `printing`).
  3. Code PIN : `LockScreen` maquette acceptant tout code à 4 chiffres (en attente de `flutter_secure_storage`).
  4. Notifications système : interrupteurs persistés mais aucune alarme locale planifiée (en attente de `flutter_local_notifications`).
- **Audit Outbox & Invariants** :
  - Test d'invariant automatisé (`test/db/outbox_audit_test.dart`) déroulant un scénario complet sur base vide touchant les 10 entités synchronisables.
  - Vérifié : chaque ligne de chaque table synchronisable a au moins une entrée correspondante `(entity, entity_id)` dans `sync_outbox`.
  - Vérifié : chaque opération `op = 'delete'` dans l'outbox correspond rigoureusement à une ligne dont `deleted_at` est non nul.
- **Audit des écritures** :
  - Aucune écriture SQL directe hors de `lib/data/`.
  - Toutes les écritures de `lib/data/` passent soit par `writeWithOutbox`, soit par une transaction atomique générant systématiquement les entrées d'outbox requises.
- **Revue du schéma Drift v1** :
  - `docs/schema-drift.md` harmonisé pour expliciter que `fitting_date` est un instant préservant l'heure d'essayage.
  - Schéma v1 prêt à être gelé pour la synchronisation.

### Tranche Photos (Photos réelles, stockage local et dédoublonnage) — Terminée
- **Service `PhotoStorage`** (`lib/data/services/photo_storage.dart`) :
  - Interface abstraite injectée via `Provider<PhotoStorage>` dans `main.dart`. Implémentation `DefaultPhotoStorage` utilisant `image_picker` et `path_provider`.
  - Acquisition caméra / galerie avec compression `image_picker` (1600x1600, qualité 80). Redressement EXIF automatique appliqué aux pixels et métadonnées GPS purgées par les OS.
  - Hachage SHA-256 des octets compressés : nommage déterministe `photos/<hash>.jpg`.
  - Dédoublonnage : si le fichier existe déjà, il n'est pas réécrit et son chemin relatif est réutilisé.
  - Écriture atomique : écriture dans `photos/<hash>.jpg.tmp` puis renommage atomique vers `photos/<hash>.jpg`. Aucun fichier corrompu en cas de coupure.
  - Support d'Android `retrieveLostData()` pour restaurer les clichés si le processus a été tué par le système.
- **Chemins relatifs & Résolveur d'affichage** :
  - Seul le chemin relatif `photos/<hash>.jpg` (ou `demo:N`) est stocké en base SQLite (`photo_path`).
  - Aucun chemin absolu n'est persisté en base (immunité contre les changements de répertoire d'application sous iOS/Android).
  - Résolution dynamique via `PhotoStorage.getAbsolutePath()`.
  - Optimisation vignette : `PhotoThumb` applique `cacheWidth` sur les vignettes réduites (`(size * 2).clamp(100, 1600)`), évitant le décodage plein format en mémoire dans les listes. Plein format réservé au visualiseur `openPhoto`.
  - Fallback neutre sans plantage si le fichier est manquant ou invalide (`Icons.broken_image_outlined`).
- **Règles de cohérence des colonnes (Décision 4)** :
  - Centralisées dans `lib/data/utils/photo_metadata.dart` (`resolvePhotoMetadata`) pour `modeles`, `realisations`, `orders` et `order_photos`.
  - `demo:N` ou vide : `photo_hash = null`, `photo_upload_state = 'none'`.
  - Photo réelle (`photos/<hash>.jpg`) : `photo_hash = <hash>`, `photo_upload_state = 'pending'`.
- **Politique de suppression et règles de synchronisation future** :
  - Aucun fichier photo physique n'est supprimé dans cette tranche lors de la suppression logique d'une entité ou du remplacement d'une photo (évite les suppressions orphelines partagées par dédoublonnage).
  - Règle de restauration lors de la future sync : si la ligne SQLite possède un `photo_hash` et que le fichier local manque, la sync le téléchargera depuis Supabase Storage.
  - Ordre imposé lors de la sync : données d'abord (SQLite / Outbox), photos ensuite (fichiers binaires en arrière-plan).

### Tranche Photos (Rattrapage EXIF/GPS, Redressement & Contraintes CHECK — Partie A) — Terminée
- **Nettoyage binaire EXIF / GPS & Redressement orientation** (`lib/data/utils/jpeg_sanitizer.dart`) :
  - `readExifOrientation(bytes)` : analyse les segments JPEG pour extraire l'orientation EXIF.
  - Si orientation != 1 : décodage via `package:image`, redressement physique des pixels (`bakeOrientation`), purge d'EXIF, puis réencodage.
  - Si orientation == 1 ou image droite : découpage binaire sans perte des segments `APP1` (Exif/GPS/XMP), `APP13` (IPTC), `COM`. Aucun réencodage, zéro perte de qualité.
  - Le fichier JPEG final ne contient AUCUNE métadonnée EXIF / GPS / IPTC / XMP.
  - Calcul SHA-256 déterministe sur les octets finaux assainis.
- **Contraintes CHECK du schéma Drift v1** (`docs/schema-drift.md`, `drift_schemas/drift_schema_v1.json`) :
  - `CHECK (photo_upload_state IN ('none', 'pending', 'uploaded', 'failed'))` sur `modeles`, `realisations`, `orders`, `order_photos`.
  - `CHECK (op IN ('upsert', 'delete'))` sur `sync_outbox`.
  - Pas de CHECK sur `orders.status` pour préserver l'extensibilité des statuts de production.
  - Schéma v1 prêt pour le gel final.

### Tranche Contacts (Appels, WhatsApp et SMS réels — Partie B) — Terminée
- **Service `ContactLauncher`** (`lib/data/services/contact_launcher.dart`) :
  - Interface abstraite injectée via `Provider<ContactLauncher>`. Implémentation `DefaultContactLauncher` utilisant `url_launcher: ^6.3.3`.
  - Lancement direct sans dépendre de `canLaunchUrl`, gestion gracieuse des retours `false` ou exceptions via des messages clairs.
  - Schémas configurés : `<queries>` (`tel`, `sms`, `https`) dans `AndroidManifest.xml` et `LSApplicationQueriesSchemes` dans `Info.plist`.
  - Points d'accroche : appel direct `tel:`, SMS avec pré-remplissage (`sms:` avec `?body=` Android / `&body=` iOS), WhatsApp sans ajout au carnet d'adresses (`https://wa.me/<chiffres>?text=<message>`).
- **Normalisation téléphonique** (`lib/data/utils/phone_normalizer.dart`) :
  - Fonction pure appliquée au moment du déclenchement, sans jamais altérer les numéros stockés en base.
  - Nettoyage des espaces, tirets, points, parenthèses. Conservation du `+` initial. `00` initial converti en `+`.
  - Préfixe d'indicatif par défaut issu du réglage `'default_country_code'` (défaut `"228"`, Togo). Conservation du `0` initial si présent.
  - Validation de 7 à 15 chiffres. Messages clairs si absent (« Aucun numéro enregistré ») ou invalide (« Numéro invalide »).
- **Modèles de messages en français** (`lib/data/utils/message_templates.dart`) :
  - Modèles sans civilité présumée (« Bonjour {nom} » sans « Mme/M. »), montants en FCFA, nom de l'atelier lu depuis les réglages.
  - Reçu WhatsApp : récapitulatif textuel complet avec données figées du versement (solde après et total à date du reçu). Boutons PDF et thermique maintenus avec SnackBar d'attente.
- **Aucune écriture en base, aucune entrée outbox** : ces actions sont des interactions de communication sans impact sur les données locales.

### Tranche Sécurité & PIN (Verrouillage PBKDF2, Paliers et Récupération — Partie C) — Terminée
- **Limites du PIN (règle absolue)** :
  - Le PIN est un **verrou d'interface utilisateur uniquement**.
  - Il **n'authentifie JAMAIS l'API** et **ne chiffre pas la base SQLite**.
  - Avec 4 chiffres (10 000 combinaisons), le hash PBKDF2 n'est qu'un frein calculatoire ; la véritable sécurité repose sur le stockage sécurisé matériel (`flutter_secure_storage`) et le verrouillage progressif.
- **Dérivation PBKDF2-HMAC-SHA256** (`lib/data/services/pin_security_service.dart`) :
  - Librairie officielle `package:cryptography: ^2.9.0`.
  - 30 000 itérations PBKDF2-HMAC-SHA256 mesurées pour ~300-370 ms de temps de dérivation.
  - Sel aléatoire de 16 octets (`Random.secure()`).
  - Dérivation hors du thread UI (`Isolate.run`).
  - Comparaison en temps constant (`constantTimeEquals`) contre les attaques temporelles.
- **Stockage sécurisé (`flutter_secure_storage: ^11.2.0`)** :
  - Stocke uniquement : sels (hex), hashs PBKDF2 (hex), nombre d'itérations, compteur d'échecs, échéance de verrouillage et horodatage « dernière vue ».
  - Aucun secret en clair (ni PIN, ni code de récupération). Rien en base Drift, ni dans les réglages, ni dans les SharedPreferences ordinaires.
  - Android : `android:allowBackup="false"` dans `AndroidManifest.xml` et `AndroidOptions(resetOnError: false)` pour éviter la désynchronisation clé/données lors d'une sauvegarde cloud.
  - iOS : premier lancement nettoyant le Keychain résiduel en cas de réinstallation.
  - Gestion d'erreur fatale : un échec d'accès au stockage sécurisé est traité comme une erreur de sécurité bloquante (`SecurityErrorScreen`), jamais comme « aucun PIN ». La base n'est jamais exposée sans PIN vérifié.
- **Verrouillage progressif & Garde anti-rembobinage d'horloge** :
  - Paliers : < 5 échecs : pas de blocage ; 5 échecs : 30 s ; 6 : 1 min ; 7 : 5 min ; 8 : 15 min ; >= 9 : 1 h (palier maximum).
  - **Incrément avant vérification** : le compteur d'échecs et le verrou éventuel sont systématiquement persistés dans le secure storage AVANT le calcul du hash. Tuer le processus entre deux essais ne permet pas d'échapper au compteur d'échecs.
  - **Remise à zéro** : tout succès de déverrouillage réinitialise immédiatement le compteur à 0.
  - **Garde d'horloge** : horodatage `last_seen_time` persistant. Si l'horloge système est reculée, l'échéance `locked_until` est compensée du delta correspondant afin que reculer l'heure ne raccourcisse jamais la durée de verrouillage.
- **Politique de verrouillage automatique & `runExternal`** (`lib/data/services/app_lock_manager.dart`) :
  - Verrouillé au démarrage à froid (exige la saisie du PIN avant l'accès aux données).
  - Verrouillé au retour d'arrière-plan si l'inactivité dépasse 2 minutes (`backgroundLockTimeout = Duration(minutes: 2)`).
  - **Immunité des actions externes (`runExternal`)** : `ExternalActionTracker.runExternal()` protège les lancements d'appareil photo, galerie (`PhotoStorage.pick`), appels, WhatsApp et SMS (`ContactLauncher`) : aucune mise en arrière-plan pendant une action externe volontaire ne déclenche le verrou au retour.
  - Android `retrieveLostData` : si l'activité a été tuée pendant une prise de photo, la photo est récupérée et persistée AVANT l'affichage du verrou.
- **Code de récupération (12 caractères)** :
  - Généré à la création du PIN : 12 caractères de l'alphabet Crockford Base32 sans ambiguïté (`23456789ABCDEFGHJKMNPQRSTUVWXYZ`), format `XXXX-XXXX-XXXX`.
  - Affiché UNE SEULE FOIS avec bouton de copie dans le presse-papier (`RecoveryCodeScreen`).
  - Stocké uniquement sous forme de hash PBKDF2 (sel 16 octets distinct).
  - Lien « Code d'accès oublié ? » sur l'écran de déverrouillage : saisie du code de récupération (soumise aux mêmes paliers d'échecs) permettant de réinitialiser le PIN sans perte de données.
  - Aucune réinitialisation destructrice locale. Sans PIN ni code de récupération, affiche un message d'orientation vers le support.
  - **Question ouverte pour la suite** : procédure de récupération sans code après la mise en place de la synchronisation (réémission d'une clé d'appareil ou validation administrative côté serveur Laravel).

### Gel du Schéma Drift v1 (`tag: schema-v1-frozen`)
- **Règle absolue d'évolution du schéma** :
  - Le schéma v1 (`drift_schemas/drift_schema_v1.json`) est **strictement gelé** et ne doit plus être modifié.
  - À partir du tag `schema-v1-frozen`, toute modification de table (ajout de colonne, nouvelle table, index) impose d'incrémenter `schemaVersion` (`schemaVersion + 1`).
  - Chaque incrément de schéma doit faire l'objet d'une migration écrite dans `AppDatabase.migration` ET testée à partir du dump JSON précédent via la suite de tests (`test/db/schema_v1_frozen_test.dart`).
- **Signature et Release Android** :
  - Configuration de signature via `android/key.properties` (exclu par `.gitignore`) avec fallback debug explicite.
  - Procédure de compilation et conservation de clé privée documentées dans `docs/release.md`.
  - Identifiant d'application définitif : `com.digitalvision.angela_dress` (applicationId, namespace, MainActivity).

### Tranche Reçus PDF & Impression Thermique (Partie B) — Terminée
- **Service `ReceiptPdfGenerator`** (`lib/data/services/receipt_pdf_generator.dart`) :
  - Génération 100 % locale sans réseau via `package:pdf: 3.12.0` et `package:printing: 5.14.3`.
  - Format ticket thermique : rouleau 80 mm (`PdfPageFormat.roll80`), hauteur dynamique adaptée au contenu.
  - Police TTF embarquée : `assets/fonts/Manrope-400.ttf` et `Manrope-700.ttf` intégrées via `pw.Font.ttf` et `pw.ThemeData.withFont`. Aucun caractère manquant ni carré : support complet des accents (`É`, `è`, `à`), apostrophes typographiques (`’`), tirets longs (`—`) et espaces fines.
  - Données strictement immuables/figées : construit UNIQUEMENT à partir des champs figés du versement (`receiptNumber`, `amount`, `orderPriceAtPayment`/`totalFeeAtPayment`, `balanceAfter`, `paidAt`, `note`, `voidedAt`, `voidReason`) + `beneficiaryName`, `itemDetail`, `atelierName`. Jamais le solde courant.
  - Tampons stricts :
    - `VERSÉ` si `balanceAfter > 0`.
    - `SOLDÉ` si `balanceAfter <= 0`.
    - `ANNULÉ` avec date et motif si `isVoided == true`.
  - Métadonnées du document : titre, auteur (nom d'atelier), créateur ('Angela Déesse'), date déterministe.
  - Fichier temporaire standardisé et assaini : `Recu_CMD-0007_<nom-nettoye>.pdf` (sans accents, sans espaces, caractères alphanumériques et tirets uniquement) dans `getTemporaryDirectory()`. Aucun stockage en base, aucun fichier dans photos/, aucune entrée d'outbox.
- **Intégration UI `ReceiptScreen`** (`lib/screens/receipt_screen.dart`) :
  - Bouton « PDF » (AppBar et action inférieure) : génère le PDF et ouvre la feuille de partage système (`Printing.sharePdf`) sous la garde de `runExternal` (pas de verrouillage PIN intempestif au retour). Nettoyage du fichier temporaire après partage.
  - Bouton « Imprimer » (AppBar) : ouvre la boîte de dialogue d'impression système (`Printing.layoutPdf`) sous la garde de `runExternal`.
  - En cas d'erreur de génération, affichage d'un message non-bloquant « Impossible de créer le reçu » sans planter l'interface.
  - Bouton texte « WhatsApp » conservé à l'identique.

### Tranche Identité de Marque Angela Déesse (Partie 0) — Terminée
- **Nom officiel et cohérence globale** (`lib/core/app_brand.dart`) :
  - Constante centrale `AppBrand.appName = 'Angela Déesse'` et `AppBrand.defaultAtelierName = 'Angela Déesse'`.
  - Tout texte statique (titre de l'application, `onGenerateTitle`, libellé Android `android:label="@string/app_name"`, iOS `CFBundleDisplayName`) porte « Angela Déesse ».
  - Tout texte dynamique lit `AppStore.atelierName` (`settings.atelier_name`), avec repli sur `AppBrand.defaultAtelierName`.
  - Conservation stricte des identifiants techniques invisibles : `applicationId com.digitalvision.angela_dress` et package Dart `angela_dress` sont volontairement conservés pour ne pas casser l'identité de l'application Android ni le package local.
  - Gabarits de messages unifiés avec la mention « chez {atelier} ».
- **Unification des numéros de reçus** :
  - Fonction unique `formatReceiptNumber(type, n)` dans `lib/core/format.dart` produisant `CMD-0001` et `APP-0001` sur tous les écrans, reçus PDF et messages.
- **Identité visuelle de notification** :
  - Ressource drawable vectorielle monochrome Android `ic_stat_notification` (blanc sur transparent) pour éviter les carrés blancs sous Android.
  - Bouton contextuel WhatsApp ajouté sur chaque alerte dans `NotificationsScreen` via `ContactLauncher` et `MessageTemplates`.

### Tranche Moteur d'Alertes Unique & Centre In-App (Parties A & B) — Terminée
- **Moteur d'alertes unique (`AlertEngine`)** (`lib/data/services/alert_engine.dart`) :
  - Source UNIQUE pour les alertes in-app (`currentAlerts(now)`) et les rappels futurs (`plannedReminders(now)`).
  - Purement Dart, testable avec horloge injectée.
  - Familles couvertes : livraisons (en retard, aujourd'hui, demain, dans 2 jours), essayages (aujourd'hui avec heure/sans heure, demain), échéances d'apprentis (dépassée, aujourd'hui, demain, approche <= 7 jours), soldes en attente (commandes prêtes avec solde dû > 0).
  - Clés stables formatées en « famille:étape:idEntité:jourCible » (l'étape fait partie de la clé, changeant naturellement d'un jour à l'autre).
  - Sévérité ordonnée : `late` (0) > `today` (1) > `tomorrow` (2) > `upcoming` (3) > `info` (4).
  - Confidentialité : corps d'alerte sans aucun montant (`$client · $titre` ou `$apprenti · Formation`).
  - Textes d'alertes centralisés dans `lib/data/utils/alert_strings.dart`.
  - Invariant vérifié : pour chaque rappel planifié à l'instant T, `currentAlerts` à T contient l'alerte correspondante.
- **Centre de notifications in-app (`NotificationCenterService`)** (`lib/data/services/notification_center_service.dart`) :
  - Stockage des états vu / non vu hors base SQLite Drift et hors settings (aucun impact sur la synchronisation future) via `shared_preferences: ^2.5.6`.
  - Nettoyage automatique des clés d'alertes disparues ou lues depuis plus de 60 jours (`prune`).
  - Compteur réactif d'alertes non vues affiché sur l'icône de notification (`IconBox` avec badge numérique et pastille orange) dans l'en-tête `AppHeader` / `HomeScreen`.
  - Dans `NotificationsScreen` : alertes non vues en évidence avec pastille orange pulsante, alertes vues atténuées à 65 % d'opacité.
  - Toucher une alerte la marque automatiquement comme vue et navigue vers l'entité concernée (`OrderDetailScreen` ou `ApprenticeDetailScreen`).
  - Bouton « Tout marquer comme vu » dans la barre d'action.
  - Disparition automatique : les alertes disparaissent dès que leur condition métier disparaît (commande livrée, solde payé, apprenti soldé).
  - Mémorisation de destination post-PIN (`pendingOpenNotifications`) assurant qu'un déverrouillage depuis une notification ouvre `NotificationsScreen` après validation du code sans navigation prématurée.
- **Limites connues (décision 29)** :
  - (a) Pas de rappels manuels personnalisés (exigeraient une table dédiée dans le schéma Drift v2).
  - (b) Pas de rappel « sauvegarde en retard » avant la mise en œuvre de la synchronisation serveur.
  - (c) Push serveur à étudier après la synchronisation.
  - (d) Les actions « Fait » et « Reporter » d'une notification système (Partie C) n'affectent pas les états in-app car le gestionnaire natif d'arrière-plan n'accède à aucune donnée.

### Tranche Rappels Système & Regroupement Anti-Fatigue (Partie C) — Terminée
- **Service `SystemReminderService`** (`lib/data/services/system_reminder_service.dart`) :
  - Planification push locale sans serveur ni réseau via `flutter_local_notifications: 22.3.3` et `timezone: 0.11.2`.
  - Canal sonore `rappels_sonores_v1` avec son d'alarme système (`AudioAttributesUsage.alarm`, `AndroidNotificationCategory.alarm`), vibration active, importance et priorité maximales.
  - Confidentialité : `NotificationVisibility.private` (masqué sur écran de verrouillage).
  - Deux boutons d'action natifs Android sur chaque notification :
    - « Fait » : annule immédiatement la notification sans ouvrir l'application.
    - « Reporter 10 min » : replanifie la même alarme à +10 minutes (id 31-bit distinct réservé dans la plage snooze `(id | 0x40000000) & 0x7FFFFFFF`).
  - Gestionnaire d'action en arrière-plan `@pragma('vm:entry-point') notificationActionBackgroundHandler` isolé de SQLite et du réseau.
  - Clic sur la notification : mémorise `NotificationCenterService.pendingOpenNotifications = true`, ouvrant directement l'application sur le centre de notifications une fois le code PIN saisi avec succès.
- **Regroupement anti-fatigue à la minute (`AlertEngine.groupedPlannedReminders`)** :
  - Fusion à la minute exacte des rappels simultanés : si n = 1, notification individuelle ; si n >= 2, titre « n rappels », corps jusqu'à 4 lignes + « + k autres ».
  - Identifiant 31-bit stable déterministe (sans collision).
  - Plafond strict de 120 notifications planifiées (sécurité Android).
- **Replanification automatique et debounced (Décision 20)** :
  - Replanification déclenchée au démarrage de l'app, au retour en premier plan (`resumed`), et lors de tout changement d'entité (commandes, apprentis, réglages).
  - Temporisation anti-rafale (debounce de 500 ms) pour protéger le système.
  - Idempotence : `cancel` ciblé des notifications de type `plan` uniquement, préservant les reports temporaires `snooze`.

### Tranche Moteur d'Alarmes & Notifications Fiables (Refonte v2) — Terminée
- **Moteur d'alarme natif Android (`AlarmActivity` & `AlarmService`)** :
  - Déclenchement de type réveil via `AlarmManager.setAlarmClock()` indépendant du moteur Flutter.
  - Service de premier plan Kotlin (`AlarmService`) de type `mediaPlayback` jouant en boucle `gentle_alarm.ogg` sur le flux `STREAM_ALARM` avec vibration.
  - `AlarmActivity` plein écran avec `showWhenLocked` et `turnScreenOn` ; `MainActivity` ne possède pas ces attributs pour ne jamais exposer l'app déverrouillée au-dessus de l'écran de verrouillage.
  - Boutons natifs « ARRÊTER » et « REPORTER 10m » sans démarrage du moteur Dart. Arrêt automatique après 5 minutes avec enregistrement d'une alarme manquée (`missed`).
  - `BootReceiver` réinscrit automatiquement les alarmes après redémarrage du téléphone sans avoir besoin d'ouvrir l'app.
- **Routage et dédoublonnage (`ReminderRouter` & `InAppNotificationBanner`)** :
  - Hors de l'app ou écran verrouillé : réveil natif pour les alarmes, notifications système classiques pour les notifications.
  - Dans l'app au premier plan et déverrouillée : bandeau in-app élégant avec annulation immédiate de la notification système (zéro doublon).
  - Écran de PIN affiché : considéré comme arrière-plan, aucun bandeau in-app n'est projeté au-dessus du pavé numérique.
- **Base Drift Schéma v2 & Journal local (`notification_logs`)** :
  - Schéma monté en v2 avec migration testée.
  - Table `notification_logs` (16 colonnes, index sur `scheduled_at` et `outcome`) 100 % locale : aucune écriture dans `sync_outbox`.
  - Vidage automatique de la boîte aux lettres native d'événements vers Drift au démarrage et au `resumed` (`drainNativeEvents`).
  - Purge automatique des entrées de plus de 30 jours.
- **Centre de Notifications à Deux Sections (`NotificationsScreen`)** :
  - Section 1 : « À faire » (alertes courantes générées par `AlertEngine`).
  - Section 2 : « Historique (30 jours) » (historique des signaux avec mise en avant visuelle des alarmes manquées).
  - Bouton « Tout marquer comme vu » acquittant à la fois les alertes in-app et les journaux de l'historique.



