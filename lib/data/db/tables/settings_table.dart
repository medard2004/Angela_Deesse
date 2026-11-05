import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

@TableIndex(name: 'idx_settings_key', columns: {#key}, unique: true)
@TableIndex(name: 'idx_settings_updated_at', columns: {#updatedAt})
class Settings extends Table {
  TextColumn get id => text()(); // Égal à key (ex. id = 'atelier_name')
  TextColumn get key => text()();
  TextColumn get value => text()();

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
