import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

@TableIndex(name: 'idx_apprentices_name', columns: {#name})
@TableIndex(name: 'idx_apprentices_next_due', columns: {#nextDue})
@TableIndex(name: 'idx_apprentices_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_apprentices_updated_at', columns: {#updatedAt})
class Apprentices extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  IntColumn get startDate => integer().map(const DateTimeConverter())();
  IntColumn get totalFee => integer()(); // FCFA entier
  IntColumn get nextDue => integer().nullable().map(const NullableDateTimeConverter())();
  TextColumn get notes => text().withDefault(const Constant(''))();

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (total_fee >= 0)'];
}
