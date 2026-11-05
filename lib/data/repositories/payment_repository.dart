import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';

abstract class PaymentRepository {
  Stream<List<ClientPayment>> watchAll();
  Stream<List<ClientPayment>> watchByOrderId(String orderId);
  Future<List<ClientPayment>> getAll();
  Future<ClientPayment?> getById(String id);
  Future<List<ClientPayment>> getByOrderId(String orderId);
  Future<int> getTotalActivePaymentsForOrder(String orderId);
  Future<ClientPayment> addPayment({
    required String orderId,
    required int amount,
    required String note,
    DateTime? paidAt,
  });
  Future<ClientPayment> voidPayment({
    required String id,
    required String reason,
  });
}

class DriftPaymentRepository implements PaymentRepository {
  DriftPaymentRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  ClientPayment _mapRow(db_layer.ClientPayment row) {
    return ClientPayment(
      id: row.id,
      orderId: row.orderId,
      amount: row.amount,
      paidAt: row.paidAt,
      note: row.note,
      receiptNumber: row.receiptNumber,
      orderPriceAtPayment: row.orderPriceAtPayment,
      balanceAfter: row.balanceAfter,
      voidedAt: row.voidedAt,
      voidReason: row.voidReason,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Stream<List<ClientPayment>> watchAll() {
    final query = db.select(db.clientPayments)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Stream<List<ClientPayment>> watchByOrderId(String orderId) {
    final query = db.select(db.clientPayments)
      ..where((t) => t.orderId.equals(orderId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<List<ClientPayment>> getAll() async {
    final query = db.select(db.clientPayments)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<ClientPayment?> getById(String id) async {
    final row = await (db.select(db.clientPayments)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<List<ClientPayment>> getByOrderId(String orderId) async {
    final query = db.select(db.clientPayments)
      ..where((t) => t.orderId.equals(orderId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<int> getTotalActivePaymentsForOrder(String orderId) async {
    return db.getTotalActivePaymentsForOrder(orderId);
  }

  @override
  Future<ClientPayment> addPayment({
    required String orderId,
    required int amount,
    required String note,
    DateTime? paidAt,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Le montant du versement doit être strictement positif.');
    }

    final order = await (db.select(db.orders)..where((t) => t.id.equals(orderId) & t.deletedAt.isNull())).getSingleOrNull();
    if (order == null) {
      throw StateError('La commande n\'existe pas ou a été supprimée.');
    }

    final totalActive = await getTotalActivePaymentsForOrder(orderId);
    final remaining = order.price - totalActive;
    if (amount > remaining) {
      throw ArgumentError('Le montant ($amount FCFA) dépasse le reliquat restant ($remaining FCFA).');
    }

    final now = clock.now();
    final paymentId = idGenerator.generate();
    final pDate = paidAt ?? now;

    return await db.transaction(() async {
      final receiptNo = await db.nextReceiptNumber(counterName: 'clients');
      final orderPriceAtPayment = order.price;
      final balanceAfter = remaining - amount;

      final companion = db_layer.ClientPaymentsCompanion.insert(
        id: paymentId,
        orderId: orderId,
        amount: amount,
        paidAt: pDate,
        receiptNumber: receiptNo,
        orderPriceAtPayment: orderPriceAtPayment,
        balanceAfter: balanceAfter,
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      );

      await db.into(db.clientPayments).insert(companion);

      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'client_payments',
              entityId: paymentId,
              op: 'upsert',
              createdAt: now,
            ),
          );

      return ClientPayment(
        id: paymentId,
        orderId: orderId,
        amount: amount,
        paidAt: pDate,
        receiptNumber: receiptNo,
        orderPriceAtPayment: orderPriceAtPayment,
        balanceAfter: balanceAfter,
        note: note,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<ClientPayment> voidPayment({
    required String id,
    required String reason,
  }) async {
    final existing = await (db.select(db.clientPayments)..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
    if (existing == null) {
      throw StateError('Versement introuvable.');
    }
    if (existing.voidedAt != null) {
      throw StateError('Ce versement est déjà annulé.');
    }

    final now = clock.now();

    return await db.transaction(() async {
      await (db.update(db.clientPayments)..where((t) => t.id.equals(id))).write(
        db_layer.ClientPaymentsCompanion(
          voidedAt: Value(now),
          voidReason: Value(reason),
          updatedAt: Value(now),
        ),
      );

      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'client_payments',
              entityId: id,
              op: 'upsert',
              createdAt: now,
            ),
          );

      final updated = await (db.select(db.clientPayments)..where((t) => t.id.equals(id))).getSingle();
      return _mapRow(updated);
    });
  }
}

