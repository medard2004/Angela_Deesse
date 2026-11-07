import 'dart:convert';
import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';
import '../db/id_generator.dart';

/// Repository pour le journal local des notifications et alarmes (Table `notification_log`).
///
/// Invariants stricts :
/// - 100 % LOCAL : aucune écriture dans `sync_outbox`.
/// - Insertion idempotente sur `source_event_id`.
/// - Purge automatique physique (> 30 jours).
abstract class NotificationLogRepository {
  Stream<List<db_layer.NotificationLog>> watchHistory({int limit = 50});
  Future<List<db_layer.NotificationLog>> getHistory({int limit = 50, DateTime? since});
  Future<List<db_layer.NotificationLog>> getActiveAlerts();
  Future<db_layer.NotificationLog?> getById(String id);
  Future<db_layer.NotificationLog?> getBySourceEventId(String sourceEventId);
  Future<db_layer.NotificationLog> logEvent({
    required String channel,
    required String category,
    required String title,
    required String body,
    int itemCount = 1,
    required List<String> alertKeys,
    required DateTime scheduledAt,
    DateTime? firedAt,
    DateTime? endedAt,
    required String outcome,
    int snoozeCount = 0,
    DateTime? seenAt,
    String? sourceEventId,
  });
  Future<void> updateOutcome(
    String id, {
    required String outcome,
    DateTime? endedAt,
    int? snoozeCount,
  });
  Future<void> markSeen(String id, {DateTime? seenAt});
  Future<void> markAllSeen({DateTime? seenAt});
  Future<int> purgeOlderThan([Duration maxAge = const Duration(days: 30)]);
}

class DriftNotificationLogRepository implements NotificationLogRepository {
  DriftNotificationLogRepository({
    required this.db,
    this.clock = const SystemClock(),
    this.idGenerator = const UuidV7IdGenerator(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;

  @override
  Stream<List<db_layer.NotificationLog>> watchHistory({int limit = 50}) {
    return (db.select(db.notificationLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)])
          ..limit(limit))
        .watch();
  }

  @override
  Future<List<db_layer.NotificationLog>> getHistory({int limit = 50, DateTime? since}) async {
    final query = db.select(db.notificationLogs)
      ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)])
      ..limit(limit);

    if (since != null) {
      query.where((t) => t.scheduledAt.isBiggerOrEqualValue(since.millisecondsSinceEpoch));
    }

    return await query.get();
  }

  @override
  Future<List<db_layer.NotificationLog>> getActiveAlerts() async {
    return await (db.select(db.notificationLogs)
          ..where((t) => t.outcome.equals('missed') & t.seenAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.scheduledAt)]))
        .get();
  }

  @override
  Future<db_layer.NotificationLog?> getById(String id) async {
    return await (db.select(db.notificationLogs)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  @override
  Future<db_layer.NotificationLog?> getBySourceEventId(String sourceEventId) async {
    return await (db.select(db.notificationLogs)..where((t) => t.sourceEventId.equals(sourceEventId)))
        .getSingleOrNull();
  }

  @override
  Future<db_layer.NotificationLog> logEvent({
    required String channel,
    required String category,
    required String title,
    required String body,
    int itemCount = 1,
    required List<String> alertKeys,
    required DateTime scheduledAt,
    DateTime? firedAt,
    DateTime? endedAt,
    required String outcome,
    int snoozeCount = 0,
    DateTime? seenAt,
    String? sourceEventId,
  }) async {
    // Idempotence : si un événement avec ce sourceEventId existe déjà, le retourner
    if (sourceEventId != null && sourceEventId.isNotEmpty) {
      final existing = await getBySourceEventId(sourceEventId);
      if (existing != null) {
        return existing;
      }
    }

    final id = idGenerator.generate();
    final now = clock.now().toUtc();
    final keysStr = jsonEncode(alertKeys);

    final companion = db_layer.NotificationLogsCompanion.insert(
      id: id,
      channel: channel,
      category: category,
      title: title,
      body: body,
      itemCount: Value(itemCount),
      alertKeys: keysStr,
      scheduledAt: scheduledAt,
      firedAt: Value(firedAt),
      endedAt: Value(endedAt),
      outcome: outcome,
      snoozeCount: Value(snoozeCount),
      seenAt: Value(seenAt),
      sourceEventId: Value(sourceEventId),
      createdAt: now,
      updatedAt: now,
    );

    await db.into(db.notificationLogs).insert(companion);
    return (await getById(id))!;
  }

  @override
  Future<void> updateOutcome(
    String id, {
    required String outcome,
    DateTime? endedAt,
    int? snoozeCount,
  }) async {
    final now = clock.now().toUtc();
    final companion = db_layer.NotificationLogsCompanion(
      outcome: Value(outcome),
      updatedAt: Value(now),
      endedAt: endedAt != null ? Value(endedAt) : const Value.absent(),
      snoozeCount: snoozeCount != null ? Value(snoozeCount) : const Value.absent(),
    );

    await (db.update(db.notificationLogs)..where((t) => t.id.equals(id))).write(companion);
  }

  @override
  Future<void> markSeen(String id, {DateTime? seenAt}) async {
    final now = clock.now().toUtc();
    final effectiveSeenAt = seenAt ?? now;
    await (db.update(db.notificationLogs)..where((t) => t.id.equals(id))).write(
      db_layer.NotificationLogsCompanion(
        seenAt: Value(effectiveSeenAt),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> markAllSeen({DateTime? seenAt}) async {
    final now = clock.now().toUtc();
    final effectiveSeenAt = seenAt ?? now;
    await (db.update(db.notificationLogs)..where((t) => t.seenAt.isNull())).write(
      db_layer.NotificationLogsCompanion(
        seenAt: Value(effectiveSeenAt),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<int> purgeOlderThan([Duration maxAge = const Duration(days: 30)]) async {
    final cutoff = clock.now().toUtc().subtract(maxAge);
    // Suppression physique (pas de soft delete car table 100% locale hors sync)
    return await (db.delete(db.notificationLogs)
          ..where((t) => t.createdAt.isSmallerThanValue(cutoff.millisecondsSinceEpoch)))
        .go();
  }
}
