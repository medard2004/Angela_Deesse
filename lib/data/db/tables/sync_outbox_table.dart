import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

@TableIndex(name: 'idx_sync_outbox_created_at', columns: {#createdAt})
@TableIndex(name: 'idx_sync_outbox_entity_row', columns: {#entity, #entityId})
class SyncOutbox extends Table {
  TextColumn get id => text()(); // UUIDv7
  TextColumn get entity => text()(); // Nom de l'entité/table : 'clients', 'orders', etc.
  TextColumn get entityId => text()(); // Identifiant de la ligne concernée
  TextColumn get op => text()(); // 'upsert' ou 'delete'
  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
