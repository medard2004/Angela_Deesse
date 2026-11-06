import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:angela_dress/data/db/app_database.dart';

void main() {
  group('Schema Drift v1 Gelé (schema-v1-frozen)', () {
    late AppDatabase db;
    late Map<String, dynamic> schemaDump;

    setUpAll(() async {
      final dumpFile = File('drift_schemas/drift_schema_v1.json');
      expect(dumpFile.existsSync(), isTrue,
          reason: 'Le dump drift_schemas/drift_schema_v1.json doit exister.');
      final content = await dumpFile.readAsString();
      schemaDump = jsonDecode(content) as Map<String, dynamic>;
    });

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Version du schéma gelée à schemaVersion = 1', () {
      expect(db.schemaVersion, equals(1));
    });

    test('2. Toutes les tables du dump v1 sont présentes et conformes', () {
      final dumpEntities = (schemaDump['entities'] as List)
          .where((e) => e['type'] == 'table')
          .toList();

      final dumpTableNames = dumpEntities
          .map((e) => (e['data'] as Map)['name'] as String)
          .toSet();

      final expectedTables = {
        'clients',
        'measurements',
        'modeles',
        'realisations',
        'orders',
        'order_photos',
        'client_payments',
        'apprentices',
        'apprentice_payments',
        'settings',
        'sync_outbox',
        'receipt_counters',
      };

      expect(dumpTableNames, containsAll(expectedTables));
      expect(db.allTables.map((t) => t.actualTableName).toSet(),
          containsAll(expectedTables));
    });

    test('3. Contraintes CHECK obligatoires présentes sur le schéma', () {
      final dumpEntities = (schemaDump['entities'] as List)
          .where((e) => e['type'] == 'table')
          .toList();

      // Vérifier CHECK photo_upload_state sur modeles, realisations, orders, order_photos
      for (final tableName in ['modeles', 'realisations', 'orders', 'order_photos']) {
        final tableData = dumpEntities.firstWhere(
            (e) => (e['data'] as Map)['name'] == tableName)['data'] as Map;
        final constraints = (tableData['constraints'] as List? ?? []).cast<String>();
        expect(
          constraints.any((c) =>
              c.contains('photo_upload_state') &&
              c.contains("'none'") &&
              c.contains("'uploaded'")),
          isTrue,
          reason: 'Table $tableName doit avoir CHECK sur photo_upload_state.',
        );
      }

      // Vérifier CHECK op sur sync_outbox
      final outboxData = dumpEntities.firstWhere(
          (e) => (e['data'] as Map)['name'] == 'sync_outbox')['data'] as Map;
      final outboxConstraints =
          (outboxData['constraints'] as List? ?? []).cast<String>();
      expect(
        outboxConstraints.any((c) =>
            c.contains('op') &&
            c.contains("'upsert'") &&
            c.contains("'delete'")),
        isTrue,
        reason: 'Table sync_outbox doit avoir CHECK sur op.',
      );
    });
  });
}
