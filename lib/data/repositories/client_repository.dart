import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';
import '../models.dart';

abstract class ClientRepository {
  Stream<List<Client>> watchAll();
  Future<List<Client>> getAll();
  Future<Client?> getById(String id);
  Future<void> save(Client client);
  Future<void> delete(String id);
}

class DriftClientRepository implements ClientRepository {
  DriftClientRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  Client _toDomain(db_layer.Client row) => Client(
        id: row.id,
        name: row.name,
        phone: row.phone,
        notes: row.notes,
      );

  @override
  Stream<List<Client>> watchAll() {
    return (db.select(db.clients)
          ..where((t) => t.deletedAt.isNull()))
        .watch()
        .map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Client>> getAll() async {
    final rows = await (db.select(db.clients)
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Client?> getById(String id) async {
    final row = await (db.select(db.clients)
          ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(Client client) async {
    final now = clock.now();
    final existing = await (db.select(db.clients)
          ..where((t) => t.id.equals(client.id)))
        .getSingleOrNull();

    final createdAt = existing?.createdAt ?? now;
    final updatedAt = now;

    await db.writeWithOutbox(
      entity: 'clients',
      entityId: client.id,
      op: 'upsert',
      action: () async {
        await db.into(db.clients).insertOnConflictUpdate(
              db_layer.ClientsCompanion(
                id: Value(client.id),
                name: Value(client.name),
                phone: Value(client.phone),
                notes: Value(client.notes),
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

    // En une seule transaction atomique :
    // 1. Suppression logique du client + outbox 'clients'
    // 2. Suppression logique de ses fiches de mesures + outbox 'measurements' pour chaque fiche
    await db.transaction(() async {
      await (db.update(db.clients)..where((t) => t.id.equals(id))).write(
        db_layer.ClientsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final clientOutboxId = idGenerator.generate();
      await db.into(db.syncOutbox).insert(
            db_layer.SyncOutboxCompanion.insert(
              id: clientOutboxId,
              entity: 'clients',
              entityId: id,
              op: 'delete',
              createdAt: now,
            ),
          );

      final clientMeasurements = await (db.select(db.measurements)
            ..where((t) => t.clientId.equals(id) & t.deletedAt.isNull()))
          .get();

      for (final m in clientMeasurements) {
        await (db.update(db.measurements)..where((t) => t.id.equals(m.id))).write(
          db_layer.MeasurementsCompanion(
            deletedAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        final measureOutboxId = idGenerator.generate();
        await db.into(db.syncOutbox).insert(
              db_layer.SyncOutboxCompanion.insert(
                id: measureOutboxId,
                entity: 'measurements',
                entityId: m.id,
                op: 'delete',
                createdAt: now,
              ),
            );
      }
    });
  }
}
