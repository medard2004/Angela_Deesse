import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/db/demo_seeder.dart';
import 'package:angela_dress/data/db/id_generator.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/repositories/client_repository.dart';
import 'package:angela_dress/data/repositories/order_repository.dart';
import 'package:angela_dress/data/repositories/payment_repository.dart';

class TestClock implements Clock {
  TestClock(this.currentTime);
  DateTime currentTime;

  @override
  DateTime now() => currentTime;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Tranche 3B - Versements clients, reçus et annulation (Drift)', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late IdGenerator idGen;
    late DriftOrderRepository orderRepo;
    late DriftPaymentRepository paymentRepo;

    setUp(() async {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 5, 10, 0));
      idGen = const UuidV7IdGenerator();
      orderRepo = DriftOrderRepository(db: db, clock: clock, idGenerator: idGen);
      paymentRepo = DriftPaymentRepository(db: db, clock: clock, idGenerator: idGen);

      // Créer un client de base pour les tests (insertion directe sans outbox)
      await db.into(db.clients).insert(
            db_layer.ClientsCompanion.insert(
              id: 'c_test',
              name: 'Amina Test',
              phone: const Value('90000000'),
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Création avec acompte : atomicité complète et rollback si échec', () async {
      final order = Order(
        id: 'o_dep',
        clientId: 'c_test',
        title: 'Robe Acompte',
        fabric: 'Soie',
        price: 50000,
        deliveryDate: DateTime.utc(2026, 11, 20),
        photos: ['demo:1', 'demo:2'],
        createdAt: clock.now(),
      );

      // Cas valide
      await orderRepo.createWithDeposit(
        order: order,
        depositAmount: 20000,
        depositNote: 'Acompte initial',
      );

      // Vérifier commande
      final readOrder = await orderRepo.getById('o_dep');
      expect(readOrder, isNotNull);
      expect(readOrder!.photos.length, 2);

      // Vérifier versement
      final payments = await paymentRepo.getByOrderId('o_dep');
      expect(payments.length, 1);
      final p1 = payments.first;
      expect(p1.amount, 20000);
      expect(p1.receiptNumber, 1);
      expect(p1.note, 'Acompte initial');
      expect(p1.isVoided, isFalse);

      // Vérifier le compteur de reçus
      final counter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('clients'))).getSingle();
      expect(counter.lastValue, 1);

      // Vérifier l'outbox : 1 order + 2 order_photos + 1 client_payment = 4 entrées
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.length, 4);
      expect(outbox.map((e) => e.entity).toSet(), containsAll(['orders', 'order_photos', 'client_payments']));

      // Cas d'échec : montant négatif ou nul (rejeté avant écriture)
      final orderFail = Order(
        id: 'o_fail',
        clientId: 'c_test',
        title: 'Robe Echec',
        fabric: 'Coton',
        price: 30000,
        deliveryDate: DateTime.utc(2026, 11, 25),
        createdAt: clock.now(),
      );

      expect(
        () => orderRepo.createWithDeposit(order: orderFail, depositAmount: -5000),
        throwsA(isA<ArgumentError>()),
      );

      // Commande non créée
      final readFail = await orderRepo.getById('o_fail');
      expect(readFail, isNull);

      // Le compteur n'a pas bougé
      final counterAfter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('clients'))).getSingle();
      expect(counterAfter.lastValue, 1);
    });

    test('2. Reçus : numéros séquentiels, concurrence Future.wait, et sans doublon', () async {
      final order = Order(
        id: 'o_seq',
        clientId: 'c_test',
        title: 'Commande Séquentielle',
        fabric: 'Wax',
        price: 100000,
        deliveryDate: DateTime.utc(2026, 11, 30),
        createdAt: clock.now(),
      );
      await orderRepo.save(order);

      // Ajouter 3 versements séquentiels
      final p1 = await paymentRepo.addPayment(orderId: 'o_seq', amount: 10000, note: 'V1');
      final p2 = await paymentRepo.addPayment(orderId: 'o_seq', amount: 15000, note: 'V2');
      final p3 = await paymentRepo.addPayment(orderId: 'o_seq', amount: 20000, note: 'V3');

      expect(p1.receiptNumber, 1);
      expect(p2.receiptNumber, 2);
      expect(p3.receiptNumber, 3);

      // Deux versements simultanés (Future.wait)
      final results = await Future.wait([
        paymentRepo.addPayment(orderId: 'o_seq', amount: 5000, note: 'Simultané A'),
        paymentRepo.addPayment(orderId: 'o_seq', amount: 5000, note: 'Simultané B'),
      ]);

      final receiptNums = results.map((r) => r.receiptNumber).toSet();
      expect(receiptNums.length, 2, reason: 'Chaque versement doit avoir un numéro unique');
      expect(receiptNums, containsAll([4, 5]));
    });

    test('3. Reconcile des compteurs de reçus après insertion directe/restauration', () async {
      // Simuler l'insertion d'un versement restauré avec un numéro de reçu élevé (ex: 42)
      final order = Order(
        id: 'o_rec',
        clientId: 'c_test',
        title: 'Robe Rec',
        fabric: 'Lin',
        price: 80000,
        deliveryDate: DateTime.utc(2026, 12, 1),
        createdAt: clock.now(),
      );
      await orderRepo.save(order);

      await db.into(db.clientPayments).insert(
            db_layer.ClientPaymentsCompanion.insert(
              id: 'p_restored',
              orderId: 'o_rec',
              amount: 25000,
              paidAt: clock.now(),
              receiptNumber: 42,
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      // Réconciliation
      await db.reconcileReceiptCounters();

      final counter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('clients'))).getSingle();
      expect(counter.lastValue, 42);

      // Le versement suivant reçoit 43
      final nextP = await paymentRepo.addPayment(orderId: 'o_rec', amount: 5000, note: 'Suite');
      expect(nextP.receiptNumber, 43);
    });

    test('4. Annulation d un versement : voided_at, motif, outbox, exclusion des sommes et double annulation refusée', () async {
      final order = Order(
        id: 'o_void',
        clientId: 'c_test',
        title: 'Robe Annulation',
        fabric: 'Bazin',
        price: 60000,
        deliveryDate: DateTime.utc(2026, 12, 5),
        createdAt: clock.now(),
      );
      await orderRepo.save(order);

      final p = await paymentRepo.addPayment(orderId: 'o_void', amount: 20000, note: 'Acompte');
      expect(p.isVoided, isFalse);

      final totalBefore = await paymentRepo.getTotalActivePaymentsForOrder('o_void');
      expect(totalBefore, 20000);

      // Avancer l'horloge
      clock.currentTime = clock.currentTime.add(const Duration(hours: 2));

      // Annuler le versement
      final voided = await paymentRepo.voidPayment(id: p.id, reason: 'Erreur de saisie client');
      expect(voided.isVoided, isTrue);
      expect(voided.voidedAt, clock.now());
      expect(voided.voidReason, 'Erreur de saisie client');

      // Le total actif exclut le versement annulé
      final totalAfter = await paymentRepo.getTotalActivePaymentsForOrder('o_void');
      expect(totalAfter, 0);

      // Double annulation refusée
      expect(
        () => paymentRepo.voidPayment(id: p.id, reason: 'Deuxième tentative'),
        throwsA(isA<StateError>()),
      );

      // Vérifier l'outbox d'annulation (op: 'upsert' sur client_payments)
      final outboxEntries = await (db.select(db.syncOutbox)
            ..where((t) => t.entity.equals('client_payments') & t.entityId.equals(p.id)))
          .get();
      expect(outboxEntries.length, 2); // 1 pour la création, 1 pour l'annulation
      expect(outboxEntries.last.op, 'upsert');
    });

    test('5. Règle du reliquat : refus versement > reliquat et solde de l ancien reçu invariant', () async {
      final order = Order(
        id: 'o_rest',
        clientId: 'c_test',
        title: 'Robe Reliquat',
        fabric: 'Satin',
        price: 50000,
        deliveryDate: DateTime.utc(2026, 12, 10),
        createdAt: clock.now(),
      );
      await orderRepo.save(order);

      // Versement 1 : 30 000 FCFA -> reliquat = 20 000 FCFA
      final p1 = await paymentRepo.addPayment(orderId: 'o_rest', amount: 30000, note: 'V1');
      expect(p1.receiptNumber, 1);

      // Versement de 25 000 FCFA refusé car 25 000 > 20 000
      expect(
        () => paymentRepo.addPayment(orderId: 'o_rest', amount: 25000, note: 'Trop élevé'),
        throwsA(isA<ArgumentError>()),
      );

      // Versement 2 valide : 20 000 FCFA
      final p2 = await paymentRepo.addPayment(orderId: 'o_rest', amount: 20000, note: 'Solde');
      expect(p2.receiptNumber, 2);

      // Solde de l'ancien reçu (photographie au moment du versement 1)
      final allPayments = await paymentRepo.getByOrderId('o_rest');
      final activePaymentsAtP1 = allPayments
          .where((p) => !p.isVoided && p.receiptNumber <= p1.receiptNumber)
          .fold<int>(0, (sum, p) => sum + p.amount);
      final remainingAtP1 = order.price - activePaymentsAtP1;
      expect(remainingAtP1, 20000, reason: 'Le solde calculé au moment du premier reçu ne doit pas changer');

      // Solde au moment du versement 2
      final activePaymentsAtP2 = allPayments
          .where((p) => !p.isVoided && p.receiptNumber <= p2.receiptNumber)
          .fold<int>(0, (sum, p) => sum + p.amount);
      final remainingAtP2 = order.price - activePaymentsAtP2;
      expect(remainingAtP2, 0);
    });

    test('6. Contrainte de clé étrangère : versement sur commande inexistante refusé', () async {
      expect(
        () => paymentRepo.addPayment(orderId: 'o_inexistante', amount: 10000, note: 'Invalide'),
        throwsA(isA<StateError>()),
      );
    });

    test('7. Persistance sur base FICHIER temporaire across restarts (commande + photos + versement + reçu)', () async {
      final tempDir = await Directory.systemTemp.createTemp('angela_tranche3b_test_');
      final dbPath = p.join(tempDir.path, 'angela_persistence.db');

      // Phase 1 : écriture sur base fichier
      final fileDb1 = db_layer.AppDatabase(NativeDatabase(File(dbPath)));
      final oRepo1 = DriftOrderRepository(db: fileDb1, clock: clock, idGenerator: idGen);
      final cRepo1 = DriftClientRepository(db: fileDb1, clock: clock, idGenerator: idGen);

      await cRepo1.save(Client(id: 'c_file', name: 'File Client', phone: '92000000'));
      final order = Order(
        id: 'o_file',
        clientId: 'c_file',
        title: 'Commande Persistée',
        fabric: 'Lin',
        price: 75000,
        deliveryDate: DateTime.utc(2026, 12, 15),
        photos: ['demo:1', 'demo:2'],
        createdAt: clock.now(),
      );

      await oRepo1.createWithDeposit(order: order, depositAmount: 30000, depositNote: 'Acompte fichier');
      await fileDb1.close();

      // Phase 2 : réouverture avec nouvelle instance AppDatabase
      final fileDb2 = db_layer.AppDatabase(NativeDatabase(File(dbPath)));
      final oRepo2 = DriftOrderRepository(db: fileDb2, clock: clock, idGenerator: idGen);
      final pRepo2 = DriftPaymentRepository(db: fileDb2, clock: clock, idGenerator: idGen);

      final reloadedOrder = await oRepo2.getById('o_file');
      expect(reloadedOrder, isNotNull);
      expect(reloadedOrder!.title, 'Commande Persistée');
      expect(reloadedOrder.photos, ['demo:1', 'demo:2']);

      final reloadedPayments = await pRepo2.getByOrderId('o_file');
      expect(reloadedPayments.length, 1);
      expect(reloadedPayments.first.amount, 30000);
      expect(reloadedPayments.first.receiptNumber, 1);
      expect(reloadedPayments.first.note, 'Acompte fichier');

      await fileDb2.close();
      await tempDir.delete(recursive: true);
    });

    test('8. DemoSeeder : seeding commandes + photos + versements, outbox vierge, compteur calé', () async {
      final seeder = DemoSeeder(db);
      final seeded = await seeder.seedIfNecessary(isDebug: true);
      expect(seeded, isTrue);

      // Vérifier sync_state
      final syncState = await (db.select(db.syncState)..where((t) => t.key.equals('demo_seeded:orders'))).getSingleOrNull();
      expect(syncState, isNotNull);

      // Vérifier commandes et versements
      final ordersCount = await db.orders.count().getSingle();
      expect(ordersCount, 15);

      final paymentsCount = await db.clientPayments.count().getSingle();
      expect(paymentsCount, greaterThan(0));

      // Aucune entrée dans sync_outbox
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox, isEmpty, reason: 'Le DemoSeeder ne doit JAMAIS écrire dans sync_outbox');

      // Compteur de reçus calé sur le max des versements démo
      final maxPaymentRow = await (db.selectOnly(db.clientPayments)..addColumns([db.clientPayments.receiptNumber.max()])).getSingle();
      final maxReceipt = maxPaymentRow.read(db.clientPayments.receiptNumber.max())!;

      final counter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('clients'))).getSingle();
      expect(counter.lastValue, maxReceipt);

      // Idempotence : un deuxième appel ne fait rien
      final reseeded = await seeder.seedIfNecessary(isDebug: true);
      expect(reseeded, isFalse);
    });
  });
}
