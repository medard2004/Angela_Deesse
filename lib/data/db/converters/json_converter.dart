import 'dart:convert';
import 'package:drift/drift.dart';

/// Convertisseur pour les valeurs de mensurations (`Map<String, double>` <-> JSON String).
class MeasurementValuesConverter extends TypeConverter<Map<String, double>, String> {
  const MeasurementValuesConverter();

  @override
  Map<String, double> fromSql(String fromDb) {
    if (fromDb.trim().isEmpty) return const {};
    final decoded = jsonDecode(fromDb) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  @override
  String toSql(Map<String, double> value) => jsonEncode(value);
}

/// Convertisseur pour les listes de chaînes (`List<String>` <-> JSON String).
class StringListJsonConverter extends TypeConverter<List<String>, String> {
  const StringListJsonConverter();

  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.trim().isEmpty) return const [];
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded.cast<String>();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
