import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';

import 'package:angela_dress/data/db/app_database.dart';
import 'package:angela_dress/data/db/converters/datetime_converter.dart';
import 'package:angela_dress/data/db/id_generator.dart';

void main() {
  late AppDatabase db;
  late IdGenerator idGen;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    idGen = const UuidV7IdGenerator();
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift In-Memory Database - Schema & Operations', () {
    test('1. Insertion and read across all tables', () async {
      final now = DateTime.utc(2026, 11, 2, 14, 30, 0, 456);

      // 1. Clients
      final clientId = idGen.generate();
      await db.into(db.clients).insert(
            ClientsCompanion.insert(
              id: clientId,
              name: 'Amina Diallo',
              phone: const Value('90000001'),
              notes: const Value('Cliente VIP'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final client = await (db.select(db.clients)..where((t) => t.id.equals(clientId))).getSingle();
      expect(client.name, 'Amina Diallo');
      expect(client.phone, '90000001');
      expect(client.createdAt, now);

      // 2. Measurements (measures column)
      final measurementId = idGen.generate();
      await db.into(db.measurements).insert(
            MeasurementsCompanion.insert(
              id: measurementId,
              clientId: clientId,
              takenAt: now,
              measures: {'epaule': 38, 'poitrine': 92, 'taille': 74},
              note: const Value('Mesures pour robe'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final measurement =
          await (db.select(db.measurements)..where((t) => t.id.equals(measurementId))).getSingle();
      expect(measurement.note, 'Mesures pour robe');
      expect(measurement.measures['poitrine'], 92);

      // 3. Modeles
      final modeleId = idGen.generate();
      await db.into(db.modeles).insert(
            ModelesCompanion.insert(
              id: modeleId,
              name: 'Robe Sirène',
              description: const Value('Robe de soirée élégante'),
              photoPath: const Value('demo:1'),
              photoUploadState: const Value('none'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final modele = await (db.select(db.modeles)..where((t) => t.id.equals(modeleId))).getSingle();
      expect(modele.name, 'Robe Sirène');
      expect(modele.description, 'Robe de soirée élégante');

      // 4. Orders
      final orderId = idGen.generate();
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              id: orderId,
              clientId: clientId,
              title: 'Confection Robe Sirène',
              price: 40000,
              deliveryDate: now.add(const Duration(days: 7)),
              status: const Value('attente'),
              createdAt: now,
              updatedAt: now,
              modeleId: Value(modeleId),
            ),
          );
      final order = await (db.select(db.orders)..where((t) => t.id.equals(orderId))).getSingle();
      expect(order.price, 40000);
      expect(order.clientId, clientId);

      // 5. OrderPhotos
      final photoId = idGen.generate();
      await db.into(db.orderPhotos).insert(
            OrderPhotosCompanion.insert(
              id: photoId,
              orderId: orderId,
              photoPath: 'demo:3',
              photoUploadState: const Value('none'),
              position: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final photo = await (db.select(db.orderPhotos)..where((t) => t.id.equals(photoId))).getSingle();
      expect(photo.photoPath, 'demo:3');
      expect(photo.position, 1);

      // 6. ClientPayments
      final paymentId = idGen.generate();
      final receiptNumber = await db.nextReceiptNumber(counterName: 'clients');
      await db.into(db.clientPayments).insert(
            ClientPaymentsCompanion.insert(
              id: paymentId,
              orderId: orderId,
              amount: 25000,
              paidAt: now,
              receiptNumber: receiptNumber,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final payment =
          await (db.select(db.clientPayments)..where((t) => t.id.equals(paymentId))).getSingle();
      expect(payment.amount, 25000);
      expect(payment.receiptNumber, 1);

      // 7. Apprentices
      final apprenticeId = idGen.generate();
      await db.into(db.apprentices).insert(
            ApprenticesCompanion.insert(
              id: apprenticeId,
              name: 'Koffi Mensah',
              phone: const Value('91000001'),
              startDate: now,
              totalFee: 150000,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final apprentice =
          await (db.select(db.apprentices)..where((t) => t.id.equals(apprenticeId))).getSingle();
      expect(apprentice.name, 'Koffi Mensah');
      expect(apprentice.totalFee, 150000);

      // 8. ApprenticePayments
      final apprenticePaymentId = idGen.generate();
      final appReceiptNumber = await db.nextReceiptNumber(counterName: 'apprentices');
      await db.into(db.apprenticePayments).insert(
            ApprenticePaymentsCompanion.insert(
              id: apprenticePaymentId,
              apprenticeId: apprenticeId,
              amount: 50000,
              paidAt: now,
              receiptNumber: appReceiptNumber,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final appPayment = await (db.select(db.apprenticePayments)
            ..where((t) => t.id.equals(apprenticePaymentId)))
          .getSingle();
      expect(appPayment.amount, 50000);
      expect(appPayment.receiptNumber, 1);

      // 9. Realisations
      final realisationId = idGen.generate();
      await db.into(db.realisations).insert(
            RealisationsCompanion.insert(
              id: realisationId,
              category: const Value('Robes'),
              caption: const Value('Ensemble Kente Gala'),
              photoPath: 'demo:2',
              createdAt: now,
              updatedAt: now,
              clientId: Value(clientId),
            ),
          );
      final real =
          await (db.select(db.realisations)..where((t) => t.id.equals(realisationId))).getSingle();
      expect(real.caption, 'Ensemble Kente Gala');

      // 10. Settings (id == key)
      const settingKey = 'atelier_name';
      await db.into(db.settings).insert(
            SettingsCompanion.insert(
              id: settingKey,
              key: settingKey,
              value: 'Angela Couture Lomé',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final setting =
          await (db.select(db.settings)..where((t) => t.key.equals(settingKey))).getSingle();
      expect(setting.id, settingKey);
      expect(setting.value, 'Angela Couture Lomé');

      // 11. ReceiptCounters
      final counter = await (db.select(db.receiptCounters)
            ..where((t) => t.counterName.equals('clients')))
          .getSingle();
      expect(counter.lastValue, 1);

      // 12. SyncOutbox
      final outboxId = idGen.generate();
      await db.into(db.syncOutbox).insert(
            SyncOutboxCompanion.insert(
              id: outboxId,
              entity: 'clients',
              entityId: clientId,
              op: 'upsert',
              createdAt: now,
            ),
          );
      final outboxRow =
          await (db.select(db.syncOutbox)..where((t) => t.id.equals(outboxId))).getSingle();
      expect(outboxRow.entity, 'clients');
      expect(outboxRow.attempts, const Value(0).value);

      // 13. SyncState
      await db.into(db.syncState).insert(
            SyncStateCompanion.insert(
              key: 'pull_cursor',
              value: 'cursor-123',
              updatedAt: now,
            ),
          );
      final syncStateRow =
          await (db.select(db.syncState)..where((t) => t.key.equals('pull_cursor'))).getSingle();
      expect(syncStateRow.value, 'cursor-123');
    });

    test('2. Foreign key enforcement is active', () async {
      final now = DateTime.utc(2026, 11, 2, 12, 0, 0);
      final fakeClientId = idGen.generate();

      expect(
        () async => db.into(db.orders).insert(
              OrdersCompanion.insert(
                id: idGen.generate(),
                clientId: fakeClientId,
                title: 'Commande test FK',
                price: 20000,
                deliveryDate: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('3. Uniqueness of receipt_number on ClientPayments and ApprenticePayments', () async {
      final now = DateTime.utc(2026, 11, 2, 12, 0, 0);
      final clientId = idGen.generate();
      await db.into(db.clients).insert(
            ClientsCompanion.insert(
              id: clientId,
              name: 'Client Test Unicité',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final orderId = idGen.generate();
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              id: orderId,
              clientId: clientId,
              title: 'Commande Test',
              price: 50000,
              deliveryDate: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      const duplicateReceipt = 1001;

      await db.into(db.clientPayments).insert(
            ClientPaymentsCompanion.insert(
              id: idGen.generate(),
              orderId: orderId,
              amount: 10000,
              paidAt: now,
              receiptNumber: duplicateReceipt,
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(
        () async => db.into(db.clientPayments).insert(
              ClientPaymentsCompanion.insert(
                id: idGen.generate(),
                orderId: orderId,
                amount: 15000,
                paidAt: now,
                receiptNumber: duplicateReceipt,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      final apprenticeId = idGen.generate();
      await db.into(db.apprentices).insert(
            ApprenticesCompanion.insert(
              id: apprenticeId,
              name: 'Apprenti Test Unicité',
              startDate: now,
              totalFee: 100000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      const appDuplicateReceipt = 2001;
      await db.into(db.apprenticePayments).insert(
            ApprenticePaymentsCompanion.insert(
              id: idGen.generate(),
              apprenticeId: apprenticeId,
              amount: 30000,
              paidAt: now,
              receiptNumber: appDuplicateReceipt,
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(
        () async => db.into(db.apprenticePayments).insert(
              ApprenticePaymentsCompanion.insert(
                id: idGen.generate(),
                apprenticeId: apprenticeId,
                amount: 20000,
                paidAt: now,
                receiptNumber: appDuplicateReceipt,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('4. Atomicity of writeWithOutbox with rollback on failure', () async {
      final now = DateTime.utc(2026, 11, 2, 12, 0, 0);
      final clientId = idGen.generate();

      await db.writeWithOutbox(
        entity: 'clients',
        entityId: clientId,
        op: 'upsert',
        action: () async {
          await db.into(db.clients).insert(
                ClientsCompanion.insert(
                  id: clientId,
                  name: 'Client Atomique',
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        },
      );

      final client = await (db.select(db.clients)..where((t) => t.id.equals(clientId))).getSingleOrNull();
      expect(client, isNotNull);

      final outboxEntries = await (db.select(db.syncOutbox)
            ..where((t) => t.entityId.equals(clientId)))
          .get();
      expect(outboxEntries.length, 1);
      expect(outboxEntries.first.op, 'upsert');

      final failClientId = idGen.generate();
      expect(
        () async => db.writeWithOutbox(
          entity: 'clients',
          entityId: failClientId,
          op: 'upsert',
          action: () async {
            await db.into(db.clients).insert(
                  ClientsCompanion.insert(
                    id: failClientId,
                    name: 'Client Doomed',
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
            throw Exception('Simulation erreur transactionnelle');
          },
        ),
        throwsA(isA<Exception>()),
      );

      final doomedClient =
          await (db.select(db.clients)..where((t) => t.id.equals(failClientId))).getSingleOrNull();
      expect(doomedClient, isNull);

      final doomedOutbox = await (db.select(db.syncOutbox)
            ..where((t) => t.entityId.equals(failClientId)))
          .get();
      expect(doomedOutbox, isEmpty);
    });

    test('5. Voided payment is excluded from remaining balance / sum', () async {
      final now = DateTime.utc(2026, 11, 2, 12, 0, 0);
      final clientId = idGen.generate();
      await db.into(db.clients).insert(
            ClientsCompanion.insert(
              id: clientId,
              name: 'Client Solde',
              createdAt: now,
              updatedAt: now,
            ),
          );

      const totalPrice = 50000;
      final orderId = idGen.generate();
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              id: orderId,
              clientId: clientId,
              title: 'Commande avec annulation',
              price: totalPrice,
              deliveryDate: now,
              status: const Value('cours'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.clientPayments).insert(
            ClientPaymentsCompanion.insert(
              id: idGen.generate(),
              orderId: orderId,
              amount: 20000,
              paidAt: now,
              receiptNumber: 101,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final voidedPaymentId = idGen.generate();
      await db.into(db.clientPayments).insert(
            ClientPaymentsCompanion.insert(
              id: voidedPaymentId,
              orderId: orderId,
              amount: 10000,
              paidAt: now,
              receiptNumber: 102,
              createdAt: now,
              updatedAt: now,
              voidedAt: Value(now),
              voidReason: const Value('Erreur de saisie montant'),
            ),
          );

      await db.into(db.clientPayments).insert(
            ClientPaymentsCompanion.insert(
              id: idGen.generate(),
              orderId: orderId,
              amount: 5000,
              paidAt: now,
              receiptNumber: 103,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final activeTotal = await db.activePaymentsTotalForOrder(orderId);
      expect(activeTotal, 25000);

      final remaining = totalPrice - activeTotal;
      expect(remaining, 25000);

      final apprenticeId = idGen.generate();
      const totalFee = 120000;
      await db.into(db.apprentices).insert(
            ApprenticesCompanion.insert(
              id: apprenticeId,
              name: 'Apprenti Solde',
              startDate: now,
              totalFee: totalFee,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.apprenticePayments).insert(
            ApprenticePaymentsCompanion.insert(
              id: idGen.generate(),
              apprenticeId: apprenticeId,
              amount: 40000,
              paidAt: now,
              receiptNumber: 201,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.apprenticePayments).insert(
            ApprenticePaymentsCompanion.insert(
              id: idGen.generate(),
              apprenticeId: apprenticeId,
              amount: 15000,
              paidAt: now,
              receiptNumber: 202,
              createdAt: now,
              updatedAt: now,
              voidedAt: Value(now),
              voidReason: const Value('Doublon versement'),
            ),
          );

      final activeAppTotal = await db.activePaymentsTotalForApprentice(apprenticeId);
      expect(activeAppTotal, 40000);
      expect(totalFee - activeAppTotal, 80000);
    });

    test('6. DateTimeConverter preserves exact UTC milliseconds', () {
      const converter = DateTimeConverter();
      const nullableConverter = NullableDateTimeConverter();

      final original = DateTime.utc(2026, 11, 2, 23, 45, 12, 789);
      final sqlInt = converter.toSql(original);
      expect(sqlInt, original.millisecondsSinceEpoch);

      final restored = converter.fromSql(sqlInt);
      expect(restored.isUtc, isTrue);
      expect(restored.millisecond, 789);
      expect(restored, original);

      final localDate = DateTime(2026, 11, 2, 10, 0, 0, 123);
      final convertedSql = converter.toSql(localDate);
      expect(convertedSql, localDate.toUtc().millisecondsSinceEpoch);
      final fromConverted = converter.fromSql(convertedSql);
      expect(fromConverted.isUtc, isTrue);
      expect(fromConverted.millisecond, 123);

      expect(nullableConverter.toSql(null), null);
      expect(nullableConverter.fromSql(null), null);
      expect(nullableConverter.toSql(original), original.millisecondsSinceEpoch);
      expect(nullableConverter.fromSql(sqlInt), original);
    });

    test('7. AppDatabase.reconcileReceiptCounters adjusts last_value to max receipt number', () async {
      final now = DateTime.utc(2026, 11, 2, 12, 0, 0);

      // Client & order setup
      final clientId = idGen.generate();
      await db.into(db.clients).insert(
            ClientsCompanion.insert(
              id: clientId,
              name: 'Client Reconcile',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final orderId = idGen.generate();
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              id: orderId,
              clientId: clientId,
              title: 'Order Reconcile',
              price: 100000,
              deliveryDate: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Start counter at 5
      await db.into(db.receiptCounters).insert(
            ReceiptCountersCompanion.insert(
              counterName: 'clients',
              lastValue: const Value(5),
              updatedAt: now,
            ),
          );

      // Simulate restored payment with receipt_number 500 (even if voided!)
      await db.into(db.clientPayments).insert(
            ClientPaymentsCompanion.insert(
              id: idGen.generate(),
              orderId: orderId,
              amount: 15000,
              paidAt: now,
              receiptNumber: 500,
              voidedAt: Value(now),
              voidReason: const Value('Annulé lors de la restauration'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Same for apprentice with receipt_number 300
      final apprenticeId = idGen.generate();
      await db.into(db.apprentices).insert(
            ApprenticesCompanion.insert(
              id: apprenticeId,
              name: 'Apprenti Reconcile',
              startDate: now,
              totalFee: 50000,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.apprenticePayments).insert(
            ApprenticePaymentsCompanion.insert(
              id: idGen.generate(),
              apprenticeId: apprenticeId,
              amount: 10000,
              paidAt: now,
              receiptNumber: 300,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Call reconcile
      await db.reconcileReceiptCounters();

      // Verify that next client receipt is 501, not 6
      final nextClientReceipt = await db.nextReceiptNumber(counterName: 'clients');
      expect(nextClientReceipt, 501);

      // Verify that next apprentice receipt is 301, not 1
      final nextAppReceipt = await db.nextReceiptNumber(counterName: 'apprentices');
      expect(nextAppReceipt, 301);
    });

    test('8. CHECK constraints enforce positive values', () async {
      final now = DateTime.utc(2026, 11, 2, 12, 0, 0);
      final clientId = idGen.generate();
      await db.into(db.clients).insert(
            ClientsCompanion.insert(
              id: clientId,
              name: 'Client Check',
              createdAt: now,
              updatedAt: now,
            ),
          );
      final orderId = idGen.generate();
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              id: orderId,
              clientId: clientId,
              title: 'Order Check',
              price: 10000,
              deliveryDate: now,
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 1. client_payments.amount <= 0 must fail
      expect(
        () async => db.into(db.clientPayments).insert(
              ClientPaymentsCompanion.insert(
                id: idGen.generate(),
                orderId: orderId,
                amount: 0,
                paidAt: now,
                receiptNumber: 9991,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // 2. apprentice_payments.amount <= 0 must fail
      final apprenticeId = idGen.generate();
      await db.into(db.apprentices).insert(
            ApprenticesCompanion.insert(
              id: apprenticeId,
              name: 'Apprenti Check',
              startDate: now,
              totalFee: 10000,
              createdAt: now,
              updatedAt: now,
            ),
          );

      expect(
        () async => db.into(db.apprenticePayments).insert(
              ApprenticePaymentsCompanion.insert(
                id: idGen.generate(),
                apprenticeId: apprenticeId,
                amount: -500,
                paidAt: now,
                receiptNumber: 9992,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // 3. orders.price < 0 must fail
      expect(
        () async => db.into(db.orders).insert(
              OrdersCompanion.insert(
                id: idGen.generate(),
                clientId: clientId,
                title: 'Order Negatif',
                price: -100,
                deliveryDate: now,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );

      // 4. apprentices.total_fee < 0 must fail
      expect(
        () async => db.into(db.apprentices).insert(
              ApprenticesCompanion.insert(
                id: idGen.generate(),
                name: 'Apprenti Negatif',
                startDate: now,
                totalFee: -10,
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
