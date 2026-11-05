import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

/// Table dédiée au compteur séquentiel de reçus (pour clients et apprentis).
class ReceiptCounters extends Table {
  TextColumn get counterName => text()();
  IntColumn get lastValue => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();

  @override
  Set<Column> get primaryKey => {counterName};
}
