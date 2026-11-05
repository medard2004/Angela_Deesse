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
import 'package:angela_dress/data/repositories/modele_repository.dart';
import 'package:angela_dress/data/repositories/realisation_repository.dart';
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

  group('Tranche 2 - Modèles & Réalisations (Drift)', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late IdGenerator idGen;
    late DriftClientRepository clientRepo;
    late DriftMeasurementRepository measurementRepo;
    late DriftModeleRepository modeleRepo;
    late DriftRealisationRepository realisationRepo;

    setUp(() {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 2, 10, 0, 0));
      idGen = const UuidV7IdGenerator();
      clientRepo = DriftClientRepository(db: db, clock: clock, idGenerator: idGen);
      measurementRepo = DriftMeasurementRepository(db: db, clock: clock, idGenerator: idGen);
      modeleRepo = DriftModeleRepository(db: db, clock: clock, idGenerator: idGen);
      realisationRepo = DriftRealisationRepository(db: db, clock: clock, idGenerator: idGen);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Modèle CRUD & outbox (création, modification, suppression logique, horodatages)', () async {
      final t0 = clock.currentTime;
      final mId = idGen.generate();
      final modele = Modele(id: mId, name: 'Robe de bal', description: 'Belle robe longue', photo: 'demo:1');

      // Création
      await modeleRepo.save(modele);

      final fetched = await modeleRepo.getById(mId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Robe de bal');
      expect(fetched.description, 'Belle robe longue');
      expect(fetched.photo, 'demo:1');

      // Vérification en base Drift (created_at et updated_at)
      final rawRow1 = await (db.select(db.modeles)..where((t) => t.id.equals(mId))).getSingle();
      expect(rawRow1.createdAt, t0);
      expect(rawRow1.updatedAt, t0);
      expect(rawRow1.deletedAt, isNull);
      expect(rawRow1.photoUploadState, 'none');

      // Vérification sync_outbox
      final outbox1 = await db.select(db.syncOutbox).get();
      expect(outbox1.length, 1);
      expect(outbox1.first.entity, 'modeles');
      expect(outbox1.first.entityId, mId);
      expect(outbox1.first.op, 'upsert');

      // Modification après 2 heures
      clock.currentTime = t0.add(const Duration(hours: 2));
      final updatedModele = Modele(id: mId, name: 'Robe de bal prestige', description: 'Soie et broderies', photo: 'demo:2');
      await modeleRepo.save(updatedModele);

      final rawRow2 = await (db.select(db.modeles)..where((t) => t.id.equals(mId))).getSingle();
      expect(rawRow2.createdAt, t0, reason: 'created_at doit rester stable');
      expect(rawRow2.updatedAt, clock.currentTime, reason: 'updated_at doit avancer');
      expect(rawRow2.name, 'Robe de bal prestige');

      final outbox2 = await db.select(db.syncOutbox).get();
      expect(outbox2.length, 2);
      expect(outbox2[1].entity, 'modeles');
      expect(outbox2[1].entityId, mId);
      expect(outbox2[1].op, 'upsert');

      // Suppression logique après 3 heures
      clock.currentTime = t0.add(const Duration(hours: 3));
      await modeleRepo.delete(mId);

      final rawRow3 = await (db.select(db.modeles)..where((t) => t.id.equals(mId))).getSingle();
      expect(rawRow3.deletedAt, clock.currentTime);
      expect(rawRow3.updatedAt, clock.currentTime);

      // Vérification outbox 'delete'
      final outbox3 = await db.select(db.syncOutbox).get();
      expect(outbox3.length, 3);
      expect(outbox3[2].entity, 'modeles');
      expect(outbox3[2].entityId, mId);
      expect(outbox3[2].op, 'delete');

      // Lecture par getById sans includeDeleted -> null
      expect(await modeleRepo.getById(mId), isNull);
      // Lecture par getById avec includeDeleted -> retrouve le modèle
      final withDeleted = await modeleRepo.getById(mId, includeDeleted: true);
      expect(withDeleted, isNotNull);
      expect(withDeleted!.name, 'Robe de bal prestige');

      // Catalogue sans les supprimés
      final catalogue = await modeleRepo.getAll();
      expect(catalogue.any((m) => m.id == mId), isFalse);
    });

    test('2. Modèle dans AppStore : catalogue sans supprimés, modeleById inclut supprimés', () async {
      final store = AppStore(
        db: db,
        clientRepository: clientRepo,
        measurementRepository: measurementRepo,
        modeleRepository: modeleRepo,
        realisationRepository: realisationRepo,
      );

      final m1 = Modele(id: 'm1', name: 'Boubou royal', photo: 'demo:1');
      final m2 = Modele(id: 'm2', name: 'Veste africaine', photo: 'demo:2');
      await store.saveModele(m1);
      await store.saveModele(m2);

      expect(store.modeles.length, 2);
      expect(store.modeleById('m1')?.name, 'Boubou royal');
      expect(store.modeleById('m2')?.name, 'Veste africaine');

      // Supprimer m1
      await store.deleteModele('m1');

      // Le catalogue n'affiche plus m1
      expect(store.modeles.map((m) => m.id), ['m2']);
      expect(store.modeles.any((m) => m.id == 'm1'), isFalse);

      // modeleById('m1') continue de renvoyer m1 (pour les commandes existantes)
      final resolved = store.modeleById('m1');
      expect(resolved, isNotNull);
      expect(resolved!.id, 'm1');
      expect(resolved.name, 'Boubou royal');
    });

    test('3. Réalisation CRUD : avec client, sans client, outbox, suppression logique', () async {
      final t0 = clock.currentTime;
      // Insérer un client pour la FK
      final cId = idGen.generate();
      await clientRepo.save(Client(id: cId, name: 'Sika Mensah', phone: '90001122'));

      // Création avec client
      final r1Id = idGen.generate();
      final r1 = Realisation(
        id: r1Id,
        photo: 'demo:3',
        category: 'Robe',
        clientId: cId,
        caption: 'Robe sirène sur mesure',
        createdAt: t0,
      );
      await realisationRepo.save(r1);

      // Création sans client
      final r2Id = idGen.generate();
      final r2 = Realisation(
        id: r2Id,
        photo: 'demo:4',
        category: 'Costume',
        clientId: null,
        caption: 'Costume d exposition',
        createdAt: t0.add(const Duration(minutes: 5)),
      );
      await realisationRepo.save(r2);

      final list = await realisationRepo.getAll();
      expect(list.length, 2);
      expect(list.any((r) => r.id == r1Id), isTrue);
      expect(list.any((r) => r.id == r2Id), isTrue);

      // Vérification outbox
      final outbox = await (db.select(db.syncOutbox)..where((t) => t.entity.equals('realisations'))).get();
      expect(outbox.length, 2);
      expect(outbox.every((o) => o.op == 'upsert'), isTrue);

      // Suppression logique de r1
      clock.currentTime = t0.add(const Duration(hours: 1));
      await realisationRepo.delete(r1Id);

      final listAfterDel = await realisationRepo.getAll();
      expect(listAfterDel.length, 1);
      expect(listAfterDel.first.id, r2Id);

      final outboxDel = await (db.select(db.syncOutbox)
            ..where((t) => t.entity.equals('realisations') & t.entityId.equals(r1Id)))
          .get();
      expect(outboxDel.last.op, 'delete');
    });

    test('4. Réalisation liée à un client supprimé logiquement : lecture sans plantage', () async {
      final cId = idGen.generate();
      await clientRepo.save(Client(id: cId, name: 'Koffi Paul', phone: '91234567'));

      final rId = idGen.generate();
      await realisationRepo.save(Realisation(
        id: rId,
        photo: 'demo:5',
        category: 'Chemise',
        clientId: cId,
        caption: 'Chemise brodée',
        createdAt: clock.currentTime,
      ));

      // Supprimer le client logiquement
      await clientRepo.delete(cId);

      // Vérifier que le client est supprimé
      final deletedClient = await clientRepo.getById(cId);
      expect(deletedClient, isNull);

      // La réalisation doit toujours exister et être lue sans erreur
      final fetchedRealisation = await realisationRepo.getById(rId);
      expect(fetchedRealisation, isNotNull);
      expect(fetchedRealisation!.clientId, cId);

      // Vérification dans l'AppStore
      final store = AppStore(
        db: db,
        clientRepository: clientRepo,
        measurementRepository: measurementRepo,
        modeleRepository: modeleRepo,
        realisationRepository: realisationRepo,
      );
      await store.init();

      final rInStore = store.realisations.where((r) => r.id == rId).firstOrNull;
      expect(rInStore, isNotNull);
      // Le client est supprimé, clientById renvoie null, pas de crash
      final clientInStore = store.clientById(rInStore!.clientId);
      expect(clientInStore, isNull);
    });

    test('5. Tri insensible à la casse et aux accents, filtre par catégorie', () async {
      // Tri des modèles
      final m1 = Modele(id: 'tm1', name: 'élégance soyeuse');
      final m2 = Modele(id: 'tm2', name: 'Abaya brodée');
      final m3 = Modele(id: 'tm3', name: 'costume 3 pièces');
      final m4 = Modele(id: 'tm4', name: 'Évasée wax');

      await modeleRepo.save(m1);
      await modeleRepo.save(m2);
      await modeleRepo.save(m3);
      await modeleRepo.save(m4);

      final store = AppStore(
        db: db,
        clientRepository: clientRepo,
        measurementRepository: measurementRepo,
        modeleRepository: modeleRepo,
        realisationRepository: realisationRepo,
      );
      await store.init();

      final names = store.modeles
          .where((m) => m.id.startsWith('tm'))
          .map((m) => m.name)
          .toList();
      // Ordre alphabétique sans accent ni casse :
      // 1. "Abaya brodée" (A)
      // 2. "costume 3 pièces" (C)
      // 3. "élégance soyeuse" (E)
      // 4. "Évasée wax" (E)
      expect(names[0], 'Abaya brodée');
      expect(names[1], 'costume 3 pièces');
      expect(names[2], 'élégance soyeuse');
      expect(names[3], 'Évasée wax');

      // Filtre par catégorie de réalisations
      await realisationRepo.save(Realisation(
        id: 'tr1',
        photo: 'demo:1',
        category: 'Robe',
        createdAt: DateTime.utc(2026, 11, 2, 8),
      ));
      await realisationRepo.save(Realisation(
        id: 'tr2',
        photo: 'demo:2',
        category: 'robe',
        createdAt: DateTime.utc(2026, 11, 2, 9),
      ));
      await realisationRepo.save(Realisation(
        id: 'tr3',
        photo: 'demo:3',
        category: 'Chemise',
        createdAt: DateTime.utc(2026, 11, 2, 10),
      ));

      final robes = (await realisationRepo.getAll())
          .where((r) => r.id.startsWith('tr') && equalsCaseAndAccentInsensitive(r.category, 'ROBE'))
          .toList();
      expect(robes.length, 2);
      expect(robes.map((r) => r.id).toSet(), {'tr1', 'tr2'});
    });

    test('6. DemoSeeder : clés par entité, migration de l ancienne clé, aucune écriture dans sync_outbox', () async {
      // Test 6.1 : Seeding vierge
      final seeder = DemoSeeder(db);
      final seeded = await seeder.seedIfNecessary(isDebug: true);
      expect(seeded, isTrue);

      // Vérifier les 3 clés dans sync_state
      final syncStates = await db.select(db.syncState).get();
      final keys = syncStates.map((s) => s.key).toSet();
      expect(keys, contains('demo_seeded:clients'));
      expect(keys, contains('demo_seeded:modeles'));
      expect(keys, contains('demo_seeded:realisations'));

      // Vérifier le contenu seedé
      final clientsCount = await db.clients.count().getSingle();
      expect(clientsCount, 9);
      final modelesCount = await db.modeles.count().getSingle();
      expect(modelesCount, 6);
      final realisationsCount = await db.realisations.count().getSingle();
      expect(realisationsCount, 9);

      // Vérifier qu'AUCUNE écriture n'a été faite dans sync_outbox
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox, isEmpty, reason: 'Le DemoSeeder ne doit JAMAIS écrire dans sync_outbox');

      // Test 6.2 : Idempotence (un second appel ne fait rien)
      final reseeded = await seeder.seedIfNecessary(isDebug: true);
      expect(reseeded, isFalse);

      // Test 6.3 : Migration de l'ancienne clé unique 'demo_seeded'
      final db2 = db_layer.AppDatabase(NativeDatabase.memory());
      // Simuler l'état Tranche 1 : clients présents et clé 'demo_seeded' = '1'
      await db2.into(db2.clients).insert(
            db_layer.ClientsCompanion.insert(
              id: 'c0',
              name: 'Client Existant',
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );
      await db2.into(db2.syncState).insert(
            db_layer.SyncStateCompanion.insert(
              key: 'demo_seeded',
              value: '1',
              updatedAt: clock.now(),
            ),
          );

      final seeder2 = DemoSeeder(db2);
      final seeded2 = await seeder2.seedIfNecessary(isDebug: true);
      expect(seeded2, isTrue);

      final syncStates2 = await db2.select(db2.syncState).get();
      final keys2 = syncStates2.map((s) => s.key).toSet();
      expect(keys2, contains('demo_seeded:clients'));
      expect(keys2, contains('demo_seeded:modeles'));
      expect(keys2, contains('demo_seeded:realisations'));
      expect(keys2, isNot(contains('demo_seeded')), reason: 'L ancienne clé unique doit être migrée');

      // Les clients n'ont pas été réinsérés (toujours 1 client : 'c0')
      final clientsCount2 = await db2.clients.count().getSingle();
      expect(clientsCount2, 1);
      // Les modèles et réalisations ont été seedés
      expect(await db2.modeles.count().getSingle(), 6);
      expect(await db2.realisations.count().getSingle(), 9);

      // Toujours zéro outbox
      expect(await db2.select(db2.syncOutbox).get(), isEmpty);

      await db2.close();
    });

    test('7. Atomicité & Rollback si l écriture échoue', () async {
      final initialModeles = await db.select(db.modeles).get();
      final initialOutbox = await db.select(db.syncOutbox).get();

      expect(
        () async {
          await db.writeWithOutbox(
            entity: 'modeles',
            entityId: 'fail_id',
            op: 'upsert',
            action: () async {
              await db.into(db.modeles).insert(
                    db_layer.ModelesCompanion.insert(
                      id: 'fail_id',
                      name: 'Ce modèle va échouer',
                      createdAt: clock.now(),
                      updatedAt: clock.now(),
                    ),
                  );
              throw Exception('Simulation erreur fatale');
            },
          );
        },
        throwsA(isA<Exception>()),
      );

      // Vérifier que le modèle n'a PAS été inséré
      final modelesAfter = await db.select(db.modeles).get();
      expect(modelesAfter.length, initialModeles.length);

      // Vérifier que l'outbox n'a PAS été modifiée
      final outboxAfter = await db.select(db.syncOutbox).get();
      expect(outboxAfter.length, initialOutbox.length);
    });

    test('8. Persistance sur base FICHIER temporaire across restarts', () async {
      final tempDir = await Directory.systemTemp.createTemp('angela_tranche2_test_');
      final file = File('${tempDir.path}/test_db.sqlite');

      // 1. Ouvrir la base fichier
      final dbFile1 = db_layer.AppDatabase(NativeDatabase(file));
      final modeleRepo1 = DriftModeleRepository(db: dbFile1);
      final clientRepo1 = DriftClientRepository(db: dbFile1);
      final realisationRepo1 = DriftRealisationRepository(db: dbFile1);

      await clientRepo1.save(Client(id: 'c_pers', name: 'Client Persistant'));
      await modeleRepo1.save(Modele(id: 'm_pers', name: 'Modèle Persistant', description: 'Test fichier', photo: 'demo:7'));
      await realisationRepo1.save(Realisation(
        id: 'r_pers',
        photo: 'demo:8',
        category: 'Costume',
        clientId: 'c_pers',
        caption: 'Réalisation persistante',
        createdAt: DateTime.utc(2026, 11, 2, 12),
      ));

      // Fermer la base 1
      await dbFile1.close();

      // 2. Rouvrir la base sur le même fichier
      final dbFile2 = db_layer.AppDatabase(NativeDatabase(file));
      final modeleRepo2 = DriftModeleRepository(db: dbFile2);
      final realisationRepo2 = DriftRealisationRepository(db: dbFile2);

      final fetchedModele = await modeleRepo2.getById('m_pers');
      expect(fetchedModele, isNotNull);
      expect(fetchedModele!.name, 'Modèle Persistant');
      expect(fetchedModele.description, 'Test fichier');
      expect(fetchedModele.photo, 'demo:7');

      final fetchedRealisation = await realisationRepo2.getById('r_pers');
      expect(fetchedRealisation, isNotNull);
      expect(fetchedRealisation!.caption, 'Réalisation persistante');
      expect(fetchedRealisation.category, 'Costume');
      expect(fetchedRealisation.clientId, 'c_pers');

      await dbFile2.close();
      await tempDir.delete(recursive: true);
    });
  });
}
