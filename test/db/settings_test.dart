import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/db/demo_seeder.dart';
import 'package:angela_dress/data/repositories/settings_repository.dart';

class TestClock implements Clock {
  TestClock(this.currentTime);
  DateTime currentTime;

  @override
  DateTime now() => currentTime;
}

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Tranche 5A - Réglages persistés (SettingsRepository & Drift)', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late DriftSettingsRepository settingsRepo;

    setUp(() async {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 5, 10, 0));
      settingsRepo = DriftSettingsRepository(db: db, clock: clock);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Aller-retour : écriture et lecture d un réglage', () async {
      // Valeur absente initialement
      final initial = await settingsRepo.get(kSettingAtelierName);
      expect(initial, isNull);

      // Écriture
      await settingsRepo.set(kSettingAtelierName, 'Atelier Haute Couture');

      final value = await settingsRepo.get(kSettingAtelierName);
      expect(value, 'Atelier Haute Couture');

      final all = await settingsRepo.getAll();
      expect(all[kSettingAtelierName], 'Atelier Haute Couture');
    });

    test('2. Deux écritures de la même clé = une seule ligne (id = key)', () async {
      await settingsRepo.set('custom_key', 'valeur_1');
      var rows = await db.select(db.settings).get();
      expect(rows.length, 1);
      expect(rows.first.id, 'custom_key');
      expect(rows.first.key, 'custom_key');
      expect(rows.first.value, 'valeur_1');
      expect(rows.first.createdAt, clock.now());
      expect(rows.first.updatedAt, clock.now());

      // Deuxième écriture à un temps ultérieur
      final later = clock.now().add(const Duration(hours: 2));
      clock.currentTime = later;
      await settingsRepo.set('custom_key', 'valeur_2');

      rows = await db.select(db.settings).get();
      expect(rows.length, 1, reason: 'id = key doit garantir une seule ligne par clé');
      expect(rows.first.value, 'valeur_2');
      expect(rows.first.createdAt, DateTime.utc(2026, 11, 5, 10, 0));
      expect(rows.first.updatedAt, later);
    });

    test('3. Entrée d outbox correcte à chaque écriture', () async {
      await settingsRepo.set(kSettingNotifDelivery, 'false');

      final outbox = await db.select(db.syncOutbox).get();
      expect(outbox.length, 1);
      expect(outbox.first.entity, 'settings');
      expect(outbox.first.entityId, kSettingNotifDelivery);
      expect(outbox.first.op, 'upsert');
    });

    test('4. Valeur par défaut quand la clé est absente', () async {
      final val = await settingsRepo.get(kSettingNotifFitting);
      expect(val, isNull);
      // Les constantes par défaut vivent dans le code
      final effective = val ?? (kDefaultNotifFitting ? 'true' : 'false');
      expect(effective, 'true');
    });

    test('5. Ligne restaurée (pull/sync) avec même clé et même id insérée sans violation', () async {
      // Simuler l'arrivée d'une ligne de synchronisation
      await db.into(db.settings).insertOnConflictUpdate(
            db_layer.SettingsCompanion.insert(
              id: 'restored_key',
              key: 'restored_key',
              value: 'restored_val',
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ),
          );

      final val = await settingsRepo.get('restored_key');
      expect(val, 'restored_val');

      // Ré-écriture locale par-dessus
      await settingsRepo.set('restored_key', 'updated_locally');
      final updated = await settingsRepo.get('restored_key');
      expect(updated, 'updated_locally');

      final rows = await (db.select(db.settings)..where((t) => t.key.equals('restored_key'))).get();
      expect(rows.length, 1);
    });

    test('6. DemoSeeder n écrit aucun réglage', () async {
      final seeder = DemoSeeder(db);
      await seeder.seedIfNecessary(isDebug: true);

      final settingsCount = await db.settings.count().getSingle();
      expect(settingsCount, 0, reason: 'Le DemoSeeder ne doit JAMAIS insérer de réglages');
    });

    test('7. Persistance sur base FICHIER temporaire across restarts', () async {
      final tempDir = await Directory.systemTemp.createTemp('angela_settings_test_');
      final dbPath = p.join(tempDir.path, 'settings_persist.db');

      // Phase 1 : création et écriture
      final fileDb1 = db_layer.AppDatabase(NativeDatabase(File(dbPath)));
      final sRepo1 = DriftSettingsRepository(db: fileDb1, clock: clock);

      await sRepo1.set(kSettingAtelierName, 'Angela Déesse Couture');
      await sRepo1.set(kSettingNotifLate, 'false');
      await fileDb1.close();

      // Phase 2 : réouverture avec nouvelle instance
      final fileDb2 = db_layer.AppDatabase(NativeDatabase(File(dbPath)));
      final sRepo2 = DriftSettingsRepository(db: fileDb2, clock: clock);

      final reloadedName = await sRepo2.get(kSettingAtelierName);
      final reloadedLate = await sRepo2.get(kSettingNotifLate);

      expect(reloadedName, 'Angela Déesse Couture');
      expect(reloadedLate, 'false');

      await fileDb2.close();
      await tempDir.delete(recursive: true);
    });
  });
}
