import 'package:drift/drift.dart';

import '../../core/app_brand.dart';
import '../db/app_database.dart' as db_layer;
import '../db/clock.dart';

const String kSettingAtelierName = 'atelier_name';
const String kSettingNotifDelivery = 'notif_delivery';
const String kSettingNotifFitting = 'notif_fitting';
const String kSettingNotifPayments = 'notif_payments';
const String kSettingNotifLate = 'notif_late';
const String kSettingNotifApprentice = 'notif_apprentice';
const String kSettingReminderGuideDismissed = 'reminder_guide_dismissed';

/// Modes de rappel configurables par l'artisan pour chaque type d'événement.
enum ReminderMode {
  none('none', 'Désactivé'),
  notification('notification', 'Notification'),
  alarm('alarm', 'Alarme réveil');

  const ReminderMode(this.code, this.label);
  final String code;
  final String label;

  static ReminderMode parse(String? value, {ReminderMode fallback = ReminderMode.notification}) {
    if (value == null) return fallback;
    if (value == 'alarm') return ReminderMode.alarm;
    if (value == 'notification') return ReminderMode.notification;
    if (value == 'none' || value == 'false') return ReminderMode.none;
    if (value == 'true') return fallback;
    return fallback;
  }

  String toSettingString() => code;
}

const String kDefaultAtelierName = AppBrand.defaultAtelierName;
const bool kDefaultNotifDelivery = true;
const bool kDefaultNotifFitting = true;
const bool kDefaultNotifPayments = true;
const bool kDefaultNotifLate = true;
const bool kDefaultNotifApprentice = true;

const ReminderMode kDefaultModeDelivery = ReminderMode.alarm;
const ReminderMode kDefaultModeFitting = ReminderMode.alarm;
const ReminderMode kDefaultModePayments = ReminderMode.notification;
const ReminderMode kDefaultModeLate = ReminderMode.notification;
const ReminderMode kDefaultModeApprentice = ReminderMode.alarm;

/// Table de correspondance famille / étape -> clé de réglage :
/// - Famille livraison (AlertFamily.delivery) :
///     - étape tomorrow (veille 18:00) : kSettingNotifDelivery ('notif_delivery', défaut alarm)
///     - étape today (jour J 08:00) : kSettingNotifDelivery ('notif_delivery', défaut alarm)
///     - étape overdue (retard) : kSettingNotifLate ('notif_late', in-app seulement, pas de rappel planifié futur)
///     - étape upcoming (dans 2 jours) : in-app seulement (accueil / notifications), pas de rappel planifié
/// - Famille essayage (AlertFamily.fitting) :
///     - étape tomorrow (veille 18:00) : kSettingNotifFitting ('notif_fitting', défaut alarm)
///     - étape today (jour J 1h avant ou 08:00) : kSettingNotifFitting ('notif_fitting', défaut alarm)
/// - Famille échéance d'apprenti (AlertFamily.apprenticeDue) :
///     - étape today (jour J 08:00) : kSettingNotifApprentice ('notif_apprentice', défaut alarm)
///     - étape tomorrow / upcoming (2-7 j) / overdue : in-app seulement, pas de rappel planifié
/// - Famille solde dû (AlertFamily.pendingBalance) :
///     - étape ready : kSettingNotifPayments ('notif_payments', défaut notification, in-app seulement, pas de rappel planifié)

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
