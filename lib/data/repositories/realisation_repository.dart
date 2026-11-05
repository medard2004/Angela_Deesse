import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';

abstract class RealisationRepository {
  Stream<List<Realisation>> watchAll();
  Stream<List<Realisation>> watchByCategory(String category);
  Stream<List<Realisation>> watchByClient(String clientId);
  Future<List<Realisation>> getAll();
  Future<List<Realisation>> getByCategory(String category);
  Future<List<Realisation>> getByClient(String clientId);
  Future<Realisation?> getById(String id, {bool includeDeleted = false});
  Future<void> save(Realisation realisation);
  Future<void> delete(String id);
}

class DriftRealisationRepository implements RealisationRepository {
  DriftRealisationRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  Realisation _toDomain(db_layer.Realisation row) => Realisation(
        id: row.id,
        photo: row.photoPath,
        category: row.category,
        clientId: row.clientId,
        caption: row.caption,
        createdAt: row.createdAt,
      );

  @override
  Stream<List<Realisation>> watchAll() {
    return (db.select(db.realisations)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<List<Realisation>> watchByCategory(String category) {
    return (db.select(db.realisations)
          ..where((t) => t.category.equals(category) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Stream<List<Realisation>> watchByClient(String clientId) {
    return (db.select(db.realisations)
          ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Realisation>> getAll() async {
    final rows = await (db.select(db.realisations)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Realisation>> getByCategory(String category) async {
    final rows = await (db.select(db.realisations)
          ..where((t) => t.category.equals(category) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Realisation>> getByClient(String clientId) async {
    final rows = await (db.select(db.realisations)
          ..where((t) => t.clientId.equals(clientId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Realisation?> getById(String id, {bool includeDeleted = false}) async {
    final row = await (db.select(db.realisations)
          ..where((t) => t.id.equals(id) & (includeDeleted ? const Constant(true) : t.deletedAt.isNull())))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(Realisation realisation) async {
    final now = clock.now();
    final existing = await (db.select(db.realisations)
          ..where((t) => t.id.equals(realisation.id)))
        .getSingleOrNull();

    final createdAt = existing?.createdAt ?? realisation.createdAt;
    final updatedAt = now;

    await db.writeWithOutbox(
      entity: 'realisations',
      entityId: realisation.id,
      op: 'upsert',
      action: () async {
        await db.into(db.realisations).insertOnConflictUpdate(
              db_layer.RealisationsCompanion(
                id: Value(realisation.id),
                category: Value(realisation.category),
                clientId: Value(realisation.clientId),
                caption: Value(realisation.caption),
                photoPath: Value(realisation.photo),
                photoUploadState: const Value('none'),
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
      entity: 'realisations',
      entityId: id,
      op: 'delete',
      action: () async {
        await (db.update(db.realisations)..where((t) => t.id.equals(id))).write(
          db_layer.RealisationsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      },
    );
  }
}
