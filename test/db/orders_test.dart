import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/db/converters/datetime_converter.dart';
import 'package:angela_dress/data/db/id_generator.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/repositories/client_repository.dart';
import 'package:angela_dress/data/repositories/order_repository.dart';
import 'package:angela_dress/data/store.dart';

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

  group('Tranche 3A - Commandes & Photos de commande (Drift)', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late IdGenerator idGen;
    late DriftClientRepository clientRepo;
    late DriftOrderRepository orderRepo;

    setUp(() async {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 5, 10, 0, 0));
      idGen = const UuidV7IdGenerator();
      clientRepo = DriftClientRepository(db: db, clock: clock, idGenerator: idGen);
      orderRepo = DriftOrderRepository(db: db, clock: clock, idGenerator: idGen);

      // Créer un client de test
      await clientRepo.save(Client(id: 'c1', name: 'Ama Mensah', phone: '90123456'));
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Commande CRUD & outbox (created_at stable, updated_at avance, logical delete)', () async {
      final t0 = clock.currentTime;
      final oId = idGen.generate();
      final delivery = DateTime.utc(2026, 11, 20);

      final order = Order(
        id: oId,
        clientId: 'c1',
        title: 'Robe de cocktail',
        fabric: 'Satin émeraude',
        price: 45000,
        deliveryDate: delivery,
        photos: ['demo:1', 'demo:2'],
        createdAt: t0,
      );

      // 1.1 Création
      await orderRepo.save(order);

      final fetched = await orderRepo.getById(oId);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Robe de cocktail');
      expect(fetched.fabric, 'Satin émeraude');
      expect(fetched.price, 45000);
      expect(fetched.photos, ['demo:1', 'demo:2']);
      expect(fetched.deliveryDate, delivery);

      // Vérification table orders
      final rawOrder = await (db.select(db.orders)..where((t) => t.id.equals(oId))).getSingle();
      expect(rawOrder.createdAt, t0);
      expect(rawOrder.updatedAt, t0);
      expect(rawOrder.photoPath, 'demo:1');
      expect(rawOrder.deletedAt, isNull);

      // Vérification table order_photos
      final rawPhotos = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(oId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      expect(rawPhotos.length, 2);
      expect(rawPhotos[0].photoPath, 'demo:1');
      expect(rawPhotos[0].position, 0);
      expect(rawPhotos[1].photoPath, 'demo:2');
      expect(rawPhotos[1].position, 1);

      // Vérification outbox : 1 'orders' + 2 'order_photos'
      final outbox1 = await db.select(db.syncOutbox).get();
      expect(outbox1.where((e) => e.entity == 'orders').length, 1);
      expect(outbox1.where((e) => e.entity == 'order_photos').length, 2);

      // 1.2 Modification après 2 heures
      clock.currentTime = t0.add(const Duration(hours: 2));
      final updatedOrder = order.copyWith(status: OrderStatus.cours);
      await orderRepo.save(updatedOrder);

      final rawOrder2 = await (db.select(db.orders)..where((t) => t.id.equals(oId))).getSingle();
      expect(rawOrder2.createdAt, t0, reason: 'created_at doit rester stable');
      expect(rawOrder2.updatedAt, clock.currentTime, reason: 'updated_at doit avancer');
      expect(rawOrder2.status, 'cours');

      // 1.3 Suppression logique
      clock.currentTime = t0.add(const Duration(hours: 4));
      await orderRepo.delete(oId);

      final rawOrder3 = await (db.select(db.orders)..where((t) => t.id.equals(oId))).getSingle();
      expect(rawOrder3.deletedAt, clock.currentTime);

      final deletedPhotos = await (db.select(db.orderPhotos)..where((t) => t.orderId.equals(oId))).get();
      expect(deletedPhotos.every((p) => p.deletedAt != null), isTrue);

      // Exclus du catalogue actif
      final allActive = await orderRepo.getAll();
      expect(allActive.any((o) => o.id == oId), isFalse);
    });

    test('2. Photos de commande : diffing, réordonnancement, suppression et ajout', () async {
      final oId = idGen.generate();
      final order1 = Order(
        id: oId,
        clientId: 'c1',
        title: 'Ensemble Wax',
        price: 30000,
        deliveryDate: DateTime.utc(2026, 11, 15),
        photos: ['photo_A', 'photo_B', 'photo_C'],
        createdAt: clock.now(),
      );

      await orderRepo.save(order1);

      var photosInDb = await (db.select(db.orderPhotos)
            ..where((t) => t.orderId.equals(oId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.position)]))
          .get();
      expect(photosInDb.map((p) => p.photoPath).toList(), ['photo_A', 'photo_B', 'photo_C']);
      final idA = photosInDb[0].id;
      final idB = photosInDb[1].id;
      final idC = photosInDb[2].id;

      // Réordonner : ['photo_C', 'photo_A', 'photo_D'] (B retiré, C premier, A deuxième, D ajouté)
      final order2 = Order(
        id: oId,
        clientId: 'c1',
        title: 'Ensemble Wax',
        price: 30000,
        deliveryDate: DateTime.utc(2026, 11, 15),
        photos: ['photo_C', 'photo_A', 'photo_D'],
        createdAt: clock.now(),
      );
      await orderRepo.save(order2);

      final fetched2 = await orderRepo.getById(oId);
      expect(fetched2!.photos, ['photo_C', 'photo_A', 'photo_D']);

      // Vérifier en base que B est supprimé logiquement
      final photoB = await (db.select(db.orderPhotos)..where((t) => t.id.equals(idB))).getSingle();
      expect(photoB.deletedAt, isNotNull);

      // Vérifier que C et A ont leurs positions mises à jour
      final photoC = await (db.select(db.orderPhotos)..where((t) => t.id.equals(idC))).getSingle();
      expect(photoC.position, 0);

      final photoA = await (db.select(db.orderPhotos)..where((t) => t.id.equals(idA))).getSingle();
      expect(photoA.position, 1);

      // Vérifier l'outbox pour order_photos
      final outboxPhotos = await (db.select(db.syncOutbox)..where((t) => t.entity.equals('order_photos'))).get();
      expect(outboxPhotos.any((o) => o.entityId == idB && o.op == 'delete'), isTrue);
    });

    test('3. Règle suppression client via OrderRepository (SQL)', () async {
      final c2Id = idGen.generate();
      await clientRepo.save(Client(id: c2Id, name: 'Client Avec Commande'));

      final oId = idGen.generate();
      await orderRepo.save(Order(
        id: oId,
        clientId: c2Id,
        title: 'Chemise',
        price: 20000,
        deliveryDate: DateTime.utc(2026, 11, 18),
        createdAt: clock.now(),
      ));

      final store = AppStore(
        db: db,
        clientRepository: clientRepo,
        orderRepository: orderRepo,
      );
      await store.init();

      // La suppression du client doit être refusée car il a une commande active
      expect(
        () => store.deleteClient(c2Id),
        throwsA(isA<StateError>()),
      );

      // Supprimer la commande
      await store.deleteOrder(oId);

      // Maintenant la suppression du client doit réussir
      await store.deleteClient(c2Id);
      expect(await clientRepo.getById(c2Id), isNull);
    });

    test('4. Refus de fixation d un prix inférieur aux versements non annulés', () async {
      final oId = idGen.generate();
      await orderRepo.save(Order(
        id: oId,
        clientId: 'c1',
        title: 'Costume',
        price: 80000,
        deliveryDate: DateTime.utc(2026, 11, 25),
        createdAt: clock.now(),
      ));

      // Simuler un versement de 50 000 FCFA
      await db.into(db.clientPayments).insert(
            db_layer.ClientPaymentsCompanion.insert(
              id: 'p1',
              orderId: oId,
              amount: 50000,
              paidAt: clock.now(),
              receiptNumber: 101,
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      // Tenter de réduire le prix à 40 000 FCFA (< 50 000)
      expect(
        () => orderRepo.save(Order(
          id: oId,
          clientId: 'c1',
          title: 'Costume',
          price: 40000,
          deliveryDate: DateTime.utc(2026, 11, 25),
          createdAt: clock.now(),
        )),
        throwsA(isA<ArgumentError>()),
      );

      // Fixer à 50 000 FCFA ou plus doit réussir
      await orderRepo.save(Order(
        id: oId,
        clientId: 'c1',
        title: 'Costume',
        price: 50000,
        deliveryDate: DateTime.utc(2026, 11, 25),
        createdAt: clock.now(),
      ));
      final updated = await orderRepo.getById(oId);
      expect(updated!.price, 50000);
    });

    test('5. Refus de suppression d une commande avec versement non annulé', () async {
      final oId = idGen.generate();
      await orderRepo.save(Order(
        id: oId,
        clientId: 'c1',
        title: 'Jupe Wax',
        price: 15000,
        deliveryDate: DateTime.utc(2026, 11, 10),
        createdAt: clock.now(),
      ));

      // Ajouter un versement
      await db.into(db.clientPayments).insert(
            db_layer.ClientPaymentsCompanion.insert(
              id: 'p_jupe',
              orderId: oId,
              amount: 10000,
              paidAt: clock.now(),
              receiptNumber: 102,
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      // Suppression refusée
      expect(() => orderRepo.delete(oId), throwsA(isA<StateError>()));

      // Annuler le versement
      await (db.update(db.clientPayments)..where((t) => t.id.equals('p_jupe'))).write(
        db_layer.ClientPaymentsCompanion(
          voidedAt: Value(clock.now()),
          voidReason: const Value('Erreur saisie'),
          updatedAt: Value(clock.now()),
        ),
      );

      // Maintenant la suppression réussit
      await orderRepo.delete(oId);
      final deleted = await (db.select(db.orders)..where((t) => t.id.equals(oId))).getSingle();
      expect(deleted.deletedAt, isNotNull);
    });

    test('6. Dates jour-seul : conservation exacte du jour (UTC / Date calendaire)', () {
      final pickedDate = DateTime(2026, 11, 5); // Simule showDatePicker local
      final normalized = normalizeDate(pickedDate);

      expect(normalized.year, 2026);
      expect(normalized.month, 11);
      expect(normalized.day, 5);
      expect(normalized.isUtc, isTrue);

      final converter = const DateTimeConverter();
      final inSql = converter.toSql(normalized);
      final fromSql = converter.fromSql(inSql);

      expect(fromSql.year, 2026);
      expect(fromSql.month, 11);
      expect(fromSql.day, 5);
    });
  });
}

