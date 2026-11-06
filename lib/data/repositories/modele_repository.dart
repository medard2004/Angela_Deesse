import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';

abstract class ModeleRepository {
  Stream<List<Modele>> watchAll();
  Future<List<Modele>> getAll();
  Future<List<Modele>> getAllIncludingDeleted();
  Future<Modele?> getById(String id, {bool includeDeleted = false});
  Future<void> save(Modele modele);
  Future<void> delete(String id);
}

class DriftModeleRepository implements ModeleRepository {
  DriftModeleRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  Modele _toDomain(db_layer.Modele row) => Modele(
        id: row.id,
        name: row.name,
        description: row.description,
        photo: row.photoPath,
      );

  @override
  Stream<List<Modele>> watchAll() {
    return (db.select(db.modeles)
          ..where((t) => t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Modele>> getAll() async {
    final rows = await (db.select(db.modeles)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Modele>> getAllIncludingDeleted() async {
    final rows = await db.select(db.modeles).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Modele?> getById(String id, {bool includeDeleted = false}) async {
    final row = await (db.select(db.modeles)
          ..where((t) => t.id.equals(id) & (includeDeleted ? const Constant(true) : t.deletedAt.isNull())))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(Modele modele) async {
    final now = clock.now();
    final existing = await (db.select(db.modeles)
          ..where((t) => t.id.equals(modele.id)))
        .getSingleOrNull();

    final createdAt = existing?.createdAt ?? now;
    final updatedAt = now;

    await db.writeWithOutbox(
      entity: 'modeles',
      entityId: modele.id,
      op: 'upsert',
      timestamp: now,
      action: () async {
        await db.into(db.modeles).insertOnConflictUpdate(
              db_layer.ModelesCompanion(
                id: Value(modele.id),
                name: Value(modele.name),
                description: Value(modele.description),
                photoPath: Value(modele.photo),
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
      entity: 'modeles',
      entityId: id,
      op: 'delete',
      timestamp: now,
      action: () async {
        await (db.update(db.modeles)..where((t) => t.id.equals(id))).write(
          db_layer.ModelesCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      },
    );
  }
}
