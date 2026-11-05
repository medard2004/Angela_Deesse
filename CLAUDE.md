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
- Données volatiles (perdues à la fermeture).
- Photos = identifiants simulés (`demo:1`), pas d'appareil photo ni de fichiers.
- Boutons WhatsApp / SMS / appel = simple SnackBar.
- Pas de vrai PDF.
- `LockScreen` accepte n'importe quel code à 4 chiffres.
- Interrupteurs de notifications purement visuels.
- Aucune sauvegarde ni sync.

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

1. **Local** : schéma Drift sync-ready, repositories, migration d'`AppStore`, `_seed()` devient un jeu de démo optionnel.
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
- **Numéros de reçus & Affichage** :
  - Numéro stocké sous forme d'entier séquentiel unique dans `receipt_number`.
  - Format d'affichage : préfixe distinctif `CMD-0001` pour les clients (différencié du format `0001` des apprentis).
  - Reçu en photographie du moment : solde affiché = `prix - somme(versements actifs dont receipt_number <= reçu.receipt_number)`.
  - Tampon de reçu : « ANNULÉ » en rouge (`Pal.thread`) si le versement est annulé ; « SOLDÉ » ou « PAYÉ » sinon.
- **Dates jour-seul & fuseaux horaires** :
  - Les dates jour-seul (`deliveryDate`) sont normalisées en UTC calendaire (`DateTime.utc(year, month, day)`) garantissant un aller-retour exact sans décalage quel que soit le fuseau horaire (`Africa/Lagos` UTC+1, `America/New_York` UTC-5).
  - Les calculs de tableau de bord (délais, retards) restent en Dart avec bornes en heure locale.
- **DemoSeeder** :
  - Commandes + photos + versements démo insérés ensemble sous la clé `'demo_seeded:orders'` en debug uniquement, sans écriture dans `sync_outbox`.
  - Numéros de reçus séquentiels attribués aux versements démo et compteur `receipt_counters('clients')` calé dessus.
  - `reconcileReceiptCounters()` exécuté à l'initialisation de l'atelier pour garantir la cohérence continue des compteurs.
