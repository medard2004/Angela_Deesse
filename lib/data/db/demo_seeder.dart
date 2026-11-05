import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Seeder des données de démonstration pour Clients, Mesures, Modèles et Réalisations.
/// S'exécute uniquement si :
/// 1. kDebugMode est vrai (jamais en release)
/// 2. La clé d'entité ('demo_seeded:clients', 'demo_seeded:modeles', 'demo_seeded:realisations') est absente
/// N'écrit AUCUNE ligne dans sync_outbox (la démo ne doit pas être synchronisée).
class DemoSeeder {
  const DemoSeeder(this.db);

  final AppDatabase db;

  Future<bool> seedIfNecessary({bool? isDebug}) async {
    final debug = isDebug ?? kDebugMode;
    if (!debug) return false;

    final now = DateTime.now().toUtc();
    DateTime day(int offset) => now.add(Duration(days: offset));

    bool didSeed = false;

    // 1. Migration : si 'demo_seeded' existe, la convertir en 'demo_seeded:clients'
    final legacySeeded = await (db.select(db.syncState)
          ..where((t) => t.key.equals('demo_seeded')))
        .getSingleOrNull();

    if (legacySeeded != null && legacySeeded.value == '1') {
      await db.into(db.syncState).insertOnConflictUpdate(
            SyncStateCompanion.insert(
              key: 'demo_seeded:clients',
              value: '1',
              updatedAt: legacySeeded.updatedAt,
            ),
          );
      await (db.delete(db.syncState)..where((t) => t.key.equals('demo_seeded'))).go();
    }

    // 2. Clients & Mesures
    final clientsSeeded = await (db.select(db.syncState)
          ..where((t) => t.key.equals('demo_seeded:clients')))
        .getSingleOrNull();

    if (clientsSeeded == null) {
      final existingClientsCount = await db.clients.count().getSingle();
      if (existingClientsCount == 0) {
        await db.transaction(() async {
          const names = [
            ('Ama Mensah', '90 12 34 56'),
            ('Yawa Kpogo', '91 45 67 89'),
            ('Adjoa Agbodjan', '92 33 21 08'),
            ('Akouvi Lawson', '90 77 12 40'),
            ('Afi Dosseh', '93 18 52 66'),
            ('Edem Amegah', '98 04 31 72'),
            ('Mawussi Koffi', '97 66 20 15'),
            ('Abla Tchalla', '91 29 83 47'),
            ('Dzifa Ayivi', '99 50 14 38'),
          ];

          for (var i = 0; i < names.length; i++) {
            final id = 'c$i';
            final notes = i == 1 ? 'Préfère les coupes ajustées.' : '';
            await db.into(db.clients).insert(
                  ClientsCompanion.insert(
                    id: id,
                    name: names[i].$1,
                    phone: Value(names[i].$2),
                    notes: Value(notes),
                    createdAt: day(-30 + i),
                    updatedAt: day(-30 + i),
                  ),
                );
          }

          for (final c in ['c0', 'c1', 'c2']) {
            final k = c == 'c0' ? 0 : c == 'c1' ? 2 : 4;
            await db.into(db.measurements).insert(
                  MeasurementsCompanion.insert(
                    id: 'm$c',
                    clientId: c,
                    takenAt: day(-20 - k),
                    measures: {
                      'Épaules': 38.0 + k,
                      'Tour de poitrine': 92.0 + k,
                      'Tour de taille': 74.0 + k,
                      'Tour de bassin': 100.0 + k,
                      'Longueur robe': 112.0,
                      'Longueur manche': 58.0,
                    },
                    note: const Value(''),
                    createdAt: day(-20 - k),
                    updatedAt: day(-20 - k),
                  ),
                );
          }

          await db.into(db.syncState).insertOnConflictUpdate(
                SyncStateCompanion.insert(
                  key: 'demo_seeded:clients',
                  value: '1',
                  updatedAt: now,
                ),
              );
        });
        didSeed = true;
      }
    }

    // 3. Modèles
    final modelesSeeded = await (db.select(db.syncState)
          ..where((t) => t.key.equals('demo_seeded:modeles')))
        .getSingleOrNull();

    if (modelesSeeded == null) {
      await db.transaction(() async {
        const mods = [
          ('Robe sirène', 'Coupe ajustée jusqu\'aux genoux, évasée en bas.'),
          ('Ensemble pagne', 'Haut cintré et jupe longue assortie.'),
          ('Chemise bazin', 'Col mao, broderies sur le plastron.'),
          ('Costume 3 pièces', 'Veste, pantalon et gilet.'),
          ('Boubou brodé', 'Grand boubou, broderies main.'),
          ('Robe enfant', 'Robe évasée avec nœud dans le dos.'),
        ];

        for (var i = 0; i < mods.length; i++) {
          await db.into(db.modeles).insert(
                ModelesCompanion.insert(
                  id: 'mo$i',
                  name: mods[i].$1,
                  description: Value(mods[i].$2),
                  photoPath: Value('demo:$i'),
                  photoUploadState: const Value('none'),
                  createdAt: day(-30 + i),
                  updatedAt: day(-30 + i),
                ),
              );
        }

        await db.into(db.syncState).insertOnConflictUpdate(
              SyncStateCompanion.insert(
                key: 'demo_seeded:modeles',
                value: '1',
                updatedAt: now,
              ),
            );
      });
      didSeed = true;
    }

    // 4. Réalisations
    final realisationsSeeded = await (db.select(db.syncState)
          ..where((t) => t.key.equals('demo_seeded:realisations')))
        .getSingleOrNull();

    if (realisationsSeeded == null) {
      await db.transaction(() async {
        const cats = ['Robe', 'Robe', 'Chemise', 'Costume', 'Pagne', 'Pagne', 'Enfant', 'Robe', 'Costume'];
        const modNames = [
          'Robe sirène',
          'Ensemble pagne',
          'Chemise bazin',
          'Costume 3 pièces',
          'Boubou brodé',
          'Robe enfant',
        ];

        final existingClients = await db.select(db.clients).get();
        final clientIds = existingClients.map((c) => c.id).toSet();

        for (var i = 0; i < cats.length; i++) {
          final targetClientId = 'c${i % 6}';
          final effectiveClientId = clientIds.contains(targetClientId) ? targetClientId : null;
          await db.into(db.realisations).insert(
                RealisationsCompanion.insert(
                  id: 'r$i',
                  photoPath: 'demo:${i + 2}',
                  category: Value(cats[i]),
                  clientId: Value(effectiveClientId),
                  caption: Value(i.isEven ? modNames[i % modNames.length] : ''),
                  photoUploadState: const Value('none'),
                  createdAt: day(-3 * i - 2),
                  updatedAt: day(-3 * i - 2),
                ),
              );
        }

        await db.into(db.syncState).insertOnConflictUpdate(
              SyncStateCompanion.insert(
                key: 'demo_seeded:realisations',
                value: '1',
                updatedAt: now,
              ),
            );
      });
      didSeed = true;
    }

    return didSeed;
  }
}
