import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:angela_dress/data/db/app_database.dart' as db_layer;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/db/demo_seeder.dart';
import 'package:angela_dress/data/repositories/finance_repository.dart';
import 'package:angela_dress/data/store.dart';

class TestClock implements Clock {
  TestClock(this.currentTime);
  DateTime currentTime;

  @override
  DateTime now() => currentTime;
}

void main() {
  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await initializeDateFormatting('fr_FR', null);
  });

  group('Tranche 5B - Finances et Ponctualité (FinanceRepository & Drift)', () {
    late db_layer.AppDatabase db;
    late TestClock clock;
    late DriftFinanceRepository financeRepo;

    setUp(() async {
      db = db_layer.AppDatabase(NativeDatabase.memory());
      clock = TestClock(DateTime.utc(2026, 11, 15, 10, 0));
      financeRepo = DriftFinanceRepository(db: db, clock: clock);
    });

    tearDown(() async {
      await db.close();
    });

    test('1. Chaque agrégat comparé à une valeur calculée à la main sur un jeu contrôlé', () async {
      final now = clock.now();

      // Clients
      await db.into(db.clients).insert(db_layer.ClientsCompanion.insert(
            id: 'c1',
            name: 'Client 1',
            createdAt: now,
            updatedAt: now,
          ));

      // Commandes :
      // o1: prix 50 000, versement 20 000 -> reste 30 000
      // o2: prix 30 000, versement 30 000 -> reste 0
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o1',
            clientId: 'c1',
            title: 'Robe 1',
            price: 50000,
            deliveryDate: DateTime.utc(2026, 11, 20),
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o2',
            clientId: 'c1',
            title: 'Robe 2',
            price: 30000,
            deliveryDate: DateTime.utc(2026, 11, 25),
            createdAt: now,
            updatedAt: now,
          ));

      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p1',
            orderId: 'o1',
            amount: 20000,
            paidAt: now,
            receiptNumber: 1,
            orderPriceAtPayment: 50000,
            balanceAfter: 30000,
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p2',
            orderId: 'o2',
            amount: 30000,
            paidAt: now,
            receiptNumber: 2,
            orderPriceAtPayment: 30000,
            balanceAfter: 0,
            createdAt: now,
            updatedAt: now,
          ));

      // Apprentis :
      // a1: frais 100 000, versement 40 000 -> reste 60 000
      // a2: frais 50 000, versement 0 -> reste 50 000
      await db.into(db.apprentices).insert(db_layer.ApprenticesCompanion.insert(
            id: 'a1',
            name: 'Apprenti 1',
            startDate: now,
            totalFee: 100000,
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.apprentices).insert(db_layer.ApprenticesCompanion.insert(
            id: 'a2',
            name: 'Apprenti 2',
            startDate: now,
            totalFee: 50000,
            createdAt: now,
            updatedAt: now,
          ));

      await db.into(db.apprenticePayments).insert(db_layer.ApprenticePaymentsCompanion.insert(
            id: 'ap1',
            apprenticeId: 'a1',
            amount: 40000,
            paidAt: now,
            receiptNumber: 1,
            totalFeeAtPayment: 100000,
            balanceAfter: 60000,
            createdAt: now,
            updatedAt: now,
          ));

      final summary = await financeRepo.getSummary();

      // Recouvrement clients = 30 000 + 0 = 30 000
      expect(summary.totalClientRemaining, 30000);

      // Recouvrement apprentis = 60 000 + 50 000 = 110 000
      expect(summary.totalApprenticeRemaining, 110000);

      // Encaissements mois courant = 20 000 + 30 000 (clients) + 40 000 (apprentis) = 90 000
      expect(summary.monthTotal, 90000);

      // Dernière barre du graphique des 6 mois = mois courant = 90 000
      expect(summary.last6Months.last.total, 90000);
    });

    test('2. Annuler un versement du mois précédent modifie ce mois-là et pas le mois courant', () async {
      final now = clock.now();
      final prevMonthDate = DateTime.utc(2026, 10, 15, 12, 0);

      // Client & Commande
      await db.into(db.clients).insert(db_layer.ClientsCompanion.insert(
            id: 'c1',
            name: 'Client Octobre',
            createdAt: prevMonthDate,
            updatedAt: prevMonthDate,
          ));
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_oct',
            clientId: 'c1',
            title: 'Commande Octobre',
            price: 60000,
            deliveryDate: DateTime.utc(2026, 11, 20),
            createdAt: prevMonthDate,
            updatedAt: prevMonthDate,
          ));

      // Versement en Octobre (30 000)
      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_oct',
            orderId: 'o_oct',
            amount: 30000,
            paidAt: prevMonthDate,
            receiptNumber: 1,
            orderPriceAtPayment: 60000,
            balanceAfter: 30000,
            createdAt: prevMonthDate,
            updatedAt: prevMonthDate,
          ));

      // Versement en Novembre (20 000)
      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_nov',
            orderId: 'o_oct',
            amount: 20000,
            paidAt: now,
            receiptNumber: 2,
            orderPriceAtPayment: 60000,
            balanceAfter: 10000,
            createdAt: now,
            updatedAt: now,
          ));

      final octStart = DateTime(2026, 10, 1);
      final novStart = DateTime(2026, 11, 1);
      final decStart = DateTime(2026, 12, 1);

      expect(await financeRepo.getMonthCashFlow(octStart, novStart), 30000);
      expect(await financeRepo.getMonthCashFlow(novStart, decStart), 20000);

      // Annuler le versement d'octobre pendant le mois de novembre
      await (db.update(db.clientPayments)..where((t) => t.id.equals('p_oct'))).write(
        db_layer.ClientPaymentsCompanion(
          voidedAt: Value(now),
          voidReason: const Value('Erreur'),
          updatedAt: Value(now),
        ),
      );

      // Le total d'octobre est maintenant 0, celui de novembre reste 20 000
      expect(await financeRepo.getMonthCashFlow(octStart, novStart), 0);
      expect(await financeRepo.getMonthCashFlow(novStart, decStart), 20000);
    });

    test('3. Bornes de mois en heure locale (dernier jour 23:59 vs 1er jour 00:00)', () async {
      final now = clock.now().toLocal();
      final prevMonthStartLocal = DateTime(now.year, now.month - 1, 1);
      final currentMonthStartLocal = DateTime(now.year, now.month, 1);
      final nextMonthStartLocal = DateTime(now.year, now.month + 1, 1);

      // Dernier jour du mois précédent à 23:59:59 heure locale
      final lastSecPrevLocal = DateTime(now.year, now.month, 0, 23, 59, 59);
      final lastSecPrevUtc = lastSecPrevLocal.toUtc();

      // 1er jour du mois courant à 00:00:00 heure locale
      final firstSecCurrentLocal = DateTime(now.year, now.month, 1, 0, 0, 0);
      final firstSecCurrentUtc = firstSecCurrentLocal.toUtc();

      await db.into(db.clients).insert(db_layer.ClientsCompanion.insert(
            id: 'c_bounds',
            name: 'Client Bornes',
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ));
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_bounds',
            clientId: 'c_bounds',
            title: 'Test Bornes',
            price: 100000,
            deliveryDate: DateTime.utc(now.year, now.month, 20),
            createdAt: clock.now(),
            updatedAt: clock.now(),
          ));

      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_last_prev',
            orderId: 'o_bounds',
            amount: 15000,
            paidAt: lastSecPrevUtc,
            receiptNumber: 10,
            orderPriceAtPayment: 100000,
            balanceAfter: 85000,
            createdAt: lastSecPrevUtc,
            updatedAt: lastSecPrevUtc,
          ));

      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_first_curr',
            orderId: 'o_bounds',
            amount: 25000,
            paidAt: firstSecCurrentUtc,
            receiptNumber: 11,
            orderPriceAtPayment: 100000,
            balanceAfter: 60000,
            createdAt: firstSecCurrentUtc,
            updatedAt: firstSecCurrentUtc,
          ));

      // 15 000 tombe dans le mois précédent, 25 000 tombe dans le mois courant
      expect(await financeRepo.getMonthCashFlow(prevMonthStartLocal, currentMonthStartLocal), 15000);
      expect(await financeRepo.getMonthCashFlow(currentMonthStartLocal, nextMonthStartLocal), 25000);
    });

    test('4. Mois vides = 0 et fenêtre de 6 mois à cheval sur deux années (au 15 février)', () async {
      final febClock = TestClock(DateTime.utc(2027, 2, 15, 12, 0));
      final repo = DriftFinanceRepository(db: db, clock: febClock);

      // Les 6 mois au 15 février 2027 sont : Sept 2026, Oct 2026, Nov 2026, Déc 2026, Janv 2027, Févr 2027
      final last6 = await repo.getLast6MonthsCashFlow();
      expect(last6.length, 6);
      expect(last6.first.monthStartLocal.year, 2026);
      expect(last6.first.monthStartLocal.month, 9); // Septembre 2026
      expect(last6.last.monthStartLocal.year, 2027);
      expect(last6.last.monthStartLocal.month, 2); // Février 2027

      // Tous les mois sans versement valent 0
      for (final m in last6) {
        expect(m.total, 0);
      }

      // Insérer un versement en Décembre 2026 (index 3) et un en Février 2027 (index 5)
      await db.into(db.clients).insert(db_layer.ClientsCompanion.insert(
            id: 'c_year',
            name: 'Client Multi-Année',
            createdAt: febClock.now(),
            updatedAt: febClock.now(),
          ));
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_year',
            clientId: 'c_year',
            title: 'Robe Réveillon',
            price: 80000,
            deliveryDate: DateTime.utc(2026, 12, 31),
            createdAt: febClock.now(),
            updatedAt: febClock.now(),
          ));

      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_dec',
            orderId: 'o_year',
            amount: 50000,
            paidAt: DateTime.utc(2026, 12, 24, 15, 0),
            receiptNumber: 101,
            orderPriceAtPayment: 80000,
            balanceAfter: 30000,
            createdAt: DateTime.utc(2026, 12, 24),
            updatedAt: DateTime.utc(2026, 12, 24),
          ));

      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_feb',
            orderId: 'o_year',
            amount: 30000,
            paidAt: DateTime.utc(2027, 2, 10, 10, 0),
            receiptNumber: 102,
            orderPriceAtPayment: 80000,
            balanceAfter: 0,
            createdAt: DateTime.utc(2027, 2, 10),
            updatedAt: DateTime.utc(2027, 2, 10),
          ));

      final updated6 = await repo.getLast6MonthsCashFlow();
      expect(updated6[3].total, 50000); // Décembre 2026
      expect(updated6[4].total, 0);     // Janvier 2027 (vide)
      expect(updated6[5].total, 30000); // Février 2027
    });

    test('5. Taux de ponctualité : à temps, en retard, hors fenêtre 90j, null exclu, zéro commande', () async {
      // 5.1 Zéro commande livrée -> rate == null (évite division par zéro)
      var stats = await financeRepo.getPunctualityStats();
      expect(stats.totalCount, 0);
      expect(stats.rate, isNull);

      final now = clock.now();

      await db.into(db.clients).insert(db_layer.ClientsCompanion.insert(
            id: 'c_ponct',
            name: 'Client Ponctualité',
            createdAt: now,
            updatedAt: now,
          ));

      // o_ontime: promis le 10 nov, livré le 10 nov à 23:30 local (à temps)
      final ontimeLocal = DateTime(2026, 11, 10, 23, 30);
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_ontime',
            clientId: 'c_ponct',
            title: 'À temps',
            price: 20000,
            deliveryDate: DateTime.utc(2026, 11, 10),
            status: const Value('livree'),
            deliveredAt: Value(ontimeLocal.toUtc()),
            createdAt: now,
            updatedAt: now,
          ));

      // o_late: promis le 10 nov, livré le 11 nov à 00:10 local (en retard)
      final lateLocal = DateTime(2026, 11, 11, 0, 10);
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_late',
            clientId: 'c_ponct',
            title: 'En retard',
            price: 25000,
            deliveryDate: DateTime.utc(2026, 11, 10),
            status: const Value('livree'),
            deliveredAt: Value(lateLocal.toUtc()),
            createdAt: now,
            updatedAt: now,
          ));

      // o_old: promis il y a 95 jours, livré il y a 95 jours (hors fenêtre 90j) -> exclu
      final oldDate = now.subtract(const Duration(days: 95));
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_old',
            clientId: 'c_ponct',
            title: 'Hors 90j',
            price: 40000,
            deliveryDate: oldDate,
            status: const Value('livree'),
            deliveredAt: Value(oldDate),
            createdAt: oldDate,
            updatedAt: oldDate,
          ));

      // o_null: statut livree mais delivered_at = null -> exclu
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_null',
            clientId: 'c_ponct',
            title: 'Sans delivered_at',
            price: 30000,
            deliveryDate: DateTime.utc(2026, 11, 12),
            status: const Value('livree'),
            deliveredAt: const Value(null),
            createdAt: now,
            updatedAt: now,
          ));

      // o_deleted: livree à temps mais supprimée logiquement -> exclue
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_deleted',
            clientId: 'c_ponct',
            title: 'Supprimée',
            price: 15000,
            deliveryDate: DateTime.utc(2026, 11, 10),
            status: const Value('livree'),
            deliveredAt: Value(DateTime.utc(2026, 11, 10, 12, 0)),
            deletedAt: Value(now),
            createdAt: now,
            updatedAt: now,
          ));

      stats = await financeRepo.getPunctualityStats();
      // Total pris en compte : 2 commandes (o_ontime et o_late)
      expect(stats.totalCount, 2);
      expect(stats.onTimeCount, 1);
      expect(stats.rate, 0.5);
    });

    test('6. Jointure LEFT OUTER JOIN : commande sans versement et commande annulée comptent dans le recouvrement', () async {
      final now = clock.now();
      await db.into(db.clients).insert(db_layer.ClientsCompanion.insert(
            id: 'c_join',
            name: 'Client Jointure',
            createdAt: now,
            updatedAt: now,
          ));

      // Commande sans aucun versement : prix = 45 000 -> reste 45 000
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_nopay',
            clientId: 'c_join',
            title: 'Sans versement',
            price: 45000,
            deliveryDate: DateTime.utc(2026, 11, 25),
            createdAt: now,
            updatedAt: now,
          ));

      // Commande avec versement totalement annulé : prix = 35 000 -> reste 35 000
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_voided',
            clientId: 'c_join',
            title: 'Versement annulé',
            price: 35000,
            deliveryDate: DateTime.utc(2026, 11, 28),
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_void',
            orderId: 'o_voided',
            amount: 35000,
            paidAt: now,
            receiptNumber: 99,
            orderPriceAtPayment: 35000,
            balanceAfter: 0,
            voidedAt: Value(now),
            voidReason: const Value('Chèque rejeté'),
            createdAt: now,
            updatedAt: now,
          ));

      final remaining = await financeRepo.getTotalClientRemaining();
      expect(remaining, 80000, reason: '45000 + 35000 = 80000');
    });

    test('7. Cohérence recouvrement SQL vs accesseur central (sur DemoSeeder et jeu aléatoire fixe)', () async {
      // 7.1 Sur le jeu DemoSeeder
      final seeder = DemoSeeder(db);
      await seeder.seedIfNecessary(isDebug: true);

      final store = AppStore(db: db);
      await store.init();

      final sqlClientRemaining = await financeRepo.getTotalClientRemaining();
      final storeClientRemaining = store.orders.fold<int>(0, (s, o) => s + store.remainingOf(o));
      expect(sqlClientRemaining, storeClientRemaining);

      final sqlAppRemaining = await financeRepo.getTotalApprenticeRemaining();
      final storeAppRemaining = store.apprentices.fold<int>(0, (s, a) => s + store.apprenticeRemaining(a));
      expect(sqlAppRemaining, storeAppRemaining);
      store.dispose();

      // 7.2 Sur un jeu aléatoire à graine fixe
      final rng = Random(42);
      for (var i = 0; i < 10; i++) {
        final price = 10000 + rng.nextInt(90) * 1000;
        final oId = 'rnd_o_$i';
        await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
              id: oId,
              clientId: 'c0',
              title: 'Order $i',
              price: price,
              deliveryDate: DateTime.utc(2026, 12, 1),
              createdAt: clock.now(),
              updatedAt: clock.now(),
            ));

        final payCount = rng.nextInt(3);
        var currentPaid = 0;
        for (var p = 0; p < payCount; p++) {
          final amt = (price - currentPaid > 0) ? (rng.nextInt(price - currentPaid) ~/ 1000) * 1000 : 0;
          if (amt > 0) {
            currentPaid += amt;
            final isVoided = rng.nextBool() && rng.nextBool(); // 25% voided
            await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
                  id: 'rnd_p_${i}_$p',
                  orderId: oId,
                  amount: amt,
                  paidAt: clock.now(),
                  receiptNumber: 1000 + i * 10 + p,
                  orderPriceAtPayment: price,
                  balanceAfter: price - currentPaid,
                  voidedAt: isVoided ? Value(clock.now()) : const Value(null),
                  voidReason: isVoided ? const Value('Test void') : const Value(null),
                  createdAt: clock.now(),
                  updatedAt: clock.now(),
                ));
          }
        }
      }

      final appStoreUpdated = AppStore(db: db);
      await appStoreUpdated.init();

      final sqlClient2 = await financeRepo.getTotalClientRemaining();
      final storeClient2 = appStoreUpdated.orders.fold<int>(0, (s, o) => s + appStoreUpdated.remainingOf(o));
      expect(sqlClient2, storeClient2);
      appStoreUpdated.dispose();
    });

    test('8. Réactivité : écrire un versement met à jour la valeur émise par le stream', () async {
      final now = clock.now();
      await db.into(db.clients).insert(db_layer.ClientsCompanion.insert(
            id: 'c_react',
            name: 'Client React',
            createdAt: now,
            updatedAt: now,
          ));
      await db.into(db.orders).insert(db_layer.OrdersCompanion.insert(
            id: 'o_react',
            clientId: 'c_react',
            title: 'Robe Réactive',
            price: 50000,
            deliveryDate: DateTime.utc(2026, 11, 20),
            createdAt: now,
            updatedAt: now,
          ));

      final stream = financeRepo.watchSummary();
      final emittedValues = <int>[];

      final sub = stream.listen((summary) {
        emittedValues.add(summary.monthTotal);
      });

      // Laisser le temps à Drift d émettre le premier yield
      await Future.delayed(const Duration(milliseconds: 100));
      expect(emittedValues, isNotEmpty);
      expect(emittedValues.first, 0);

      // Ajouter un versement
      await db.into(db.clientPayments).insert(db_layer.ClientPaymentsCompanion.insert(
            id: 'p_react_1',
            orderId: 'o_react',
            amount: 25000,
            paidAt: now,
            receiptNumber: 501,
            orderPriceAtPayment: 50000,
            balanceAfter: 25000,
            createdAt: now,
            updatedAt: now,
          ));

      // Laisser le temps à Drift de propager la notification de mise à jour de table
      await Future.delayed(const Duration(milliseconds: 150));
      expect(emittedValues.last, 25000);

      await sub.cancel();
    });
  });
}
