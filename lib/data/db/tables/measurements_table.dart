import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';
import '../converters/json_converter.dart';
import 'clients_table.dart';

@TableIndex(name: 'idx_measurements_client_id', columns: {#clientId})
@TableIndex(name: 'idx_measurements_taken_at', columns: {#takenAt})
@TableIndex(name: 'idx_measurements_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_measurements_updated_at', columns: {#updatedAt})
class Measurements extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id)();
  IntColumn get takenAt => integer().map(const DateTimeConverter())();
  TextColumn get measures => text().map(const MeasurementValuesConverter())();
  TextColumn get note => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
