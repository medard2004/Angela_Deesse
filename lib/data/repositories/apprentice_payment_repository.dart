import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';

abstract class ApprenticePaymentRepository {
  Stream<List<ApprenticePayment>> watchAll();
  Stream<List<ApprenticePayment>> watchByApprenticeId(String apprenticeId);
  Future<List<ApprenticePayment>> getAll();
  Future<ApprenticePayment?> getById(String id);
  Future<List<ApprenticePayment>> getByApprenticeId(String apprenticeId);
  Future<int> getTotalActivePaymentsForApprentice(String apprenticeId);
  Future<ApprenticePayment> addPayment({
    required String apprenticeId,
    required int amount,
    required String note,
    DateTime? paidAt,
  });
  Future<ApprenticePayment> voidPayment({
    required String id,
    required String reason,
  });
}

class DriftApprenticePaymentRepository implements ApprenticePaymentRepository {
  DriftApprenticePaymentRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  ApprenticePayment _mapRow(db_layer.ApprenticePayment row) {
    return ApprenticePayment(
      id: row.id,
      apprenticeId: row.apprenticeId,
      amount: row.amount,
      paidAt: row.paidAt,
      note: row.note,
      receiptNumber: row.receiptNumber,
      totalFeeAtPayment: row.totalFeeAtPayment,
      balanceAfter: row.balanceAfter,
      voidedAt: row.voidedAt,
      voidReason: row.voidReason,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Stream<List<ApprenticePayment>> watchAll() {
    final query = db.select(db.apprenticePayments)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Stream<List<ApprenticePayment>> watchByApprenticeId(String apprenticeId) {
    final query = db.select(db.apprenticePayments)
      ..where((t) => t.apprenticeId.equals(apprenticeId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    return query.watch().map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<List<ApprenticePayment>> getAll() async {
    final query = db.select(db.apprenticePayments)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<ApprenticePayment?> getById(String id) async {
    final row = await (db.select(db.apprenticePayments)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<List<ApprenticePayment>> getByApprenticeId(String apprenticeId) async {
    final query = db.select(db.apprenticePayments)
      ..where((t) => t.apprenticeId.equals(apprenticeId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm.desc(t.paidAt),
        (t) => OrderingTerm.desc(t.receiptNumber),
      ]);
    final rows = await query.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<int> getTotalActivePaymentsForApprentice(String apprenticeId) async {
    final query = db.selectOnly(db.apprenticePayments)
      ..addColumns([db.apprenticePayments.amount.sum()])
      ..where(
        db.apprenticePayments.apprenticeId.equals(apprenticeId) &
            db.apprenticePayments.voidedAt.isNull() &
            db.apprenticePayments.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(db.apprenticePayments.amount.sum()) ?? 0;
  }

  @override
  Future<ApprenticePayment> addPayment({
    required String apprenticeId,
    required int amount,
    required String note,
    DateTime? paidAt,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Le montant du versement doit être strictement positif.');
    }

    final apprentice = await (db.select(db.apprentices)
          ..where((t) => t.id.equals(apprenticeId) & t.deletedAt.isNull()))
        .getSingleOrNull();
    if (apprentice == null) {
      throw StateError('L\'apprenti n\'existe pas ou a été supprimé.');
    }

    final totalActive = await getTotalActivePaymentsForApprentice(apprenticeId);
    final remaining = apprentice.totalFee - totalActive;
    if (amount > remaining) {
      throw ArgumentError('Le montant ($amount FCFA) dépasse le reste à payer ($remaining FCFA).');
    }

    final now = clock.now();
    final paymentId = idGenerator.generate();
    final pDate = paidAt ?? now;

    return await db.transaction(() async {
      final receiptNo = await db.nextReceiptNumber(counterName: 'apprentices');
      final totalFeeAtPayment = apprentice.totalFee;
      final balanceAfter = remaining - amount;

      final companion = db_layer.ApprenticePaymentsCompanion.insert(
        id: paymentId,
        apprenticeId: apprenticeId,
        amount: amount,
        paidAt: pDate,
        receiptNumber: receiptNo,
        totalFeeAtPayment: totalFeeAtPayment,
        balanceAfter: balanceAfter,
        note: Value(note),
        createdAt: now,
        updatedAt: now,
      );

      await db.into(db.apprenticePayments).insert(companion);

      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'apprentice_payments',
              entityId: paymentId,
              op: 'upsert',
              createdAt: now,
            ),
          );

      return ApprenticePayment(
        id: paymentId,
        apprenticeId: apprenticeId,
        amount: amount,
        paidAt: pDate,
        receiptNumber: receiptNo,
        totalFeeAtPayment: totalFeeAtPayment,
        balanceAfter: balanceAfter,
        note: note,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<ApprenticePayment> voidPayment({
    required String id,
    required String reason,
  }) async {
    final payment = await (db.select(db.apprenticePayments)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (payment == null) {
      throw StateError('Le versement n\'existe pas.');
    }

    if (payment.voidedAt != null) {
      throw StateError('Ce versement est déjà annulé.');
    }

    final now = clock.now();

    await db.writeWithOutbox(
      entity: 'apprentice_payments',
      entityId: id,
      op: 'upsert',
      action: () async {
        await (db.update(db.apprenticePayments)..where((t) => t.id.equals(id))).write(
          db_layer.ApprenticePaymentsCompanion(
            voidedAt: Value(now),
            voidReason: Value(reason),
            updatedAt: Value(now),
          ),
        );
      },
    );

    return ApprenticePayment(
      id: payment.id,
      apprenticeId: payment.apprenticeId,
      amount: payment.amount,
      paidAt: payment.paidAt,
      receiptNumber: payment.receiptNumber,
      totalFeeAtPayment: payment.totalFeeAtPayment,
      balanceAfter: payment.balanceAfter,
      note: payment.note,
      voidedAt: now,
      voidReason: reason,
      createdAt: payment.createdAt,
      updatedAt: now,
    );
  }
}

