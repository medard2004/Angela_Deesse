import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/db/converters/datetime_converter.dart';
import 'package:angela_dress/data/db/demo_seeder.dart';
import 'package:angela_dress/data/db/id_generator.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/repositories/apprentice_payment_repository.dart';
import 'package:angela_dress/data/repositories/apprentice_repository.dart';

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

  group('Tranche 4 - Apprentis, versements d écolage et reçus (Drift)', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late IdGenerator idGen;
    late DriftApprenticeRepository apprenticeRepo;
    late DriftApprenticePaymentRepository paymentRepo;

    setUp(() async {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 5, 10, 0));
      idGen = const UuidV7IdGenerator();
      apprenticeRepo = DriftApprenticeRepository(db: db, clock: clock, idGenerator: idGen);
      paymentRepo = DriftApprenticePaymentRepository(db: db, clock: clock, idGenerator: idGen);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Apprenti CRUD : création, modification, suppression logique, horodatages, outbox', () async {
      final aId = idGen.generate();
      final startDate = DateTime.utc(2026, 1, 15);
      final nextDue = DateTime.utc(2026, 12, 1);

      // Création
      final apprentice = Apprentice(
        id: aId,
        name: 'Fatou Traoré',
        phone: '90123456',
        startDate: startDate,
        totalFee: 150000,
        nextDue: nextDue,
        notes: 'Formation coupe & couture',
        createdAt: clock.now(),
      );

      await apprenticeRepo.save(apprentice);

      // Lecture
      final fetched = await apprenticeRepo.getById(aId);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Fatou Traoré');
      expect(fetched.phone, '90123456');
      expect(fetched.totalFee, 150000);
      expect(fetched.startDate, startDate);
      expect(fetched.nextDue, nextDue);
      expect(fetched.createdAt, clock.now());
      expect(fetched.updatedAt, clock.now());

      // Vérifier outbox (1 entrée 'apprentices')
      var outbox = await db.select(db.syncOutbox).get();
      expect(outbox.length, 1);
      expect(outbox.first.entity, 'apprentices');
      expect(outbox.first.entityId, aId);

      // Modification : created_at stable, updated_at avance
      final advancedTime = clock.now().add(const Duration(hours: 3));
      clock.currentTime = advancedTime;

      await apprenticeRepo.save(fetched.copyWith(
        phone: '90998877',
        notes: 'Avancée au module 2',
      ));

      final updated = await apprenticeRepo.getById(aId);
      expect(updated!.phone, '90998877');
      expect(updated.notes, 'Avancée au module 2');
      expect(updated.createdAt, DateTime.utc(2026, 11, 5, 10, 0));
      expect(updated.updatedAt, advancedTime);

      outbox = await db.select(db.syncOutbox).get();
      expect(outbox.length, 2);

      // Suppression logique
      final deleteTime = advancedTime.add(const Duration(hours: 1));
      clock.currentTime = deleteTime;

      await apprenticeRepo.delete(aId);

      // Absent du flux actif
      final allActive = await apprenticeRepo.watchAll().first;
      expect(allActive.any((a) => a.id == aId), isFalse);

      // Toujours présent en base avec deleted_at
      final rawRow = await (db.select(db.apprentices)..where((t) => t.id.equals(aId))).getSingle();
      expect(rawRow.deletedAt, deleteTime);

      outbox = await db.select(db.syncOutbox).get();
      expect(outbox.length, 3);
    });

    test('1b. Création avec acompte : atomicité complète et rollback si échec', () async {
      final aId = idGen.generate();
      final apprentice = Apprentice(
        id: aId,
        name: 'Sékou Touré',
        phone: '98765432',
        startDate: DateTime.utc(2026, 2, 1),
        totalFee: 120000,
        createdAt: clock.now(),
      );

      // 1. Succès : apprenti + acompte créés dans la même transaction
      final payment = await apprenticeRepo.createWithDeposit(
        apprentice: apprentice,
        depositAmount: 40000,
        depositNote: 'Acompte initial',
      );

      expect(payment.receiptNumber, 1);
      expect(payment.totalFeeAtPayment, 120000);
      expect(payment.balanceAfter, 80000);
      expect(payment.note, 'Acompte initial');

      // Vérifier en base
      final fetchedApp = await apprenticeRepo.getById(aId);
      expect(fetchedApp, isNotNull);
      final payments = await paymentRepo.getByApprenticeId(aId);
      expect(payments.length, 1);

      // Vérifier le compteur de reçus
      final counter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('apprentices'))).getSingle();
      expect(counter.lastValue, 1);

      // Outbox : 1 apprentice + 1 apprentice_payment = 2 entrées
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.length, 2);
      expect(outbox.map((e) => e.entity).toSet(), containsAll(['apprentices', 'apprentice_payments']));

      // 2. Échec : acompte invalide (supérieur aux frais)
      final failId = idGen.generate();
      final failApprentice = Apprentice(
        id: failId,
        name: 'Apprenti Invalide',
        phone: '00000000',
        startDate: clock.now(),
        totalFee: 50000,
        createdAt: clock.now(),
      );

      expect(
        () => apprenticeRepo.createWithDeposit(
          apprentice: failApprentice,
          depositAmount: 60000, // Supérieur à 50 000
          depositNote: 'Trop élevé',
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Vérifier que l'apprenti n'existe pas en base
      final failFetched = await (db.select(db.apprentices)..where((t) => t.id.equals(failId))).getSingleOrNull();
      expect(failFetched, isNull);

      // Le compteur de reçus n'a pas bougé (toujours à 1)
      final counterAfterFail = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('apprentices'))).getSingle();
      expect(counterAfterFail.lastValue, 1);

      // Aucune entrée d'outbox supplémentaire
      final outboxAfterFail = await db.select(db.syncOutbox).get();
      expect(outboxAfterFail.length, 2);
    });

    test('2. Atomicité & Rollback si l écriture échoue', () async {
      // Vérifier que writeWithOutbox annule la transaction si une erreur survient
      final outboxBefore = await db.select(db.syncOutbox).get();
      expect(outboxBefore, isEmpty);

      expect(
        () => db.writeWithOutbox(
          entity: 'apprentices',
          entityId: 'fail_id',
          op: 'create',
          action: () async {
            await db.into(db.apprentices).insert(
                  db_layer.ApprenticesCompanion.insert(
                    id: 'fail_id',
                    name: 'Test Failure',
                    phone: const Value('0000'),
                    startDate: clock.now(),
                    totalFee: 100000,
                    createdAt: clock.now(),
                    updatedAt: clock.now(),
                  ),
                );
            throw Exception('Simulation erreur transactionnelle');
          },
        ),
        throwsA(predicate((e) => e.toString().contains('Simulation erreur transactionnelle'))),
      );

      // Rien n'a été inséré dans apprentices ni dans sync_outbox
      final apprentice = await (db.select(db.apprentices)..where((t) => t.id.equals('fail_id'))).getSingleOrNull();
      expect(apprentice, isNull);

      final outboxAfter = await db.select(db.syncOutbox).get();
      expect(outboxAfter, isEmpty);
    });

    test('3. Versement écolage : numéros séquentiels, concurrence et pas de trou sur rollback', () async {
      final aId = idGen.generate();
      await apprenticeRepo.save(Apprentice(
        id: aId,
        name: 'Awa Cissé',
        phone: '91234567',
        startDate: clock.now(),
        totalFee: 100000,
        createdAt: clock.now(),
      ));

      // Premier versement
      final p1 = await paymentRepo.addPayment(
        apprenticeId: aId,
        amount: 30000,
        note: 'Tranche 1',
      );
      expect(p1.receiptNumber, 1);
      expect(p1.totalFeeAtPayment, 100000);
      expect(p1.balanceAfter, 70000);

      // Deuxième versement
      final p2 = await paymentRepo.addPayment(
        apprenticeId: aId,
        amount: 20000,
        note: 'Tranche 2',
      );
      expect(p2.receiptNumber, 2);
      expect(p2.totalFeeAtPayment, 100000);
      expect(p2.balanceAfter, 50000);

      // Compteur de reçus calé à 2
      final counter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('apprentices'))).getSingle();
      expect(counter.lastValue, 2);

      // Simulation de concurrence : Future.wait sur 2 versements
      final results = await Future.wait([
        paymentRepo.addPayment(apprenticeId: aId, amount: 5000, note: 'Conc 1'),
        paymentRepo.addPayment(apprenticeId: aId, amount: 5000, note: 'Conc 2'),
      ]);
      final receiptNos = results.map((p) => p.receiptNumber).toSet();
      expect(receiptNos.length, 2, reason: 'Deux versements simultanés doivent avoir des numéros distincts');
      expect(receiptNos, containsAll([3, 4]));

      // Rollback ne doit pas incrémenter le compteur ni créer de trou
      try {
        await paymentRepo.addPayment(
          apprenticeId: aId,
          amount: 999999, // Montant supérieur au solde restant (40 000) -> rejeté
          note: 'Trop élevé',
        );
        fail('Devrait refuser le montant trop élevé');
      } catch (e) {
        expect(e, isA<ArgumentError>());
      }

      // Le compteur doit toujours être à 4
      final counterAfterRollback = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('apprentices'))).getSingle();
      expect(counterAfterRollback.lastValue, 4);

      // Le versement suivant prend le numéro 5 (pas de trou)
      final pNext = await paymentRepo.addPayment(
        apprenticeId: aId,
        amount: 10000,
        note: 'Tranche 3',
      );
      expect(pNext.receiptNumber, 5);
      expect(pNext.balanceAfter, 30000);
    });

    test('4. Reconcile après insertion de versements restaurés', () async {
      final aId = idGen.generate();
      await apprenticeRepo.save(Apprentice(
        id: aId,
        name: 'Restauration Test',
        phone: '93333333',
        startDate: clock.now(),
        totalFee: 500000,
        createdAt: clock.now(),
      ));

      // Insérer directement des versements avec numéros élevés (ex: synchronisation/restauration)
      await db.into(db.apprenticePayments).insert(
            db_layer.ApprenticePaymentsCompanion.insert(
              id: 'p_restored_1',
              apprenticeId: aId,
              amount: 50000,
              paidAt: clock.now(),
              receiptNumber: 15,
              totalFeeAtPayment: 500000,
              balanceAfter: 450000,
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      // Réconciliation
      await db.reconcileReceiptCounters();

      final counter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('apprentices'))).getSingle();
      expect(counter.lastValue, 15);

      // Le versement suivant obtient 16
      final nextP = await paymentRepo.addPayment(
        apprenticeId: aId,
        amount: 10000,
        note: 'Après réconciliation',
      );
      expect(nextP.receiptNumber, 16);
    });

    test('5. Reçu immuable : annuler un versement ancien ne modifie pas les reçus ultérieurs', () async {
      final aId = idGen.generate();
      await apprenticeRepo.save(Apprentice(
        id: aId,
        name: 'Kadiatou Diallo',
        phone: '92222222',
        startDate: clock.now(),
        totalFee: 100000,
        createdAt: clock.now(),
      ));

      final v1 = await paymentRepo.addPayment(apprenticeId: aId, amount: 20000, note: 'V1');
      final v2 = await paymentRepo.addPayment(apprenticeId: aId, amount: 30000, note: 'V2');
      final v3 = await paymentRepo.addPayment(apprenticeId: aId, amount: 10000, note: 'V3');

      expect(v1.totalFeeAtPayment, 100000);
      expect(v1.balanceAfter, 80000);
      expect(v2.totalFeeAtPayment, 100000);
      expect(v2.balanceAfter, 50000);
      expect(v3.totalFeeAtPayment, 100000);
      expect(v3.balanceAfter, 40000);

      // Annuler v1
      await paymentRepo.voidPayment(id: v1.id, reason: 'Chèque sans provision');

      // Relire v2 et v3 depuis la base
      final reloadedV2 = await paymentRepo.getById(v2.id);
      final reloadedV3 = await paymentRepo.getById(v3.id);

      expect(reloadedV2!.totalFeeAtPayment, 100000, reason: 'totalFeeAtPayment doit rester figé');
      expect(reloadedV2.balanceAfter, 50000, reason: 'balanceAfter doit rester figé');
      expect(reloadedV2.receiptNumber, v2.receiptNumber);

      expect(reloadedV3!.totalFeeAtPayment, 100000, reason: 'totalFeeAtPayment doit rester figé');
      expect(reloadedV3.balanceAfter, 40000, reason: 'balanceAfter doit rester figé');
      expect(reloadedV3.receiptNumber, v3.receiptNumber);

      // Modifier totalFee de l'apprenti après coup
      final app = await apprenticeRepo.getById(aId);
      await apprenticeRepo.save(app!.copyWith(totalFee: 120000));

      // Les reçus passés ne bougent toujours pas
      final reloadedAgainV3 = await paymentRepo.getById(v3.id);
      expect(reloadedAgainV3!.totalFeeAtPayment, 100000);
      expect(reloadedAgainV3.balanceAfter, 40000);
    });

    test('6. Annulation versement : voided_at, void_reason, rejet double annulation, outbox', () async {
      final aId = idGen.generate();
      await apprenticeRepo.save(Apprentice(
        id: aId,
        name: 'Moussa Fofana',
        phone: '94444444',
        startDate: clock.now(),
        totalFee: 60000,
        createdAt: clock.now(),
      ));

      final p = await paymentRepo.addPayment(apprenticeId: aId, amount: 20000, note: 'Avance');
      expect(p.isVoided, isFalse);

      final voidTime = clock.now().add(const Duration(days: 1));
      clock.currentTime = voidTime;

      await paymentRepo.voidPayment(id: p.id, reason: 'Erreur de caisse');

      final voided = await paymentRepo.getById(p.id);
      expect(voided!.isVoided, isTrue);
      expect(voided.voidedAt, voidTime);
      expect(voided.voidReason, 'Erreur de caisse');

      // Rejet de double annulation
      expect(
        () => paymentRepo.voidPayment(id: p.id, reason: 'Autre motif'),
        throwsA(isA<StateError>()),
      );

      // Outbox générée
      final outbox = await (db.select(db.syncOutbox)
            ..where((t) => t.entity.equals('apprentice_payments') & t.entityId.equals(p.id)))
          .get();
      expect(outbox.isNotEmpty, isTrue);

      // Exclu de la somme des versements actifs
      final payments = await paymentRepo.getByApprenticeId(aId);
      final activeSum = payments.where((x) => !x.isVoided).fold(0, (sum, x) => sum + x.amount);
      expect(activeSum, 0);
    });

    test('7. Règle total_fee : refus si inférieur aux versements actifs', () async {
      final aId = idGen.generate();
      await apprenticeRepo.save(Apprentice(
        id: aId,
        name: 'Salif Sanogo',
        phone: '95555555',
        startDate: clock.now(),
        totalFee: 100000,
        createdAt: clock.now(),
      ));

      await paymentRepo.addPayment(apprenticeId: aId, amount: 40000, note: 'P1');
      await paymentRepo.addPayment(apprenticeId: aId, amount: 20000, note: 'P2');
      // Total versé actif = 60 000

      // Tenter de réduire le totalFee à 50 000 FCFA doit lever ArgumentError
      final app = await apprenticeRepo.getById(aId);
      expect(
        () => apprenticeRepo.save(app!.copyWith(totalFee: 50000)),
        throwsA(isA<ArgumentError>()),
      );

      // Réduire à 60 000 FCFA ou plus doit réussir
      await apprenticeRepo.save(app!.copyWith(totalFee: 60000));
      final updated = await apprenticeRepo.getById(aId);
      expect(updated!.totalFee, 60000);
    });

    test('8. Suppression d un apprenti : refusée avec versements actifs, acceptée si tous annulés', () async {
      final aId = idGen.generate();
      await apprenticeRepo.save(Apprentice(
        id: aId,
        name: 'Mariam Koné',
        phone: '96666666',
        startDate: clock.now(),
        totalFee: 80000,
        createdAt: clock.now(),
      ));

      final p = await paymentRepo.addPayment(apprenticeId: aId, amount: 30000, note: 'Versement');

      // Suppression refusée car versement actif
      expect(
        () => apprenticeRepo.delete(aId),
        throwsA(isA<StateError>()),
      );

      // Annuler le versement
      await paymentRepo.voidPayment(id: p.id, reason: 'Désistement');

      // Maintenant la suppression réussit
      await apprenticeRepo.delete(aId);

      final rawApp = await (db.select(db.apprentices)..where((t) => t.id.equals(aId))).getSingle();
      expect(rawApp.deletedAt, isNotNull);

      // Le versement est TOUJOURS présent en base (jamais supprimé physiquement)
      final rawPay = await (db.select(db.apprenticePayments)..where((t) => t.id.equals(p.id))).getSingle();
      expect(rawPay.id, p.id);
      expect(rawPay.voidedAt, isNotNull);
    });

    test('9. Clés étrangères : versement sur apprenti inexistant rejeté', () async {
      expect(
        () => paymentRepo.addPayment(
          apprenticeId: 'inexistant_id',
          amount: 10000,
          note: 'Orphelin',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('10. Dates jour-seul : start_date et next_due font l aller-retour sans décalage', () {
      final localStart = DateTime(2026, 3, 1);
      final localDue = DateTime(2026, 12, 15);

      final normStart = normalizeDate(localStart);
      final normDue = normalizeDate(localDue);

      expect(normStart.year, 2026);
      expect(normStart.month, 3);
      expect(normStart.day, 1);
      expect(normStart.isUtc, isTrue);

      expect(normDue.year, 2026);
      expect(normDue.month, 12);
      expect(normDue.day, 15);
      expect(normDue.isUtc, isTrue);

      final converter = const DateTimeConverter();
      final roundtripStart = converter.fromSql(converter.toSql(normStart));
      final roundtripDue = converter.fromSql(converter.toSql(normDue));

      expect(roundtripStart.year, 2026);
      expect(roundtripStart.month, 3);
      expect(roundtripStart.day, 1);

      expect(roundtripDue.year, 2026);
      expect(roundtripDue.month, 12);
      expect(roundtripDue.day, 15);
    });

    test('11. PERSISTANCE sur base FICHIER temporaire across restarts', () async {
      final tempDir = await Directory.systemTemp.createTemp('angela_apprentice_test_');
      final dbPath = p.join(tempDir.path, 'apprentice_persist.db');

      // Phase 1 : création et versements sur base fichier
      final fileDb1 = db_layer.AppDatabase(NativeDatabase(File(dbPath)));
      final aRepo1 = DriftApprenticeRepository(db: fileDb1, clock: clock, idGenerator: idGen);
      final pRepo1 = DriftApprenticePaymentRepository(db: fileDb1, clock: clock, idGenerator: idGen);

      final aId = 'app_persist_1';
      await aRepo1.save(Apprentice(
        id: aId,
        name: 'Ousmane Traoré',
        phone: '97777777',
        startDate: DateTime.utc(2026, 2, 1),
        totalFee: 200000,
        nextDue: DateTime.utc(2026, 11, 30),
        notes: 'Apprenti persistent',
        createdAt: clock.now(),
      ));

      final pay1 = await pRepo1.addPayment(apprenticeId: aId, amount: 50000, note: 'Tranche initiale');
      expect(pay1.receiptNumber, 1);
      expect(pay1.totalFeeAtPayment, 200000);
      expect(pay1.balanceAfter, 150000);

      await fileDb1.close();

      // Phase 2 : réouverture avec nouvelle instance AppDatabase
      final fileDb2 = db_layer.AppDatabase(NativeDatabase(File(dbPath)));
      final aRepo2 = DriftApprenticeRepository(db: fileDb2, clock: clock, idGenerator: idGen);
      final pRepo2 = DriftApprenticePaymentRepository(db: fileDb2, clock: clock, idGenerator: idGen);

      final reloadedApp = await aRepo2.getById(aId);
      expect(reloadedApp, isNotNull);
      expect(reloadedApp!.name, 'Ousmane Traoré');
      expect(reloadedApp.totalFee, 200000);

      final reloadedPayments = await pRepo2.getByApprenticeId(aId);
      expect(reloadedPayments.length, 1);
      expect(reloadedPayments.first.amount, 50000);
      expect(reloadedPayments.first.receiptNumber, 1);
      expect(reloadedPayments.first.totalFeeAtPayment, 200000);
      expect(reloadedPayments.first.balanceAfter, 150000);

      // Nouveau versement sur la base réouverte : doit avoir le reçu n°2
      final pay2 = await pRepo2.addPayment(apprenticeId: aId, amount: 30000, note: 'Deuxième tranche');
      expect(pay2.receiptNumber, 2);
      expect(pay2.balanceAfter, 120000);

      await fileDb2.close();
      await tempDir.delete(recursive: true);
    });

    test('12. DemoSeeder : seeding apprentis + versements, outbox vierge, compteur calé', () async {
      final seeder = DemoSeeder(db);

      // Release : rien n'est inséré
      final seededRelease = await seeder.seedIfNecessary(isDebug: false);
      expect(seededRelease, isFalse);
      var appCount = await db.apprentices.count().getSingle();
      expect(appCount, 0);

      // Debug : insertion démo
      final seeded = await seeder.seedIfNecessary(isDebug: true);
      expect(seeded, isTrue);

      // Clé dans sync_state
      final syncState = await (db.select(db.syncState)..where((t) => t.key.equals('demo_seeded:apprentices'))).getSingleOrNull();
      expect(syncState, isNotNull);

      // 3 apprentis ('a0', 'a1', 'a2') et 5 versements ('ap0'..'ap4')
      appCount = await db.apprentices.count().getSingle();
      expect(appCount, 3);

      final paymentsCount = await db.apprenticePayments.count().getSingle();
      expect(paymentsCount, 5);

      // Aucune écriture dans sync_outbox
      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox, isEmpty, reason: 'DemoSeeder ne doit jamais écrire dans sync_outbox');

      // Compteur 'apprentices' calé à 5
      final counter = await (db.select(db.receiptCounters)..where((t) => t.counterName.equals('apprentices'))).getSingle();
      expect(counter.lastValue, 5);

      // Idempotence : un deuxième appel ne fait rien
      final reseeded = await seeder.seedIfNecessary(isDebug: true);
      expect(reseeded, isFalse);
    });
  });
}
