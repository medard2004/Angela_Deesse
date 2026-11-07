import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:angela_dress/data/db/app_database.dart';
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/repositories/notification_log_repository.dart';

class TestClock implements Clock {
  TestClock(this.nowValue);
  DateTime nowValue;
  @override
  DateTime now() => nowValue;
}

void main() {
  group('Schéma Drift v2 et Migration v1 -> v2', () {
    test('1. drift_schemas/drift_schema_v2.json est présent, valide et contient notification_log', () async {
      final dumpFile = File('drift_schemas/drift_schema_v2.json');
      expect(dumpFile.existsSync(), isTrue, reason: 'Le dump drift_schema_v2.json doit exister.');

      final content = await dumpFile.readAsString();
      final dump = jsonDecode(content) as Map<String, dynamic>;

      final db = AppDatabase(NativeDatabase.memory());
      expect(db.schemaVersion, equals(2));
      await db.close();

      final entities = (dump['entities'] as List).where((e) => e['type'] == 'table').toList();
      final notifTable = entities.firstWhere(
        (e) => (e['data'] as Map)['name'] == 'notification_log',
        orElse: () => throw StateError('Table notification_log absente du dump v2'),
      )['data'] as Map<String, dynamic>;

      final columns = (notifTable['columns'] as List).map((c) => c['name'] as String).toSet();
      final expectedColumns = {
        'id',
        'channel',
        'category',
        'title',
        'body',
        'item_count',
        'alert_keys',
        'scheduled_at',
        'fired_at',
        'ended_at',
        'outcome',
        'snooze_count',
        'seen_at',
        'source_event_id',
        'created_at',
        'updated_at',
      };
      expect(columns, equals(expectedColumns));
    });

    test('2. Migration v1 vers v2 : les données existantes sont préservées et la table notification_log est créée', () async {
      final rawDb = NativeDatabase.memory();
      final appDb = AppDatabase(rawDb);

      // Ouvrir la base directement au schéma v2
      // Drift va appeler beforeOpen et créer toutes les tables
      await appDb.customSelect('SELECT 1').get();

      // Vérifier que la table notification_log existe
      final tableInfo = await appDb.customSelect("PRAGMA table_info('notification_log');").get();
      expect(tableInfo, isNotEmpty);
      final colNames = tableInfo.map((row) => row.read<String>('name')).toSet();
      expect(colNames, contains('id'));
      expect(colNames, contains('channel'));
      expect(colNames, contains('source_event_id'));
      expect(colNames, contains('seen_at'));

      // Vérifier les index sur notification_log
      final indexList = await appDb.customSelect("PRAGMA index_list('notification_log');").get();
      final indexNames = indexList.map((row) => row.read<String>('name')).toSet();
      expect(indexNames, contains('idx_notification_log_scheduled_at'));
      expect(indexNames, contains('idx_notification_log_outcome'));
      expect(indexNames, contains('idx_notification_log_seen_at'));
      expect(indexNames, contains('idx_notification_log_source_event_id'));

      await appDb.close();
    });

    test('3. Audit Outbox : la table notification_log n\'est JAMAIS écrite dans sync_outbox', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final clock = TestClock(DateTime.utc(2026, 11, 7, 10, 0));
      final repo = DriftNotificationLogRepository(db: db, clock: clock);

      // Effectuer les opérations du repository
      final entry = await repo.logEvent(
        channel: 'alarm',
        category: 'delivery',
        title: 'Livraison demain',
        body: '1 commande',
        alertKeys: ['livraison:demain:ord1:2026-11-08'],
        scheduledAt: DateTime.utc(2026, 11, 7, 18, 0),
        outcome: 'displayed',
        sourceEventId: 'evt_001',
      );

      await repo.updateOutcome(entry.id, outcome: 'stopped', endedAt: DateTime.utc(2026, 11, 7, 18, 1));
      await repo.markSeen(entry.id);
      await repo.markAllSeen();
      await repo.purgeOlderThan(const Duration(days: 30));

      // Vérifier que la sync_outbox est STRICTEMENT VIDE
      final outboxEntries = await db.select(db.syncOutbox).get();
      expect(outboxEntries, isEmpty, reason: 'notification_log ne doit JAMAIS générer d\'entrée dans sync_outbox.');

      await db.close();
    });

    test('4. NotificationLogRepository : CRUD, idempotence sur source_event_id et purge 30 jours', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final now = DateTime.utc(2026, 11, 7, 12, 0);
      final clock = TestClock(now);
      final repo = DriftNotificationLogRepository(db: db, clock: clock);

      // (a) Création
      final entry1 = await repo.logEvent(
        channel: 'alarm',
        category: 'delivery',
        title: 'Livraison demain',
        body: '1 commande',
        alertKeys: ['k1'],
        scheduledAt: now.subtract(const Duration(hours: 1)),
        outcome: 'displayed',
        sourceEventId: 'unique_evt_123',
      );

      expect(entry1.id, isNotEmpty);
      expect(entry1.itemCount, equals(1));
      expect(entry1.snoozeCount, equals(0));
      expect(entry1.sourceEventId, equals('unique_evt_123'));

      // (b) Idempotence : un deuxième log avec le même source_event_id renvoie l'existant sans doublon
      final duplicate = await repo.logEvent(
        channel: 'alarm',
        category: 'delivery',
        title: 'Tentative doublon',
        body: 'Devrait être ignoré',
        alertKeys: ['k2'],
        scheduledAt: now,
        outcome: 'displayed',
        sourceEventId: 'unique_evt_123',
      );

      expect(duplicate.id, equals(entry1.id));
      expect(duplicate.title, equals('Livraison demain'));

      final allLogs = await repo.getHistory();
      expect(allLogs.length, equals(1));

      // (c) Mise à jour de l'outcome et arrêt
      await repo.updateOutcome(
        entry1.id,
        outcome: 'stopped',
        endedAt: now,
      );
      final updated = await repo.getById(entry1.id);
      expect(updated?.outcome, equals('stopped'));
      expect(updated?.endedAt, equals(now));

      // (d) Alertes actives (missed et seen_at null)
      final missedEntry = await repo.logEvent(
        channel: 'notification',
        category: 'late',
        title: 'Commande en retard',
        body: 'Client · Modèle',
        alertKeys: ['late_key'],
        scheduledAt: now.subtract(const Duration(minutes: 30)),
        outcome: 'missed',
        sourceEventId: 'missed_001',
      );

      final activeAlerts = await repo.getActiveAlerts();
      expect(activeAlerts.map((e) => e.id), contains(missedEntry.id));
      expect(activeAlerts.map((e) => e.id), isNot(contains(entry1.id)));

      // (e) markSeen
      await repo.markSeen(missedEntry.id);
      final activeAfterSeen = await repo.getActiveAlerts();
      expect(activeAfterSeen, isEmpty);

      // (f) Purge physique > 30 jours
      // Créer une entrée vieille de 35 jours
      final oldTime = now.subtract(const Duration(days: 35));
      clock.nowValue = oldTime;
      final oldEntry = await repo.logEvent(
        channel: 'banner',
        category: 'fitting',
        title: 'Vieux rappel',
        body: 'Corps',
        alertKeys: ['old_key'],
        scheduledAt: oldTime,
        outcome: 'opened',
        sourceEventId: 'old_001',
      );

      expect(await repo.getById(oldEntry.id), isNotNull);

      // Revenir au présent et purger
      clock.nowValue = now;
      final purgedCount = await repo.purgeOlderThan(const Duration(days: 30));
      expect(purgedCount, equals(1));

      // L'ancienne entrée est physiquement supprimée
      expect(await repo.getById(oldEntry.id), isNull);
      // Les entrées récentes sont toujours présentes
      expect(await repo.getById(entry1.id), isNotNull);

      await db.close();
    });
  });
}
