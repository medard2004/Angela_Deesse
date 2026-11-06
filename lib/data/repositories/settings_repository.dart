import 'package:drift/drift.dart';

import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';

const String kSettingAtelierName = 'atelier_name';
const String kSettingNotifDelivery = 'notif_delivery';
const String kSettingNotifFitting = 'notif_fitting';
const String kSettingNotifPayments = 'notif_payments';
const String kSettingNotifLate = 'notif_late';

const String kDefaultAtelierName = 'Angela Couture';
const bool kDefaultNotifDelivery = true;
const bool kDefaultNotifFitting = true;
const bool kDefaultNotifPayments = true;
const bool kDefaultNotifLate = true;

abstract class SettingsRepository {
  Stream<Map<String, String>> watchAll();
  Future<Map<String, String>> getAll();
  Future<String?> get(String key);
  Future<void> set(String key, String value);
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository({
    required this.db,
    this.clock = const SystemClock(),
  });

  final db_layer.AppDatabase db;
  final Clock clock;

  @override
  Stream<Map<String, String>> watchAll() {
    return db.select(db.settings).watch().map((rows) {
      return {for (final row in rows) row.key: row.value};
    });
  }

  @override
  Future<Map<String, String>> getAll() async {
    final rows = await db.select(db.settings).get();
    return {for (final row in rows) row.key: row.value};
  }

  @override
  Future<String?> get(String key) async {
    final row = await (db.select(db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  @override
  Future<void> set(String key, String value) async {
    final now = clock.now();
    final existing = await (db.select(db.settings)..where((t) => t.key.equals(key))).getSingleOrNull();
    final createdAt = existing?.createdAt ?? now;
    final updatedAt = now;

    await db.writeWithOutbox(
      entity: 'settings',
      entityId: key,
      op: 'upsert',
      timestamp: now,
      action: () async {
        await db.into(db.settings).insertOnConflictUpdate(
              db_layer.SettingsCompanion(
                id: Value(key),
                key: Value(key),
                value: Value(value),
                createdAt: Value(createdAt),
                updatedAt: Value(updatedAt),
              ),
            );
      },
    );
  }
}
