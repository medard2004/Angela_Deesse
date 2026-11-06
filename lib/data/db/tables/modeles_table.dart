import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

@TableIndex(name: 'idx_modeles_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_modeles_updated_at', columns: {#updatedAt})
@TableIndex(name: 'idx_modeles_name', columns: {#name})
class Modeles extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();

  // Colonnes photo selon Décision 5 (accepte convention demo:N ou chemin local)
  TextColumn get photoPath => text().nullable()();
  TextColumn get photoHash => text().nullable()();
  TextColumn get photoUploadState => text().withDefault(const Constant('none'))(); // none, pending, uploaded, failed

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (photo_upload_state IN ('none', 'pending', 'uploaded', 'failed'))",
      ];
}
