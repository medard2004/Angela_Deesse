import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

/// Table locale pour l'historique et la journalisation des alertes et rappels.
/// STRICTEMENT LOCALE : jamais synchronisée, jamais dans sync_outbox, exclue de DemoSeeder.
@TableIndex(name: 'idx_notification_log_scheduled_at', columns: {#scheduledAt})
@TableIndex(name: 'idx_notification_log_outcome', columns: {#outcome})
@TableIndex(name: 'idx_notification_log_seen_at', columns: {#seenAt})
@TableIndex(name: 'idx_notification_log_source_event_id', columns: {#sourceEventId}, unique: true)
class NotificationLogs extends Table {
  @override
  String get tableName => 'notification_log';

  TextColumn get id => text()();
  TextColumn get channel => text()(); // 'alarm' | 'notification' | 'banner'
  TextColumn get category => text()(); // 'delivery' | 'fitting' | 'apprentice' | 'late' | 'custom'
  TextColumn get title => text()();
  TextColumn get body => text()();
  IntColumn get itemCount => integer().withDefault(const Constant(1))();
  TextColumn get alertKeys => text()(); // Sérialisé en JSON ou séparateur virgule
  IntColumn get scheduledAt => integer().map(const DateTimeConverter())();
  IntColumn get firedAt => integer().nullable().map(const NullableDateTimeConverter())();
  IntColumn get endedAt => integer().nullable().map(const NullableDateTimeConverter())();
  TextColumn get outcome => text()(); // 'displayed' | 'opened' | 'stopped' | 'snoozed' | 'missed'
  IntColumn get snoozeCount => integer().withDefault(const Constant(0))();
  IntColumn get seenAt => integer().nullable().map(const NullableDateTimeConverter())();
  TextColumn get sourceEventId => text().nullable()();
  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
