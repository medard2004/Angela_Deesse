import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/store.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Tranche 5C - Audit outbox et invariants', () {
    late db_layer.AppDatabase db;
    late AppStore store;

    setUp(() async {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      store = AppStore(db: db);
      // Base vide, SANS DemoSeeder
      await store.init(seedDemo: false);
    });

    tearDown(() async {
      store.dispose();
      await db.close();
    });

    test('Audit d\'invariant : chaque ligne synchronisable a au moins une entrée outbox, et chaque op=delete a deleted_at non nul', () async {
      // 1. Clients & Mesures
      final client1 = Client(
        id: 'c_test_1',
        name: 'Client Conservé',
        phone: '90 00 00 01',
        notes: 'Notes client 1',
      );
      final client2 = Client(
        id: 'c_test_2',
        name: 'Client À Supprimer',
        phone: '90 00 00 02',
        notes: 'Notes client 2',
      );
      await store.saveClient(client1);
      await store.saveClient(client2);

      final m1 = Measurement(
        id: 'm_test_1',
        clientId: client1.id,
        takenAt: DateTime.utc(2026, 11, 1),
        values: {'poitrine': 95, 'taille': 75},
        note: 'Mesures 1',
      );
      final m2 = Measurement(
        id: 'm_test_2',
        clientId: client2.id,
        takenAt: DateTime.utc(2026, 11, 2),
        values: {'poitrine': 90, 'taille': 70},
        note: 'Mesures client 2',
      );
      final m3 = Measurement(
        id: 'm_test_3',
        clientId: client1.id,
        takenAt: DateTime.utc(2026, 11, 3),
        values: {'poitrine': 96},
        note: 'Mesures 3 à supprimer directement',
      );
      await store.saveMeasurement(m1);
      await store.saveMeasurement(m2);
      await store.saveMeasurement(m3);

      // Suppression directe d'une mesure
      await store.deleteMeasurement(m3.id);

      // Suppression d'un client (entraîne la suppression logique en cascade de ses mesures m2)
      await store.deleteClient(client2.id);

      // 2. Modèles & Réalisations
      final modele1 = Modele(
        id: 'mod_test_1',
        name: 'Robe Princesse',
        description: 'Description 1',
        photo: 'demo:1',
      );
      final modele2 = Modele(
        id: 'mod_test_2',
        name: 'Tailleur Dame',
        description: 'Description 2',
        photo: 'demo:2',
      );
      await store.saveModele(modele1);
      await store.saveModele(modele2);
      await store.deleteModele(modele2.id);

      final real1 = Realisation(
        id: 'real_test_1',
        photo: 'demo:3',
        category: 'Robe',
        clientId: client1.id,
        caption: 'Réalisation terminée',
        createdAt: DateTime.utc(2026, 11, 4),
      );
      final real2 = Realisation(
        id: 'real_test_2',
        photo: 'demo:4',
        category: 'Jupe',
        clientId: client1.id,
        caption: 'Réalisation annulée',
        createdAt: DateTime.utc(2026, 11, 4),
      );
      await store.saveRealisation(real1);
      await store.saveRealisation(real2);
      await store.deleteRealisation(real2.id);

      // 3. Commandes avec acompte, photos, versements, annulation de versement, suppression de commande
      final order1 = Order(
        id: 'ord_test_1',
        clientId: client1.id,
        modeleId: modele1.id,
        title: 'Robe de fête',
        fabric: 'Soie',
        price: 50000,
        deliveryDate: DateTime.utc(2026, 11, 20),
        fittingDate: DateTime.utc(2026, 11, 15, 14, 0),
        status: OrderStatus.cours,
        photos: ['demo:5', 'demo:6'],
        createdAt: DateTime.utc(2026, 11, 5),
      );
      // Commande avec acompte (crée order, order_photos, client_payments)
      await store.saveOrder(order1, initialDeposit: 15000, depositNote: 'Acompte initial');

      // Deuxième versement client
      final payment2 = await store.addClientPayment(order1.id, 10000, 'Deuxième versement');
      // Annulation du versement
      await store.voidClientPayment(payment2.id, 'Erreur de saisie client');

      // Commande 2 avec photos, sans acompte, puis supprimée
      final order2 = Order(
        id: 'ord_test_2',
        clientId: client1.id,
        modeleId: modele1.id,
        title: 'Commande test suppression',
        fabric: 'Coton',
        price: 20000,
        deliveryDate: DateTime.utc(2026, 11, 25),
        status: OrderStatus.attente,
        photos: ['demo:7'],
        createdAt: DateTime.utc(2026, 11, 5),
      );
      await store.saveOrder(order2);
      await store.deleteOrder(order2.id);

      // 4. Apprentis avec acompte, versement, annulation, suppression
      final app1 = Apprentice(
        id: 'app_test_1',
        name: 'Kofi Mensah',
        phone: '90 11 22 33',
        startDate: DateTime.utc(2026, 1, 1),
        totalFee: 150000,
        notes: 'Apprenti 1',
      );
      // Apprenti avec acompte (crée apprentice, apprentice_payments)
      await store.saveApprentice(app1, initialDeposit: 50000, depositNote: 'Acompte inscription');

      // Deuxième versement apprenti
      final pApp2 = await store.addApprenticePayment(app1.id, 25000, 'Mensualité 1');
      // Annulation du versement
      await store.voidApprenticePayment(pApp2.id, 'Erreur de montant');

      // Apprenti 2 sans versement, puis supprimé
      final app2 = Apprentice(
        id: 'app_test_2',
        name: 'Ami Lawson',
        phone: '90 44 55 66',
        startDate: DateTime.utc(2026, 2, 1),
        totalFee: 100000,
        notes: 'Apprentie 2 à supprimer',
      );
      await store.saveApprentice(app2);
      await store.deleteApprentice(app2.id);

      // 5. Réglages
      await store.setAtelierName('Atelier Angela Prestige');
      await store.setNotifDelivery(false);
      await store.setNotifFitting(true);
      await store.setNotifPayments(false);
      await store.setNotifLate(true);

      // ========================================================
      // VÉRIFICATIONS D'INVARIANTS
      // ========================================================

      final outboxEntries = await db.select(db.syncOutbox).get();
      expect(outboxEntries.isNotEmpty, isTrue);

      // Regrouper l'outbox par (entity, entityId)
      final outboxByEntityAndId = <String, Set<String>>{};
      for (final o in outboxEntries) {
        outboxByEntityAndId.putIfAbsent(o.entity, () => <String>{}).add(o.entityId);
      }

      // Helper pour vérifier qu'une table a des lignes et que chaque ligne a une entrée d'outbox
      void checkOutboxForTable<T>(
        String entityName,
        List<T> rows,
        String Function(T row) getId,
      ) {
        expect(rows.isNotEmpty, isTrue, reason: 'La table synchronisable $entityName doit contenir des lignes pour le test.');
        final outboxIds = outboxByEntityAndId[entityName] ?? <String>{};
        for (final row in rows) {
          final id = getId(row);
          expect(
            outboxIds.contains(id),
            isTrue,
            reason: 'La ligne $id de la table $entityName n\'a aucune entrée dans sync_outbox.',
          );
        }
      }

      // Table 1 : clients
      final allClients = await db.select(db.clients).get();
      checkOutboxForTable('clients', allClients, (r) => r.id);

      // Table 2 : measurements
      final allMeasurements = await db.select(db.measurements).get();
      checkOutboxForTable('measurements', allMeasurements, (r) => r.id);

      // Table 3 : modeles
      final allModeles = await db.select(db.modeles).get();
      checkOutboxForTable('modeles', allModeles, (r) => r.id);

      // Table 4 : realisations
      final allRealisations = await db.select(db.realisations).get();
      checkOutboxForTable('realisations', allRealisations, (r) => r.id);

      // Table 5 : orders
      final allOrders = await db.select(db.orders).get();
      checkOutboxForTable('orders', allOrders, (r) => r.id);

      // Table 6 : order_photos
      final allOrderPhotos = await db.select(db.orderPhotos).get();
      checkOutboxForTable('order_photos', allOrderPhotos, (r) => r.id);

      // Table 7 : client_payments
      final allClientPayments = await db.select(db.clientPayments).get();
      checkOutboxForTable('client_payments', allClientPayments, (r) => r.id);

      // Table 8 : apprentices
      final allApprentices = await db.select(db.apprentices).get();
      checkOutboxForTable('apprentices', allApprentices, (r) => r.id);

      // Table 9 : apprentice_payments
      final allApprenticePayments = await db.select(db.apprenticePayments).get();
      checkOutboxForTable('apprentice_payments', allApprenticePayments, (r) => r.id);

      // Table 10 : settings
      final allSettings = await db.select(db.settings).get();
      checkOutboxForTable('settings', allSettings, (r) => r.id);

      // ========================================================
      // INVARIANT 2 : chaque op = 'delete' correspond à une ligne dont deleted_at est NON NUL
      // ========================================================
      final deleteOps = outboxEntries.where((o) => o.op == 'delete').toList();
      expect(deleteOps.isNotEmpty, isTrue, reason: 'Il doit y avoir des opérations delete dans l\'outbox.');

      // Maps de toutes les lignes pour vérification rapide
      final clientsMap = {for (final r in allClients) r.id: r};
      final measurementsMap = {for (final r in allMeasurements) r.id: r};
      final modelesMap = {for (final r in allModeles) r.id: r};
      final realisationsMap = {for (final r in allRealisations) r.id: r};
      final ordersMap = {for (final r in allOrders) r.id: r};
      final orderPhotosMap = {for (final r in allOrderPhotos) r.id: r};
      final apprenticesMap = {for (final r in allApprentices) r.id: r};

      for (final del in deleteOps) {
        DateTime? deletedAt;
        switch (del.entity) {
          case 'clients':
            deletedAt = clientsMap[del.entityId]?.deletedAt;
            break;
          case 'measurements':
            deletedAt = measurementsMap[del.entityId]?.deletedAt;
            break;
          case 'modeles':
            deletedAt = modelesMap[del.entityId]?.deletedAt;
            break;
          case 'realisations':
            deletedAt = realisationsMap[del.entityId]?.deletedAt;
            break;
          case 'orders':
            deletedAt = ordersMap[del.entityId]?.deletedAt;
            break;
          case 'order_photos':
            deletedAt = orderPhotosMap[del.entityId]?.deletedAt;
            break;
          case 'apprentices':
            deletedAt = apprenticesMap[del.entityId]?.deletedAt;
            break;
          default:
            fail('Entité inattendue pour une opération delete: ${del.entity}');
        }

        expect(
          deletedAt,
          isNotNull,
          reason: 'L\'entrée d\'outbox delete (${del.entity}, ${del.entityId}) pointe sur une ligne avec deleted_at nul ou inexistante.',
        );
      }
    });
  });
}
