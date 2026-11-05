import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';

/// Table d'état de synchronisation locale (non synchronisée avec le serveur).
/// Stocke le curseur de pull (server_seq), la date de dernier envoi, etc.
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();

  @override
  Set<Column> get primaryKey => {key};
}
