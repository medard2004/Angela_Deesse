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

    // 5. Commandes, Photos de commande & Versements
    final ordersSeeded = await (db.select(db.syncState)
          ..where((t) => t.key.equals('demo_seeded:orders')))
        .getSingleOrNull();

    if (ordersSeeded == null) {
      await db.transaction(() async {
        final existingClients = await db.select(db.clients).get();
        if (existingClients.isNotEmpty) {
          final clientIds = existingClients.map((c) => c.id).toSet();
          final existingModeles = await db.select(db.modeles).get();
          final modeleIds = existingModeles.map((m) => m.id).toSet();

          final defs = <(int, String, String, int, int, String, int, DateTime?, int?)>[
            (7, 'Robe cocktail', 'Satin émeraude', 45000, -3, 'cours', 20000, null, null),
            (8, 'Tailleur pantalon', 'Crêpe noir', 60000, -1, 'cours', 30000, null, null),
            (2, 'Ensemble bazin brodé', 'Bazin riche', 75000, 0, 'prete', 50000, null, 2),
            (3, 'Robe de mariage civil', 'Dentelle ivoire', 120000, 1, 'cours', 70000, null, 0),
            (0, 'Robe pagne', 'Wax Vlisco', 38000, 3, 'cours', 15000, null, 1),
            (1, 'Ensemble pagne', 'Wax doré', 55000, 5, 'attente', 25000, day(0).add(const Duration(hours: 10, minutes: 30)), 1),
            (4, 'Chemise bazin', 'Bazin bleu', 28000, 9, 'attente', 10000, null, 2),
            (5, 'Costume 3 pièces', 'Laine anthracite', 140000, 12, 'cours', 70000, day(6).add(const Duration(hours: 15)), 3),
            (6, 'Boubou brodé', 'Brocart blanc', 95000, 14, 'attente', 30000, day(8).add(const Duration(hours: 9)), 4),
            (0, 'Robe enfant', 'Coton rose', 22000, 16, 'attente', 0, null, 5),
            (4, 'Jupe wax', 'Wax Hollandais', 18000, 20, 'attente', 18000, null, null),
            (8, 'Robe longue', 'Satin bordeaux', 52000, 25, 'attente', 20000, null, 0),
            (2, 'Robe wax', 'Wax rouge', 30000, -10, 'livree', 30000, null, null),
            (1, 'Chemise', 'Bazin blanc', 25000, -15, 'livree', 25000, null, 2),
            (5, 'Costume', 'Lin beige', 110000, -20, 'livree', 110000, null, 3),
          ];

          var receiptNo = 1;

          for (var i = 0; i < defs.length; i++) {
            final d = defs[i];
            final orderId = 'o$i';
            final photoPath = 'demo:${i + 1}';
            final deliveryDate = day(d.$5);
            final fittingDate = d.$8;
            final createdAt = day(d.$5 - 14);

            final targetClientId = 'c${d.$1}';
            final effectiveClientId = clientIds.contains(targetClientId) ? targetClientId : clientIds.first;
            final targetModeleId = d.$9 == null ? null : 'mo${d.$9}';
            final effectiveModeleId = (targetModeleId != null && modeleIds.contains(targetModeleId)) ? targetModeleId : null;

            DateTime? deliveredAt;
            if (d.$6 == 'livree') {
              if (i == 13) {
                deliveredAt = day(d.$5 + 1).add(const Duration(hours: 11)); // 1 jour en retard
              } else {
                deliveredAt = day(d.$5).add(const Duration(hours: 14)); // À temps
              }
            }

            // 5.1 Insertion commande
            await db.into(db.orders).insert(
                  OrdersCompanion.insert(
                    id: orderId,
                    clientId: effectiveClientId,
                    modeleId: Value(effectiveModeleId),
                    title: d.$2,
                    fabric: Value(d.$3),
                    price: d.$4,
                    deliveryDate: deliveryDate,
                    fittingDate: Value(fittingDate),
                    status: Value(d.$6),
                    deliveredAt: Value(deliveredAt),
                    photoPath: Value(photoPath),
                    photoUploadState: const Value('none'),
                    createdAt: createdAt,
                    updatedAt: createdAt,
                  ),
                );

            // 5.2 Insertion photo dans order_photos
            await db.into(db.orderPhotos).insert(
                  OrderPhotosCompanion.insert(
                    id: 'op$i',
                    orderId: orderId,
                    photoPath: photoPath,
                    position: const Value(0),
                    photoUploadState: const Value('none'),
                    createdAt: createdAt,
                    updatedAt: createdAt,
                  ),
                );

            // 5.3 Insertion des versements démo
            final paid = d.$7;
            final price = d.$4;
            if (paid >= 50000) {
              final first = (paid * .6 / 5000).round() * 5000;
              await db.into(db.clientPayments).insert(
                    ClientPaymentsCompanion.insert(
                      id: 'p${i}a',
                      orderId: orderId,
                      amount: first,
                      paidAt: day(-(6 + i)),
                      receiptNumber: receiptNo++,
                      orderPriceAtPayment: price,
                      balanceAfter: price - first,
                      note: const Value('Acompte'),
                      createdAt: day(-(6 + i)),
                      updatedAt: day(-(6 + i)),
                    ),
                  );
              await db.into(db.clientPayments).insert(
                    ClientPaymentsCompanion.insert(
                      id: 'p${i}b',
                      orderId: orderId,
                      amount: paid - first,
                      paidAt: day(-(i % 4)),
                      receiptNumber: receiptNo++,
                      orderPriceAtPayment: price,
                      balanceAfter: price - paid,
                      note: const Value('Complément'),
                      createdAt: day(-(i % 4)),
                      updatedAt: day(-(i % 4)),
                    ),
                  );
            } else if (paid > 0) {
              await db.into(db.clientPayments).insert(
                    ClientPaymentsCompanion.insert(
                      id: 'p${i}a',
                      orderId: orderId,
                      amount: paid,
                      paidAt: day(-(i % 9)),
                      receiptNumber: receiptNo++,
                      orderPriceAtPayment: price,
                      balanceAfter: price - paid,
                      note: const Value('Acompte'),
                      createdAt: day(-(i % 9)),
                      updatedAt: day(-(i % 9)),
                    ),
                  );
            }
          }

          // 5.4 Mise à jour du compteur de reçus clients
          final maxClientReceipt = receiptNo - 1;
          await db.into(db.receiptCounters).insertOnConflictUpdate(
                ReceiptCountersCompanion.insert(
                  counterName: 'clients',
                  lastValue: Value(maxClientReceipt),
                  updatedAt: now,
                ),
              );
        }

        // 5.5 Marquer la démo orders comme seedée
        await db.into(db.syncState).insertOnConflictUpdate(
              SyncStateCompanion.insert(
                key: 'demo_seeded:orders',
                value: '1',
                updatedAt: now,
              ),
            );
      });
      didSeed = true;
    }

    // =========================================================================
    // 6. APPRENTIS ET VERSEMENTS D'ÉCOLAGE
    // =========================================================================
    final seededApprentices = await (db.select(db.syncState)
          ..where((t) => t.key.equals('demo_seeded:apprentices')))
        .getSingleOrNull();

    if (seededApprentices == null) {
      await db.transaction(() async {
        final apprenticesCount = await db.apprentices.count().getSingle();
        if (apprenticesCount == 0) {
          // 6.1 Insertion des 3 apprentis démo
          final apprenticeDefs = [
            ('a0', 'Kafui Amedome', '90 22 41 18', day(-120), 150000, day(4)),
            ('a1', 'Mawuli Sodji', '91 08 77 30', day(-200), 120000, day(-2)),
            ('a2', 'Essi Gbadoe', '93 61 09 52', day(-300), 150000, null),
          ];

          for (final def in apprenticeDefs) {
            await db.into(db.apprentices).insert(
                  ApprenticesCompanion.insert(
                    id: def.$1,
                    name: def.$2,
                    phone: Value(def.$3),
                    startDate: def.$4,
                    totalFee: def.$5,
                    nextDue: Value(def.$6),
                    notes: const Value(''),
                    createdAt: def.$4,
                    updatedAt: def.$4,
                  ),
                );
          }

          // 6.2 Insertion des 5 versements d'écolage
          final paymentDefs = [
            ('ap0', 'a0', 50000, day(-60), 1, 150000, 100000, ''),
            ('ap1', 'a0', 30000, day(-5), 2, 150000, 70000, 'Mensualité'),
            ('ap2', 'a1', 60000, day(-40), 3, 120000, 60000, ''),
            ('ap3', 'a2', 100000, day(-200), 4, 150000, 50000, ''),
            ('ap4', 'a2', 50000, day(-40), 5, 150000, 0, ''),
          ];

          for (final p in paymentDefs) {
            await db.into(db.apprenticePayments).insert(
                  ApprenticePaymentsCompanion.insert(
                    id: p.$1,
                    apprenticeId: p.$2,
                    amount: p.$3,
                    paidAt: p.$4,
                    receiptNumber: p.$5,
                    totalFeeAtPayment: p.$6,
                    balanceAfter: p.$7,
                    note: Value(p.$8),
                    createdAt: p.$4,
                    updatedAt: p.$4,
                  ),
                );
          }

          // 6.3 Mise à jour du compteur de reçus apprentis
          await db.into(db.receiptCounters).insertOnConflictUpdate(
                ReceiptCountersCompanion.insert(
                  counterName: 'apprentices',
                  lastValue: const Value(5),
                  updatedAt: now,
                ),
              );
        }

        // 6.4 Marquer la démo apprentices comme seedée
        await db.into(db.syncState).insertOnConflictUpdate(
              SyncStateCompanion.insert(
                key: 'demo_seeded:apprentices',
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
