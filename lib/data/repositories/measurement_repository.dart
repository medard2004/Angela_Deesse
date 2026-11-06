import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';

abstract class MeasurementRepository {
  Stream<List<Measurement>> watchAll();
  Stream<List<Measurement>> watchByClient(String clientId);
  Future<List<Measurement>> getAll();
  Future<List<Measurement>> getByClient(String clientId);
  Future<Measurement?> getById(String id);
  Future<void> save(Measurement measurement);
  Future<void> delete(String id);
}

class DriftMeasurementRepository implements MeasurementRepository {
  DriftMeasurementRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  Measurement _toDomain(db_layer.Measurement row) => Measurement(
        id: row.id,
        clientId: row.clientId,
        takenAt: row.takenAt,
        values: row.measures,
        note: row.note,
      );

  @override
  Stream<List<Measurement>> watchAll() {
    return (db.select(db.measurements)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<List<Measurement>> watchByClient(String clientId) {
    return (db.select(db.measurements)
          ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Measurement>> getAll() async {
    final rows = await (db.select(db.measurements)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Measurement>> getByClient(String clientId) async {
    final rows = await (db.select(db.measurements)
          ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Measurement?> getById(String id) async {
    final row = await (db.select(db.measurements)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(Measurement measurement) async {
    final now = clock.now();
    final existing = await (db.select(db.measurements)
          ..where((t) => t.id.equals(measurement.id)))
        .getSingleOrNull();

    final createdAt = existing?.createdAt ?? now;
    final updatedAt = now;

    await db.writeWithOutbox(
      entity: 'measurements',
      entityId: measurement.id,
      op: 'upsert',
      timestamp: now,
      action: () async {
        await db.into(db.measurements).insertOnConflictUpdate(
              db_layer.MeasurementsCompanion(
                id: Value(measurement.id),
                clientId: Value(measurement.clientId),
                takenAt: Value(measurement.takenAt),
                measures: Value(measurement.values),
                note: Value(measurement.note),
                createdAt: Value(createdAt),
                updatedAt: Value(updatedAt),
                deletedAt: const Value(null),
              ),
            );
      },
    );
  }

  @override
  Future<void> delete(String id) async {
    final now = clock.now();
    await db.writeWithOutbox(
      entity: 'measurements',
      entityId: id,
      op: 'delete',
      timestamp: now,
      action: () async {
        await (db.update(db.measurements)..where((t) => t.id.equals(id))).write(
          db_layer.MeasurementsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      },
    );
  }
}
