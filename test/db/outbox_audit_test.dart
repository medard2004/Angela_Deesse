import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/repositories/settings_repository.dart';
import 'package:angela_dress/data/store.dart';

class TestClock implements Clock {
  TestClock(this.currentTime);
  DateTime currentTime;

  @override
  DateTime now() => currentTime;

  void tick([Duration duration = const Duration(seconds: 10)]) {
    currentTime = currentTime.add(duration);
  }
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Tranche 5C / Audit renforcé outbox et invariants', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late AppStore store;

    setUp(() async {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 6, 8, 0));
      store = AppStore(db: db, clock: clock);
      // Base vide, SANS DemoSeeder
      await store.init(seedDemo: false);
    });

    tearDown(() async {
      store.dispose();
      await db.close();
    });

    Future<void> verifyOutboxForMutation(
      String entity,
      String entityId,
      DateTime expectedTime, {
      String? expectedOp,
    }) async {
      final entries = await (db.select(db.syncOutbox)
            ..where((t) => t.entity.equals(entity) & t.entityId.equals(entityId)))
          .get();

      expect(
        entries.isNotEmpty,
        isTrue,
        reason: 'Aucune entrée outbox trouvée pour l\'entité ($entity, $entityId).',
      );

      final matching = entries.where((e) => !e.createdAt.isBefore(expectedTime)).toList();
      expect(
        matching.isNotEmpty,
        isTrue,
        reason: 'Aucune entrée outbox pour ($entity, $entityId) avec created_at >= $expectedTime (dernière: ${entries.last.createdAt}).',
      );

      if (expectedOp != null) {
        expect(
          matching.any((e) => e.op == expectedOp),
          isTrue,
          reason: 'L\'entrée outbox pour ($entity, $entityId) à $expectedTime n\'a pas op = $expectedOp (trouvées: ${matching.map((m) => m.op).toList()}).',
        );
      }
    }

    test('Audit outbox strict : chaque mutation (création, modif, annulation, suppression, diff photos, réglage) écrit dans l\'outbox avec created_at >= updated_at', () async {
      // -------------------------------------------------------------
      // 1. CLIENTS : Création, Modification, Suppression
      // -------------------------------------------------------------
      clock.tick();
      final tC1 = clock.now();
      final client1 = Client(
        id: 'c_test_1',
        name: 'Client Conservé',
        phone: '90 00 00 01',
        notes: 'Notes client 1',
      );
      await store.saveClient(client1);
      final c1Row = await (db.select(db.clients)..where((t) => t.id.equals(client1.id))).getSingle();
      expect(c1Row.updatedAt, equals(tC1));
      await verifyOutboxForMutation('clients', client1.id, tC1, expectedOp: 'upsert');

      // Modification client1
      clock.tick();
      final tC1Mod = clock.now();
      final client1Mod = Client(
        id: client1.id,
        name: 'Client 1 Renommé',
        phone: '90 99 99 99',
        notes: client1.notes,
      );
      await store.saveClient(client1Mod);
      final c1RowMod = await (db.select(db.clients)..where((t) => t.id.equals(client1.id))).getSingle();
      expect(c1RowMod.updatedAt, equals(tC1Mod));
      expect(c1RowMod.createdAt, equals(tC1));
      await verifyOutboxForMutation('clients', client1.id, tC1Mod, expectedOp: 'upsert');

      // Création client2 puis suppression logique
      clock.tick();
      final tC2 = clock.now();
      final client2 = Client(
        id: 'c_test_2',
        name: 'Client À Supprimer',
        phone: '90 00 00 02',
        notes: 'Notes client 2',
      );
      await store.saveClient(client2);
      await verifyOutboxForMutation('clients', client2.id, tC2, expectedOp: 'upsert');

      clock.tick();
      final tC2Del = clock.now();
      await store.deleteClient(client2.id);
      final c2RowDel = await (db.select(db.clients)..where((t) => t.id.equals(client2.id))).getSingle();
      expect(c2RowDel.deletedAt, equals(tC2Del));
      expect(c2RowDel.updatedAt, equals(tC2Del));
      await verifyOutboxForMutation('clients', client2.id, tC2Del, expectedOp: 'delete');

      // -------------------------------------------------------------
      // 2. MESURES : Création, Modification, Suppression
      // -------------------------------------------------------------
      clock.tick();
      final tM1 = clock.now();
      final m1 = Measurement(
        id: 'm_test_1',
        clientId: client1.id,
        takenAt: DateTime.utc(2026, 11, 1),
        values: {'poitrine': 95, 'taille': 75},
        note: 'Mesures 1',
      );
      await store.saveMeasurement(m1);
      final m1Row = await (db.select(db.measurements)..where((t) => t.id.equals(m1.id))).getSingle();
      expect(m1Row.updatedAt, equals(tM1));
      await verifyOutboxForMutation('measurements', m1.id, tM1, expectedOp: 'upsert');

      // Modification mesure
      clock.tick();
      final tM1Mod = clock.now();
      final m1Mod = Measurement(
        id: m1.id,
        clientId: m1.clientId,
        takenAt: m1.takenAt,
        values: {'poitrine': 98, 'taille': 78},
        note: 'Mesures 1 modifiées',
      );
      await store.saveMeasurement(m1Mod);
      final m1RowMod = await (db.select(db.measurements)..where((t) => t.id.equals(m1.id))).getSingle();
      expect(m1RowMod.updatedAt, equals(tM1Mod));
      expect(m1RowMod.createdAt, equals(tM1));
      await verifyOutboxForMutation('measurements', m1.id, tM1Mod, expectedOp: 'upsert');

      // Création mesure 3 puis suppression directe
      clock.tick();
      final tM3 = clock.now();
      final m3 = Measurement(
        id: 'm_test_3',
        clientId: client1.id,
        takenAt: DateTime.utc(2026, 11, 3),
        values: {'poitrine': 96},
        note: 'Mesures 3 à supprimer',
      );
      await store.saveMeasurement(m3);
      await verifyOutboxForMutation('measurements', m3.id, tM3, expectedOp: 'upsert');

      clock.tick();
      final tM3Del = clock.now();
      await store.deleteMeasurement(m3.id);
      final m3RowDel = await (db.select(db.measurements)..where((t) => t.id.equals(m3.id))).getSingle();
      expect(m3RowDel.deletedAt, equals(tM3Del));
      expect(m3RowDel.updatedAt, equals(tM3Del));
      await verifyOutboxForMutation('measurements', m3.id, tM3Del, expectedOp: 'delete');

      // -------------------------------------------------------------
      // 3. MODÈLES : Création, Modification, Suppression
      // -------------------------------------------------------------
      clock.tick();
      final tMod1 = clock.now();
      final modele1 = Modele(
        id: 'mod_test_1',
        name: 'Robe Princesse',
        description: 'Description 1',
        photo: 'demo:1',
      );
      await store.saveModele(modele1);
      final mod1Row = await (db.select(db.modeles)..where((t) => t.id.equals(modele1.id))).getSingle();
      expect(mod1Row.updatedAt, equals(tMod1));
      await verifyOutboxForMutation('modeles', modele1.id, tMod1, expectedOp: 'upsert');

      clock.tick();
      final tMod1Mod = clock.now();
      final mod1Mod = Modele(
        id: modele1.id,
        name: 'Robe Princesse Deluxe',
        description: 'Description modifiée',
        photo: 'demo:1',
      );
      await store.saveModele(mod1Mod);
      final mod1RowMod = await (db.select(db.modeles)..where((t) => t.id.equals(modele1.id))).getSingle();
      expect(mod1RowMod.updatedAt, equals(tMod1Mod));
      expect(mod1RowMod.createdAt, equals(tMod1));
      await verifyOutboxForMutation('modeles', modele1.id, tMod1Mod, expectedOp: 'upsert');

      clock.tick();
      final tMod2 = clock.now();
      final modele2 = Modele(
        id: 'mod_test_2',
        name: 'Tailleur Dame',
        description: 'Description 2',
        photo: 'demo:2',
      );
      await store.saveModele(modele2);
      await verifyOutboxForMutation('modeles', modele2.id, tMod2, expectedOp: 'upsert');

      clock.tick();
      final tMod2Del = clock.now();
      await store.deleteModele(modele2.id);
      final mod2RowDel = await (db.select(db.modeles)..where((t) => t.id.equals(modele2.id))).getSingle();
      expect(mod2RowDel.deletedAt, equals(tMod2Del));
      expect(mod2RowDel.updatedAt, equals(tMod2Del));
      await verifyOutboxForMutation('modeles', modele2.id, tMod2Del, expectedOp: 'delete');

      // -------------------------------------------------------------
      // 4. RÉALISATIONS : Création, Modification, Suppression
      // -------------------------------------------------------------
      clock.tick();
      final tReal1 = clock.now();
      final real1 = Realisation(
        id: 'real_test_1',
        photo: 'demo:3',
        category: 'Robe',
        clientId: client1.id,
        caption: 'Réalisation initiale',
        createdAt: tReal1,
      );
      await store.saveRealisation(real1);
      final real1Row = await (db.select(db.realisations)..where((t) => t.id.equals(real1.id))).getSingle();
      expect(real1Row.updatedAt, equals(tReal1));
      await verifyOutboxForMutation('realisations', real1.id, tReal1, expectedOp: 'upsert');

      clock.tick();
      final tReal1Mod = clock.now();
      final real1Mod = Realisation(
        id: real1.id,
        photo: real1.photo,
        category: 'Robe de soirée',
        clientId: real1.clientId,
        caption: 'Légende modifiée',
        createdAt: real1.createdAt,
      );
      await store.saveRealisation(real1Mod);
      final real1RowMod = await (db.select(db.realisations)..where((t) => t.id.equals(real1.id))).getSingle();
      expect(real1RowMod.updatedAt, equals(tReal1Mod));
      expect(real1RowMod.createdAt, equals(tReal1));
      await verifyOutboxForMutation('realisations', real1.id, tReal1Mod, expectedOp: 'upsert');

      clock.tick();
      final tReal2 = clock.now();
      final real2 = Realisation(
        id: 'real_test_2',
        photo: 'demo:4',
        category: 'Jupe',
        clientId: client1.id,
        caption: 'Réalisation annulée',
        createdAt: tReal2,
      );
      await store.saveRealisation(real2);
      await verifyOutboxForMutation('realisations', real2.id, tReal2, expectedOp: 'upsert');

      clock.tick();
      final tReal2Del = clock.now();
      await store.deleteRealisation(real2.id);
      final real2RowDel = await (db.select(db.realisations)..where((t) => t.id.equals(real2.id))).getSingle();
      expect(real2RowDel.deletedAt, equals(tReal2Del));
      expect(real2RowDel.updatedAt, equals(tReal2Del));
      await verifyOutboxForMutation('realisations', real2.id, tReal2Del, expectedOp: 'delete');

      // -------------------------------------------------------------
      // 5. COMMANDES : Création avec acompte, Diff de photos, Versements, Annulation, Suppression
      // -------------------------------------------------------------
      clock.tick();
      final tOrd1 = clock.now();
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
        createdAt: tOrd1,
      );
      await store.saveOrder(order1, initialDeposit: 15000, depositNote: 'Acompte initial');
      final ord1Row = await (db.select(db.orders)..where((t) => t.id.equals(order1.id))).getSingle();
      expect(ord1Row.updatedAt, equals(tOrd1));
      await verifyOutboxForMutation('orders', order1.id, tOrd1, expectedOp: 'upsert');

      // Vérifier outbox pour les photos initiales demo:5 et demo:6
      final initialPhotos = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(order1.id) & t.deletedAt.isNull()))
          .get();
      expect(initialPhotos.length, 2);
      for (final p in initialPhotos) {
        expect(p.updatedAt, equals(tOrd1));
        await verifyOutboxForMutation('order_photos', p.id, tOrd1, expectedOp: 'upsert');
      }

      // Diffing de photos : on retire demo:6 et on ajoute demo:7 et demo:8
      clock.tick();
      final tOrd1PhotoDiff = clock.now();
      final order1Diff = Order(
        id: order1.id,
        clientId: order1.clientId,
        modeleId: order1.modeleId,
        title: 'Robe de fête avec photos modifiées',
        fabric: order1.fabric,
        price: order1.price,
        deliveryDate: order1.deliveryDate,
        fittingDate: order1.fittingDate,
        status: order1.status,
        photos: ['demo:5', 'demo:7', 'demo:8'],
        createdAt: order1.createdAt,
      );
      await store.saveOrder(order1Diff);

      // Commande mise à jour dans l'outbox
      await verifyOutboxForMutation('orders', order1.id, tOrd1PhotoDiff, expectedOp: 'upsert');

      // Photo demo:6 supprimée de l'order -> outbox op 'delete' avec createdAt >= tOrd1PhotoDiff
      final removedPhotoRow = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(order1.id) & t.photoPath.equals('demo:6')))
          .getSingle();
      expect(removedPhotoRow.deletedAt, equals(tOrd1PhotoDiff));
      await verifyOutboxForMutation('order_photos', removedPhotoRow.id, tOrd1PhotoDiff, expectedOp: 'delete');

      // Nouvelles photos demo:7 et demo:8 -> outbox op 'upsert'
      final newPhotoRows = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(order1.id) & t.deletedAt.isNull() & t.photoPath.isNotValue('demo:5')))
          .get();
      expect(newPhotoRows.length, 2);
      for (final p in newPhotoRows) {
        expect(p.updatedAt, equals(tOrd1PhotoDiff));
        await verifyOutboxForMutation('order_photos', p.id, tOrd1PhotoDiff, expectedOp: 'upsert');
      }

      // Versement client complémentaire
      clock.tick();
      final tPay2 = clock.now();
      final payment2 = await store.addClientPayment(order1.id, 10000, 'Deuxième versement');
      final pay2Row = await (db.select(db.clientPayments)..where((t) => t.id.equals(payment2.id))).getSingle();
      expect(pay2Row.updatedAt, equals(tPay2));
      await verifyOutboxForMutation('client_payments', payment2.id, tPay2, expectedOp: 'upsert');

      // Annulation du versement
      clock.tick();
      final tPay2Void = clock.now();
      await store.voidClientPayment(payment2.id, 'Erreur de saisie client');
      final pay2RowVoid = await (db.select(db.clientPayments)..where((t) => t.id.equals(payment2.id))).getSingle();
      expect(pay2RowVoid.voidedAt, equals(tPay2Void));
      expect(pay2RowVoid.updatedAt, equals(tPay2Void));
      await verifyOutboxForMutation('client_payments', payment2.id, tPay2Void, expectedOp: 'upsert');

      // Création commande 2 sans versement puis suppression
      clock.tick();
      final tOrd2 = clock.now();
      final order2 = Order(
        id: 'ord_test_2',
        clientId: client1.id,
        modeleId: modele1.id,
        title: 'Commande à supprimer',
        fabric: 'Coton',
        price: 20000,
        deliveryDate: DateTime.utc(2026, 11, 25),
        status: OrderStatus.attente,
        photos: ['demo:9'],
        createdAt: tOrd2,
      );
      await store.saveOrder(order2);
      await verifyOutboxForMutation('orders', order2.id, tOrd2, expectedOp: 'upsert');

      clock.tick();
      final tOrd2Del = clock.now();
      await store.deleteOrder(order2.id);
      final ord2RowDel = await (db.select(db.orders)..where((t) => t.id.equals(order2.id))).getSingle();
      expect(ord2RowDel.deletedAt, equals(tOrd2Del));
      expect(ord2RowDel.updatedAt, equals(tOrd2Del));
      await verifyOutboxForMutation('orders', order2.id, tOrd2Del, expectedOp: 'delete');

      // Photos associées à order2 supprimées avec outbox op 'delete'
      final ord2PhotosDel = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(order2.id)))
          .get();
      for (final p in ord2PhotosDel) {
        expect(p.deletedAt, equals(tOrd2Del));
        await verifyOutboxForMutation('order_photos', p.id, tOrd2Del, expectedOp: 'delete');
      }

      // -------------------------------------------------------------
      // 6. APPRENTIS : Création avec acompte, Modification, Versement, Annulation, Suppression
      // -------------------------------------------------------------
      clock.tick();
      final tApp1 = clock.now();
      final app1 = Apprentice(
        id: 'app_test_1',
        name: 'Kofi Mensah',
        phone: '90 11 22 33',
        startDate: DateTime.utc(2026, 1, 1),
        totalFee: 150000,
        notes: 'Apprenti 1',
      );
      final depositPayment = await store.saveApprentice(app1, initialDeposit: 50000, depositNote: 'Acompte inscription');
      expect(depositPayment, isNotNull);
      final app1Row = await (db.select(db.apprentices)..where((t) => t.id.equals(app1.id))).getSingle();
      expect(app1Row.updatedAt, equals(tApp1));
      await verifyOutboxForMutation('apprentices', app1.id, tApp1, expectedOp: 'upsert');
      await verifyOutboxForMutation('apprentice_payments', depositPayment!.id, tApp1, expectedOp: 'upsert');

      // Modification apprenti1
      clock.tick();
      final tApp1Mod = clock.now();
      final app1Mod = app1.copyWith(phone: '90 99 88 77', notes: 'Notes mises à jour');
      await store.saveApprentice(app1Mod);
      final app1RowMod = await (db.select(db.apprentices)..where((t) => t.id.equals(app1.id))).getSingle();
      expect(app1RowMod.updatedAt, equals(tApp1Mod));
      expect(app1RowMod.createdAt, equals(tApp1));
      await verifyOutboxForMutation('apprentices', app1.id, tApp1Mod, expectedOp: 'upsert');

      // Versement apprenti 2
      clock.tick();
      final tAppPay2 = clock.now();
      final pApp2 = await store.addApprenticePayment(app1.id, 25000, 'Mensualité 1');
      final pApp2Row = await (db.select(db.apprenticePayments)..where((t) => t.id.equals(pApp2.id))).getSingle();
      expect(pApp2Row.updatedAt, equals(tAppPay2));
      await verifyOutboxForMutation('apprentice_payments', pApp2.id, tAppPay2, expectedOp: 'upsert');

      // Annulation versement apprenti
      clock.tick();
      final tAppPay2Void = clock.now();
      await store.voidApprenticePayment(pApp2.id, 'Erreur de montant');
      final pApp2RowVoid = await (db.select(db.apprenticePayments)..where((t) => t.id.equals(pApp2.id))).getSingle();
      expect(pApp2RowVoid.voidedAt, equals(tAppPay2Void));
      expect(pApp2RowVoid.updatedAt, equals(tAppPay2Void));
      await verifyOutboxForMutation('apprentice_payments', pApp2.id, tAppPay2Void, expectedOp: 'upsert');

      // Création apprenti 2 sans versement puis suppression
      clock.tick();
      final tApp2 = clock.now();
      final app2 = Apprentice(
        id: 'app_test_2',
        name: 'Ami Lawson',
        phone: '90 44 55 66',
        startDate: DateTime.utc(2026, 2, 1),
        totalFee: 100000,
        notes: 'Apprentie 2 à supprimer',
      );
      await store.saveApprentice(app2);
      await verifyOutboxForMutation('apprentices', app2.id, tApp2, expectedOp: 'upsert');

      clock.tick();
      final tApp2Del = clock.now();
      await store.deleteApprentice(app2.id);
      final app2RowDel = await (db.select(db.apprentices)..where((t) => t.id.equals(app2.id))).getSingle();
      expect(app2RowDel.deletedAt, equals(tApp2Del));
      expect(app2RowDel.updatedAt, equals(tApp2Del));
      await verifyOutboxForMutation('apprentices', app2.id, tApp2Del, expectedOp: 'delete');

      // -------------------------------------------------------------
      // 7. RÉGLAGES : Upsert initial et Modifications successives
      // -------------------------------------------------------------
      clock.tick();
      final tSet1 = clock.now();
      await store.setAtelierName('Atelier Angela Prestige');
      final set1Row = await (db.select(db.settings)..where((t) => t.key.equals(kSettingAtelierName))).getSingle();
      expect(set1Row.updatedAt, equals(tSet1));
      await verifyOutboxForMutation('settings', kSettingAtelierName, tSet1, expectedOp: 'upsert');

      // Modification du même réglage
      clock.tick();
      final tSet1Mod = clock.now();
      await store.setAtelierName('Atelier Angela Haute Couture');
      final set1RowMod = await (db.select(db.settings)..where((t) => t.key.equals(kSettingAtelierName))).getSingle();
      expect(set1RowMod.updatedAt, equals(tSet1Mod));
      expect(set1RowMod.createdAt, equals(tSet1));
      await verifyOutboxForMutation('settings', kSettingAtelierName, tSet1Mod, expectedOp: 'upsert');

      // Interrupteurs
      clock.tick();
      final tSetNotif = clock.now();
      await store.setNotifDelivery(false);
      await verifyOutboxForMutation('settings', kSettingNotifDelivery, tSetNotif, expectedOp: 'upsert');

      // =============================================================
      // 8. RÈGLES MÉTIER / MUTATIONS REFUSÉES : Zéro écriture, Zéro outbox
      // =============================================================
      final outboxCountBefore = (await db.select(db.syncOutbox).get()).length;

      // 8.1 Refus de supprimer un client ayant une commande active
      expect(
        () => store.deleteClient(client1.id),
        throwsA(isA<StateError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));

      // 8.2 Refus de supprimer une commande ayant un versement actif
      expect(
        () => store.deleteOrder(order1.id),
        throwsA(isA<StateError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));

      // 8.3 Refus de supprimer un apprenti ayant un versement actif
      expect(
        () => store.deleteApprentice(app1.id),
        throwsA(isA<StateError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));

      // 8.4 Refus d'un versement client supérieur au reliquat restant
      final order1Price = order1.price; // 50000
      final activePaymentsOrder1 = await db.getTotalActivePaymentsForOrder(order1.id); // 15000 (le 2e a été annulé)
      final remainingOrder1 = order1Price - activePaymentsOrder1; // 35000
      expect(
        () => store.addClientPayment(order1.id, remainingOrder1 + 1000, 'Excédent refusé'),
        throwsA(isA<ArgumentError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));

      // 8.5 Refus d'un versement apprenti supérieur au reste à payer
      final app1TotalFee = app1.totalFee; // 150000
      final activePaymentsApp1 = await db.activePaymentsTotalForApprentice(app1.id); // 50000 (le 2e a été annulé)
      final remainingApp1 = app1TotalFee - activePaymentsApp1; // 100000
      expect(
        () => store.addApprenticePayment(app1.id, remainingApp1 + 5000, 'Excédent écolage refusé'),
        throwsA(isA<ArgumentError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));

      // 8.6 Refus de ré-annuler un versement client déjà annulé
      expect(
        () => store.voidClientPayment(payment2.id, 'Double annulation'),
        throwsA(isA<StateError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));

      // 8.7 Refus de ré-annuler un versement apprenti déjà annulé
      expect(
        () => store.voidApprenticePayment(pApp2.id, 'Double annulation apprenti'),
        throwsA(isA<StateError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));

      // 8.8 Refus de baisser le prix d'une commande en dessous du total versé
      final invalidOrder = order1.copyWith(price: activePaymentsOrder1 - 5000);
      expect(
        () => store.saveOrder(invalidOrder),
        throwsA(isA<ArgumentError>()),
      );
      expect((await db.select(db.syncOutbox).get()).length, equals(outboxCountBefore));
    });
  });
}
