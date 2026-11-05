import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import 'app_database.dart';

/// Seeder des données de démonstration pour Clients et Mesures.
/// S'exécute uniquement si :
/// 1. kDebugMode est vrai (jamais en release)
/// 2. La base locale est vide pour les clients
/// 3. La clé 'demo_seeded' n'existe pas dans sync_state
/// N'écrit AUCUNE ligne dans sync_outbox (la démo ne doit pas être synchronisée).
class DemoSeeder {
  const DemoSeeder(this.db);

  final AppDatabase db;

  Future<bool> seedIfNecessary({bool? isDebug}) async {
    final debug = isDebug ?? kDebugMode;
    if (!debug) return false;

    // Vérifier si déjà seedé
    final seeded = await (db.select(db.syncState)
          ..where((t) => t.key.equals('demo_seeded')))
        .getSingleOrNull();
    if (seeded != null) return false;

    // Vérifier si la base a déjà des clients
    final existingClientsCount = await db.clients.count().getSingle();
    if (existingClientsCount > 0) return false;

    final now = DateTime.now().toUtc();
    DateTime day(int offset) => now.add(Duration(days: offset));

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

      // Marquer le seedage dans sync_state
      await db.into(db.syncState).insertOnConflictUpdate(
            SyncStateCompanion.insert(
              key: 'demo_seeded',
              value: '1',
              updatedAt: now,
            ),
          );
    });

    return true;
  }
}
