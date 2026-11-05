import 'package:drift/drift.dart';

/// Convertit un DateTime Dart en millisecondes UTC (entier) pour SQLite.
///
/// Contrairement au type natif `dateTime()` de Drift qui stocke par défaut
/// les dates en secondes entières Unix (`millisecondsSinceEpoch ~/ 1000`), ce
/// convertisseur préserve l'exactitude des millisecondes et force la cohérence
/// en UTC pour éviter les dérives de fuseaux horaires locaux.
class DateTimeConverter extends TypeConverter<DateTime, int> {
  const DateTimeConverter();

  @override
  DateTime fromSql(int fromDb) => DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}

/// Version nullable de [DateTimeConverter].
class NullableDateTimeConverter extends TypeConverter<DateTime?, int?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromSql(int? fromDb) =>
      fromDb == null ? null : DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);

  @override
  int? toSql(DateTime? value) => value?.toUtc().millisecondsSinceEpoch;
}
