import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

@TableIndex(name: 'idx_clients_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_clients_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_clients_name', columns: {#name})
class Clients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
