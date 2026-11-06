import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _num = NumberFormat.decimalPattern('fr_FR');

/// 125000 -> "125 000 FCFA" (espaces normaux, compatibles avec le PDF).
String fcfa(num v) => '${_num.format(v.round())} FCFA'.replaceAll(RegExp('[\u202f\u00a0]'), ' ');

String fmtDate(DateTime d) => DateFormat('d MMM yyyy', 'fr_FR').format(d);
String fmtDay(DateTime d) => DateFormat('EEE d MMM', 'fr_FR').format(d);

DateTime today() => DateUtils.dateOnly(DateTime.now());
int daysUntil(DateTime d) => DateUtils.dateOnly(d).difference(today()).inDays;

String countdown(DateTime d) {
  final n = daysUntil(d);
  if (n == 0) return "Aujourd'hui";
  if (n == 1) return 'Demain';
  if (n > 1) return 'Dans $n jours';
  if (n == -1) return '1 jour de retard';
  return '${-n} jours de retard';
}

String fmtDayLong(DateTime d) => DateFormat('EEEE d MMMM', 'fr_FR').format(d);
String fmtTime(DateTime d) => DateFormat('HH:mm').format(d);

/// Formate un numéro de reçu de manière unifiée et non-divergente.
/// Type: 'CMD' (commande client) ou 'APP' (versement apprenti).
/// Exemple: formatReceiptNumber('CMD', 7) -> 'CMD-0007'
///          formatReceiptNumber('APP', 1) -> 'APP-0001'
String formatReceiptNumber(String type, int number) {
  final cleanType = type.trim().toUpperCase();
  return '$cleanType-${number.toString().padLeft(4, '0')}';
}
