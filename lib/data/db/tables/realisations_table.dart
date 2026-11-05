import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';
import 'clients_table.dart';

@TableIndex(name: 'idx_realisations_category', columns: {#category})
@TableIndex(name: 'idx_realisations_client_id', columns: {#clientId})
@TableIndex(name: 'idx_realisations_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_realisations_updated_at', columns: {#updatedAt})
class Realisations extends Table {
  TextColumn get id => text()();
  TextColumn get category => text().withDefault(const Constant('Autre'))();
  TextColumn get clientId => text().nullable().references(Clients, #id)();
  TextColumn get caption => text().withDefault(const Constant(''))();

  // Photo selon Décision 5
  TextColumn get photoPath => text()(); // Requis pour une réalisation (accepte demo:N ou chemin local)
  TextColumn get photoHash => text().nullable()();
  TextColumn get photoUploadState => text().withDefault(const Constant('none'))(); // none, pending, uploaded, failed

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
