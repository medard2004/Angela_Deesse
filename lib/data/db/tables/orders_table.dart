import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';
import 'clients_table.dart';
import 'modeles_table.dart';

@TableIndex(name: 'idx_orders_client_id', columns: {#clientId})
@TableIndex(name: 'idx_orders_modele_id', columns: {#modeleId})
@TableIndex(name: 'idx_orders_delivery_date', columns: {#deliveryDate})
@TableIndex(name: 'idx_orders_status', columns: {#status})
@TableIndex(name: 'idx_orders_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_orders_updated_at', columns: {#updatedAt})
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text().references(Clients, #id)();
  TextColumn get modeleId => text().nullable().references(Modeles, #id)();
  TextColumn get title => text()();
  TextColumn get fabric => text().withDefault(const Constant(''))();
  IntColumn get price => integer()(); // FCFA entier
  IntColumn get deliveryDate => integer().map(const DateTimeConverter())();
  IntColumn get fittingDate => integer().nullable().map(const NullableDateTimeConverter())();
  TextColumn get status => text().withDefault(const Constant('attente'))(); // attente, cours, prete, livree

  // Photo selon Décision 5
  TextColumn get photoPath => text().nullable()();
  TextColumn get photoHash => text().nullable()();
  TextColumn get photoUploadState => text().withDefault(const Constant('none'))(); // none, pending, uploaded, failed

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (price >= 0)'];
}
