import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/db/demo_seeder.dart';
import 'package:angela_dress/data/db/id_generator.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/repositories/client_repository.dart';
import 'package:angela_dress/data/repositories/measurement_repository.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/data/utils/sort_utils.dart';

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

  group('Tranche 1 - Clients & Mesures (Drift)', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late IdGenerator idGen;
    late DriftClientRepository clientRepo;
    late DriftMeasurementRepository measurementRepo;

    setUp(() {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 2, 10, 0, 0));
      idGen = const UuidV7IdGenerator();
      clientRepo = DriftClientRepository(db: db, clock: clock, idGenerator: idGen);
      measurementRepo = DriftMeasurementRepository(db: db, clock: clock, idGenerator: idGen);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Client CRUD & outbox (created_at stable, updated_at advances, logical delete)', () async {
      final t0 = clock.currentTime;
      final clientId = idGen.generate();
      final client = Client(id: clientId, name: 'Adjoa Mensah', phone: '90123456', notes: 'VIP');

      // Create
      await clientRepo.save(client);

      final fetched = await clientRepo.getById(clientId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Adjoa Mensah');
      expect(fetched.phone, '90123456');
      expect(fetched.notes, 'VIP');

      // Verify db timestamps
      final rawRow1 = await (db.select(db.clients)..where((t) => t.id.equals(clientId))).getSingle();
      expect(rawRow1.createdAt, t0);
      expect(rawRow1.updatedAt, t0);
      expect(rawRow1.deletedAt, isNull);

      // Verify sync_outbox entry
      final outbox1 = await db.select(db.syncOutbox).get();
      expect(outbox1.length, 1);
      expect(outbox1.first.entity, 'clients');
      expect(outbox1.first.entityId, clientId);
      expect(outbox1.first.op, 'upsert');

      // Update after 2 hours
      clock.currentTime = t0.add(const Duration(hours: 2));
      final updatedClient = Client(id: clientId, name: 'Adjoa Mensah Lawson', phone: '90123456', notes: 'VIP Or');
      await clientRepo.save(updatedClient);

      final rawRow2 = await (db.select(db.clients)..where((t) => t.id.equals(clientId))).getSingle();
      expect(rawRow2.createdAt, t0, reason: 'createdAt doit rester inchangé');
      expect(rawRow2.updatedAt, clock.currentTime, reason: 'updatedAt doit avancer');
      expect(rawRow2.name, 'Adjoa Mensah Lawson');

      // Verify second outbox entry
      final outbox2 = await db.select(db.syncOutbox).get();
      expect(outbox2.length, 2);
      expect(outbox2[1].entity, 'clients');
      expect(outbox2[1].entityId, clientId);
      expect(outbox2[1].op, 'upsert');

      // Logical delete after 4 hours
      clock.currentTime = t0.add(const Duration(hours: 4));
      await clientRepo.delete(clientId);

      final rawRow3 = await (db.select(db.clients)..where((t) => t.id.equals(clientId))).getSingle();
      expect(rawRow3.deletedAt, clock.currentTime);
      expect(rawRow3.updatedAt, clock.currentTime);

      // Verify excluded from getAll() and getById()
      final allClients = await clientRepo.getAll();
      expect(allClients.where((c) => c.id == clientId), isEmpty);
      expect(await clientRepo.getById(clientId), isNull);

      // Verify delete outbox entry
      final outbox3 = await db.select(db.syncOutbox).get();
      expect(outbox3.length, 3);
      expect(outbox3[2].entity, 'clients');
      expect(outbox3[2].entityId, clientId);
      expect(outbox3[2].op, 'delete');
    });

    test('2. writeWithOutbox atomicity on rollback', () async {
      final clientId = idGen.generate();

      await expectLater(
        () => db.writeWithOutbox(
          entity: 'clients',
          entityId: clientId,
          op: 'upsert',
          action: () async {
            await db.into(db.clients).insert(
                  db_layer.ClientsCompanion.insert(
                    id: clientId,
                    name: 'Test Rollback',
                    createdAt: clock.now(),
                    updatedAt: clock.now(),
                  ),
                );
            throw Exception('Simulation erreur transactionnelle');
          },
        ),
        throwsA(isA<Exception>()),
      );

      // Neither client nor outbox entry must exist
      final client = await (db.select(db.clients)..where((t) => t.id.equals(clientId))).getSingleOrNull();
      expect(client, isNull);

      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox, isEmpty);
    });

    test('3. Measurements CRUD & precision of 12 measures + custom measures', () async {
      final clientId = idGen.generate();
      await clientRepo.save(Client(id: clientId, name: 'Koffi Marie'));

      final mId = idGen.generate();
      final originalValues = <String, double>{
        'Épaules': 38.5,
        'Poitrine': 92.25,
        'Taille': 74.0,
        'Bassin': 102.75,
        'Longueur taille': 41.5,
        'Longueur robe': 115.0,
        'Longueur jupe': 65.5,
        'Longueur manche': 59.25,
        'Tour manche': 28.0,
        'Tour poignet': 16.5,
        'Encolure': 36.0,
        'Entre-jambe': 78.5,
        'Mesure sur mesure perso': 44.75,
      };

      final m = Measurement(
        id: mId,
        clientId: clientId,
        takenAt: DateTime.utc(2026, 11, 2, 11, 30),
        values: originalValues,
        note: 'Tissu wax extensible',
      );

      await measurementRepo.save(m);

      final fetched = await measurementRepo.getById(mId);
      expect(fetched, isNotNull);
      expect(fetched!.clientId, clientId);
      expect(fetched.note, 'Tissu wax extensible');
      expect(fetched.values.length, 13);
      for (final entry in originalValues.entries) {
        expect(fetched.values[entry.key], equals(entry.value),
            reason: 'Perte de précision sur ${entry.key}');
      }

      // Stream / watchByClient
      final clientMeasures = await measurementRepo.getByClient(clientId);
      expect(clientMeasures.length, 1);
      expect(clientMeasures.first.id, mId);

      // Outbox check
      final outbox = await (db.select(db.syncOutbox)..where((t) => t.entity.equals('measurements'))).get();
      expect(outbox.length, 1);
      expect(outbox.first.entityId, mId);
      expect(outbox.first.op, 'upsert');

      // Delete
      await measurementRepo.delete(mId);
      expect(await measurementRepo.getById(mId), isNull);
      expect(await measurementRepo.getByClient(clientId), isEmpty);

      final outboxAfterDelete =
          await (db.select(db.syncOutbox)..where((t) => t.entity.equals('measurements'))).get();
      expect(outboxAfterDelete.length, 2);
      expect(outboxAfterDelete[1].op, 'delete');
    });

    test('4. Client deletion rule: rejected with active orders, cascades measurements if none', () async {
      final store = AppStore(
        db: db,
        clientRepository: clientRepo,
        measurementRepository: measurementRepo,
      );
      await store.init();

      // Create client A with order
      final clientA = Client(id: idGen.generate(), name: 'Client Avec Commande');
      await store.saveClient(clientA);
      final mId = idGen.generate();
      await store.saveMeasurement(Measurement(
        id: mId,
        clientId: clientA.id,
        takenAt: DateTime.utc(2026, 11, 2),
        values: {'Poitrine': 90.0},
      ));

      // Add order in store for client A
      final order = Order(
        id: idGen.generate(),
        clientId: clientA.id,
        title: 'Robe cocktail',
        price: 35000,
        fittingDate: DateTime.utc(2026, 11, 10),
        deliveryDate: DateTime.utc(2026, 11, 15),
        createdAt: DateTime.utc(2026, 11, 2),
      );
      await store.saveOrder(order);

      // Attempt deletion -> must fail with StateError
      expect(
        () => store.deleteClient(clientA.id),
        throwsA(isA<StateError>()),
      );

      // Client and measurements still exist
      expect(store.clientById(clientA.id), isNotNull);
      expect(store.measurementsOf(clientA.id), isNotEmpty);

      // Create client B WITHOUT order
      final clientB = Client(id: idGen.generate(), name: 'Client Sans Commande');
      await store.saveClient(clientB);
      final mIdB1 = idGen.generate();
      final mIdB2 = idGen.generate();
      await store.saveMeasurement(Measurement(
        id: mIdB1,
        clientId: clientB.id,
        takenAt: DateTime.utc(2026, 11, 1),
        values: {'Taille': 70.0},
      ));
      await store.saveMeasurement(Measurement(
        id: mIdB2,
        clientId: clientB.id,
        takenAt: DateTime.utc(2026, 11, 2),
        values: {'Taille': 71.0},
      ));

      expect(store.measurementsOf(clientB.id).length, 2);

      // Delete client B -> succeeds
      await store.deleteClient(clientB.id);

      // Verifications in store
      expect(store.clientById(clientB.id), isNull);
      expect(store.measurementsOf(clientB.id), isEmpty);

      // Verifications in database: logical delete on client and both measurements
      final rawClientB = await (db.select(db.clients)..where((t) => t.id.equals(clientB.id))).getSingle();
      expect(rawClientB.deletedAt, isNotNull);

      final rawM1 = await (db.select(db.measurements)..where((t) => t.id.equals(mIdB1))).getSingle();
      expect(rawM1.deletedAt, isNotNull);

      final rawM2 = await (db.select(db.measurements)..where((t) => t.id.equals(mIdB2))).getSingle();
      expect(rawM2.deletedAt, isNotNull);

      // Verify sync_outbox contains delete entries for client and both measurements
      final outboxDelete = await (db.select(db.syncOutbox)..where((t) => t.op.equals('delete'))).get();
      final deletedClientOutbox = outboxDelete.where((o) => o.entity == 'clients' && o.entityId == clientB.id);
      final deletedM1Outbox = outboxDelete.where((o) => o.entity == 'measurements' && o.entityId == mIdB1);
      final deletedM2Outbox = outboxDelete.where((o) => o.entity == 'measurements' && o.entityId == mIdB2);

      expect(deletedClientOutbox.length, 1);
      expect(deletedM1Outbox.length, 1);
      expect(deletedM2Outbox.length, 1);

      store.dispose();
    });

    test('5. File persistence test across restarts', () async {
      final tempDir = Directory.systemTemp.createTempSync('drift_file_test_');
      final dbFile = File('${tempDir.path}/test_angela.db');

      try {
        // Phase 1: Open DB on file and write data
        var fileDb = db_layer.AppDatabase(NativeDatabase(dbFile));
        var fileClientRepo = DriftClientRepository(db: fileDb);
        var fileMeasurementRepo = DriftMeasurementRepository(db: fileDb);

        final cId = idGen.generate();
        await fileClientRepo.save(Client(id: cId, name: 'Félicité Mensah', phone: '90001122'));

        final mId = idGen.generate();
        await fileMeasurementRepo.save(Measurement(
          id: mId,
          clientId: cId,
          takenAt: DateTime.utc(2026, 11, 2, 8, 0),
          values: {'Épaules': 40.0, 'Poitrine': 95.0},
        ));

        await fileDb.close();

        // Phase 2: Reopen a brand new AppDatabase instance on the same physical file
        fileDb = db_layer.AppDatabase(NativeDatabase(dbFile));
        fileClientRepo = DriftClientRepository(db: fileDb);
        fileMeasurementRepo = DriftMeasurementRepository(db: fileDb);

        final reopenedClient = await fileClientRepo.getById(cId);
        expect(reopenedClient, isNotNull);
        expect(reopenedClient!.name, 'Félicité Mensah');
        expect(reopenedClient.phone, '90001122');

        final reopenedMeasurement = await fileMeasurementRepo.getById(mId);
        expect(reopenedMeasurement, isNotNull);
        expect(reopenedMeasurement!.clientId, cId);
        expect(reopenedMeasurement.values['Épaules'], 40.0);
        expect(reopenedMeasurement.values['Poitrine'], 95.0);

        final outboxRows = await fileDb.select(fileDb.syncOutbox).get();
        expect(outboxRows.length, 2);

        await fileDb.close();
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('6. DemoSeeder: debug vs release, idempotence, and no outbox generation', () async {
      final seeder = DemoSeeder(db);

      // In non-debug mode -> does nothing
      final seededRelease = await seeder.seedIfNecessary(isDebug: false);
      expect(seededRelease, isFalse);
      expect(await db.clients.count().getSingle(), 0);

      // In debug mode -> seeds 9 clients and 3 measurements
      final seededDebug = await seeder.seedIfNecessary(isDebug: true);
      expect(seededDebug, isTrue);

      final clientCount = await db.clients.count().getSingle();
      expect(clientCount, 9);

      final measureCount = await db.measurements.count().getSingle();
      expect(measureCount, 3);

      // Check sync_state
      final syncStateRow = await (db.select(db.syncState)..where((t) => t.key.equals('demo_seeded'))).getSingleOrNull();
      expect(syncStateRow, isNotNull);
      expect(syncStateRow!.value, '1');

      // CRITICAL: outbox must remain empty
      final outboxCount = await db.syncOutbox.count().getSingle();
      expect(outboxCount, 0, reason: 'Le seeding démo ne doit JAMAIS écrire dans sync_outbox');

      // Idempotency: calling again does nothing
      final seededAgain = await seeder.seedIfNecessary(isDebug: true);
      expect(seededAgain, isFalse);
      expect(await db.clients.count().getSingle(), 9);
    });

    test('7. Accent and case insensitive sorting ("adama" < "Élise" < "Zoé")', () {
      final names = ['Zoé', 'adama', 'Élise', 'élodie', 'Béatrice', 'benjamin'];
      names.sort(compareCaseAndAccentInsensitive);

      expect(names, [
        'adama',
        'Béatrice',
        'benjamin',
        'Élise',
        'élodie',
        'Zoé',
      ]);
    });
  });
}
