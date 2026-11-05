import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'converters/datetime_converter.dart';
import 'converters/json_converter.dart';
import 'id_generator.dart';
import 'tables/apprentice_payments_table.dart';
import 'tables/apprentices_table.dart';
import 'tables/client_payments_table.dart';
import 'tables/clients_table.dart';
import 'tables/measurements_table.dart';
import 'tables/modeles_table.dart';
import 'tables/order_photos_table.dart';
import 'tables/orders_table.dart';
import 'tables/realisations_table.dart';
import 'tables/receipt_counters_table.dart';
import 'tables/settings_table.dart';
import 'tables/sync_outbox_table.dart';
import 'tables/sync_state_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Clients,
  Measurements,
  Modeles,
  Orders,
  OrderPhotos,
  ClientPayments,
  Apprentices,
  ApprenticePayments,
  Realisations,
  Settings,
  ReceiptCounters,
  SyncOutbox,
  SyncState,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e, IdGenerator? idGenerator])
      : idGenerator = idGenerator ?? const UuidV7IdGenerator(),
        super(e ?? _openConnection());

  final IdGenerator idGenerator;

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Activation explicite des clés étrangères dans SQLite
          await customStatement('PRAGMA foreign_keys = ON;');
        },
      );

  /// Exécute une opération d'écriture et enregistre son événement dans [SyncOutbox]
  /// au sein d'une seule transaction SQLite atomique (rollback total si l'un échoue).
  Future<T> writeWithOutbox<T>({
    required String entity,
    required String entityId,
    required String op, // 'upsert' ou 'delete'
    required Future<T> Function() action,
  }) {
    return transaction(() async {
      final result = await action();
      final outboxId = idGenerator.generate();
      final now = DateTime.now().toUtc();
      await into(syncOutbox).insert(
        SyncOutboxCompanion.insert(
          id: outboxId,
          entity: entity,
          entityId: entityId,
          op: op,
          createdAt: now,
          attempts: const Value(0),
        ),
      );
      return result;
    });
  }

  /// Réserve et incrémente le prochain numéro de reçu séquentiel dans [ReceiptCounters]
  /// au sein de la transaction courante.
  Future<int> nextReceiptNumber({String counterName = 'global'}) async {
    final existing = await (select(receiptCounters)
          ..where((t) => t.counterName.equals(counterName)))
        .getSingleOrNull();

    final nextVal = (existing?.lastValue ?? 0) + 1;
    final now = DateTime.now().toUtc();

    await into(receiptCounters).insertOnConflictUpdate(
      ReceiptCountersCompanion.insert(
        counterName: counterName,
        lastValue: Value(nextVal),
        updatedAt: now,
      ),
    );

    return nextVal;
  }

  /// Réconcilie les compteurs de reçus locaux avec les numéros existants en base
  /// (versements annulés inclus). Pour chaque compteur, last_value = max(last_value, MAX(receipt_number)).
  Future<void> reconcileReceiptCounters() async {
    await transaction(() async {
      final now = DateTime.now().toUtc();

      // Compteur clients
      final clientMaxQuery = selectOnly(clientPayments)
        ..addColumns([clientPayments.receiptNumber.max()]);
      final clientRow = await clientMaxQuery.getSingle();
      final maxClientReceipt = clientRow.read(clientPayments.receiptNumber.max()) ?? 0;

      final existingClientCounter = await (select(receiptCounters)
            ..where((t) => t.counterName.equals('clients')))
          .getSingleOrNull();
      final currentClientVal = existingClientCounter?.lastValue ?? 0;
      final newClientVal = maxClientReceipt > currentClientVal ? maxClientReceipt : currentClientVal;

      await into(receiptCounters).insertOnConflictUpdate(
        ReceiptCountersCompanion.insert(
          counterName: 'clients',
          lastValue: Value(newClientVal),
          updatedAt: now,
        ),
      );

      // Compteur apprentis
      final appMaxQuery = selectOnly(apprenticePayments)
        ..addColumns([apprenticePayments.receiptNumber.max()]);
      final appRow = await appMaxQuery.getSingle();
      final maxAppReceipt = appRow.read(apprenticePayments.receiptNumber.max()) ?? 0;

      final existingAppCounter = await (select(receiptCounters)
            ..where((t) => t.counterName.equals('apprentices')))
          .getSingleOrNull();
      final currentAppVal = existingAppCounter?.lastValue ?? 0;
      final newAppVal = maxAppReceipt > currentAppVal ? maxAppReceipt : currentAppVal;

      await into(receiptCounters).insertOnConflictUpdate(
        ReceiptCountersCompanion.insert(
          counterName: 'apprentices',
          lastValue: Value(newAppVal),
          updatedAt: now,
        ),
      );
    });
  }

  /// Calcule la somme des paiements actifs pour une commande en excluant
  /// les paiements annulés (voided_at != null) et supprimés logiquement (deleted_at != null).
  Future<int> activePaymentsTotalForOrder(String orderId) async {
    final query = selectOnly(clientPayments)
      ..addColumns([clientPayments.amount.sum()])
      ..where(clientPayments.orderId.equals(orderId) &
          clientPayments.voidedAt.isNull() &
          clientPayments.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(clientPayments.amount.sum()) ?? 0;
  }

  /// Calcule la somme des versements actifs pour un apprenti en excluant
  /// les versements annulés (voided_at != null) et supprimés logiquement (deleted_at != null).
  Future<int> activePaymentsTotalForApprentice(String apprenticeId) async {
    final query = selectOnly(apprenticePayments)
      ..addColumns([apprenticePayments.amount.sum()])
      ..where(apprenticePayments.apprenticeId.equals(apprenticeId) &
          apprenticePayments.voidedAt.isNull() &
          apprenticePayments.deletedAt.isNull());
    final row = await query.getSingle();
    return row.read(apprenticePayments.amount.sum()) ?? 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'angela_deesse.sqlite'));
      return NativeDatabase.createInBackground(file);
    } catch (_) {
      return NativeDatabase.memory();
    }
  });
}
