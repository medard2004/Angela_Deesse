import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';

DateTime normalizeDate(DateTime d) => DateTime.utc(d.year, d.month, d.day);

abstract class ApprenticeRepository {
  Stream<List<Apprentice>> watchAll();
  Future<List<Apprentice>> getAll();
  Future<Apprentice?> getById(String id);
  Future<void> save(Apprentice apprentice);
  Future<ApprenticePayment> createWithDeposit({
    required Apprentice apprentice,
    required int depositAmount,
    String depositNote = 'Acompte inscription',
    DateTime? paidAt,
  });
  Future<void> delete(String id);
  Future<bool> hasActivePaymentsForApprentice(String apprenticeId);
}

class DriftApprenticeRepository implements ApprenticeRepository {
  DriftApprenticeRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  Apprentice _toDomain(db_layer.Apprentice row) => Apprentice(
        id: row.id,
        name: row.name,
        phone: row.phone,
        startDate: row.startDate,
        totalFee: row.totalFee,
        nextDue: row.nextDue,
        notes: row.notes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  @override
  Stream<List<Apprentice>> watchAll() {
    return (db.select(db.apprentices)
          ..where((t) => t.deletedAt.isNull()))
        .watch()
        .map((rows) {
      final list = rows.map(_toDomain).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  @override
  Future<List<Apprentice>> getAll() async {
    final rows = await (db.select(db.apprentices)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    final list = rows.map(_toDomain).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Future<Apprentice?> getById(String id) async {
    final row = await (db.select(db.apprentices)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<bool> hasActivePaymentsForApprentice(String apprenticeId) async {
    final query = db.selectOnly(db.apprenticePayments)
      ..addColumns([db.apprenticePayments.id.count()])
      ..where(
        db.apprenticePayments.apprenticeId.equals(apprenticeId) &
            db.apprenticePayments.voidedAt.isNull() &
            db.apprenticePayments.deletedAt.isNull(),
      );
    final count = await query.map((row) => row.read(db.apprenticePayments.id.count())).getSingle();
    return (count ?? 0) > 0;
  }

  @override
  Future<void> save(Apprentice apprentice) async {
    final now = clock.now();
    final existing = await (db.select(db.apprentices)
          ..where((t) => t.id.equals(apprentice.id)))
        .getSingleOrNull();

    // Règle 3: total_fee ne peut pas être fixé en dessous du total versé non annulé
    if (existing != null) {
      final query = db.selectOnly(db.apprenticePayments)
        ..addColumns([db.apprenticePayments.amount.sum()])
        ..where(
          db.apprenticePayments.apprenticeId.equals(apprentice.id) &
              db.apprenticePayments.voidedAt.isNull() &
              db.apprenticePayments.deletedAt.isNull(),
        );
      final activeSum = await query.map((row) => row.read(db.apprenticePayments.amount.sum())).getSingle() ?? 0;
      if (apprentice.totalFee < activeSum) {
        throw ArgumentError(
          'Le total de formation (${apprentice.totalFee} FCFA) ne peut pas être inférieur aux versements actifs ($activeSum FCFA).',
        );
      }
    }

    final createdAt = existing?.createdAt ?? apprentice.createdAt;
    final updatedAt = now;
    final normStartDate = normalizeDate(apprentice.startDate);
    final normNextDue = apprentice.nextDue != null ? normalizeDate(apprentice.nextDue!) : null;

    await db.writeWithOutbox(
      entity: 'apprentices',
      entityId: apprentice.id,
      op: 'upsert',
      timestamp: now,
      action: () async {
        await db.into(db.apprentices).insertOnConflictUpdate(
              db_layer.ApprenticesCompanion(
                id: Value(apprentice.id),
                name: Value(apprentice.name),
                phone: Value(apprentice.phone),
                startDate: Value(normStartDate),
                totalFee: Value(apprentice.totalFee),
                nextDue: Value(normNextDue),
                notes: Value(apprentice.notes),
                createdAt: Value(createdAt),
                updatedAt: Value(updatedAt),
                deletedAt: const Value(null),
              ),
            );
      },
    );
  }

  @override
  Future<ApprenticePayment> createWithDeposit({
    required Apprentice apprentice,
    required int depositAmount,
    String depositNote = 'Acompte inscription',
    DateTime? paidAt,
  }) async {
    if (depositAmount <= 0) {
      throw ArgumentError('Le montant du versement doit être strictement positif.');
    }
    if (depositAmount > apprentice.totalFee) {
      throw ArgumentError(
        'Le montant du versement ($depositAmount FCFA) dépasse les frais de formation (${apprentice.totalFee} FCFA).',
      );
    }

    final now = clock.now();
    final paymentDate = paidAt ?? now;
    final paymentId = idGenerator.generate();
    final normStartDate = normalizeDate(apprentice.startDate);
    final normNextDue = apprentice.nextDue != null ? normalizeDate(apprentice.nextDue!) : null;

    return db.transaction(() async {
      // 1. Insertion de l'apprenti
      await db.into(db.apprentices).insert(
            db_layer.ApprenticesCompanion.insert(
              id: apprentice.id,
              name: apprentice.name,
              phone: Value(apprentice.phone),
              startDate: normStartDate,
              totalFee: apprentice.totalFee,
              nextDue: Value(normNextDue),
              notes: Value(apprentice.notes),
              createdAt: now,
              updatedAt: now,
            ),
          );

      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: idGenerator.generate(),
              entity: 'apprentices',
              entityId: apprentice.id,
              op: 'upsert',
              createdAt: now,
            ),
          );

      // 2. Numéro de reçu séquentiel
      final receiptNo = await db.nextReceiptNumber(counterName: 'apprentices');

      // 3. Insertion du versement
      final balanceAfter = apprentice.totalFee - depositAmount;
      await db.into(db.apprenticePayments).insert(
            db_layer.ApprenticePaymentsCompanion.insert(
              id: paymentId,
              apprenticeId: apprentice.id,
              amount: depositAmount,
              paidAt: paymentDate,
              note: Value(depositNote),
              receiptNumber: receiptNo,
              totalFeeAtPayment: apprentice.totalFee,
              balanceAfter: balanceAfter,
              createdAt: now,
              updatedAt: now,
            ),
          );

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
        apprenticeId: apprentice.id,
        amount: depositAmount,
        paidAt: paymentDate,
        note: depositNote,
        receiptNumber: receiptNo,
        totalFeeAtPayment: apprentice.totalFee,
        balanceAfter: balanceAfter,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    final hasActive = await hasActivePaymentsForApprentice(id);
    if (hasActive) {
      throw StateError('Impossible de supprimer un apprenti avec des versements actifs.');
    }

    final now = clock.now();
    await db.writeWithOutbox(
      entity: 'apprentices',
      entityId: id,
      op: 'delete',
      timestamp: now,
      action: () async {
        await (db.update(db.apprentices)..where((t) => t.id.equals(id))).write(
          db_layer.ApprenticesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      },
    );
  }
}
