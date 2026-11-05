import 'package:drift/drift.dart';
import '../converters/datetime_converter.dart';
import 'apprentices_table.dart';

@TableIndex(name: 'idx_apprentice_payments_apprentice_id', columns: {#apprenticeId})
@TableIndex(name: 'idx_apprentice_payments_receipt_number', columns: {#receiptNumber}, unique: true)
@TableIndex(name: 'idx_apprentice_payments_paid_at', columns: {#paidAt})
@TableIndex(name: 'idx_apprentice_payments_voided_at', columns: {#voidedAt})
@TableIndex(name: 'idx_apprentice_payments_deleted_at', columns: {#deletedAt})
@TableIndex(name: 'idx_apprentice_payments_updated_at', columns: {#updatedAt})
class ApprenticePayments extends Table {
  TextColumn get id => text()();
  TextColumn get apprenticeId => text().references(Apprentices, #id)();
  IntColumn get amount => integer()(); // FCFA entier
  IntColumn get paidAt => integer().map(const DateTimeConverter())();
  TextColumn get note => text().withDefault(const Constant(''))();

  // Reçu & Annulation selon Décision 4 & Tranche 4
  IntColumn get receiptNumber => integer()(); // NOT NULL avec index UNIQUE
  IntColumn get totalFeeAtPayment => integer()(); // Frais de formation au moment du versement
  IntColumn get balanceAfter => integer()(); // Solde restant après ce versement (immuable)
  IntColumn get voidedAt => integer().nullable().map(const NullableDateTimeConverter())();
  TextColumn get voidReason => text().nullable()();

  IntColumn get createdAt => integer().map(const DateTimeConverter())();
  IntColumn get updatedAt => integer().map(const DateTimeConverter())();
  IntColumn get deletedAt => integer().nullable().map(const NullableDateTimeConverter())();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (amount > 0)',
        'CHECK (balance_after >= 0)',
      ];
}
