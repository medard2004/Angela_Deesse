import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';
import 'orders_table.dart';

@TableIndex(name: 'idx_order_photos_order_id', columns: {#orderId})
@TableIndex(name: 'idx_order_photos_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_order_photos_deleted_at', columns: {#deletedAt})
class OrderPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get photoPath => text()();
  TextColumn get photoHash => text().nullable()();
  TextColumn get photoUploadState => text().withDefault(const Constant('none'))(); // none, pending, uploaded, failed
  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
