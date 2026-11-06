import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/services/alert_engine.dart';

void main() {
  group('AlertEngine - Règles, Clés & Sévérité', () {
    const engine = AlertEngine();
    final fixedNow = DateTime(2026, 11, 6, 10, 0); // Vendredi 6 nov 2026 10:00

    test('Livraison : en retard, aujourd\'hui, demain, dans 2 jours, au-delà', () {
      final client = Client(id: 'c1', name: 'Amina Diallo', phone: '+22890010203');
      final clients = {'c1': client};

      final orderLate = Order(
        id: 'ord-late',
        clientId: 'c1',
        title: 'Robe Wax',
        price: 25000,
        deliveryDate: DateTime(2026, 11, 4), // il y a 2 jours
        createdAt: DateTime(2026, 10, 20),
      );

      final orderToday = Order(
        id: 'ord-today',
        clientId: 'c1',
        title: 'Boubou Bazin',
        price: 30000,
        deliveryDate: DateTime(2026, 11, 6), // aujourd'hui
        createdAt: DateTime(2026, 10, 20),
      );

      final orderTomorrow = Order(
        id: 'ord-tomorrow',
        clientId: 'c1',
        title: 'Jupe Pagne',
        price: 15000,
        deliveryDate: DateTime(2026, 11, 7), // demain
        createdAt: DateTime(2026, 10, 20),
      );

      final orderIn2Days = Order(
        id: 'ord-in2days',
        clientId: 'c1',
        title: 'Ensemble Soie',
        price: 40000,
        deliveryDate: DateTime(2026, 11, 8), // dans 2 jours
        createdAt: DateTime(2026, 10, 20),
      );

      final orderFar = Order(
        id: 'ord-far',
        clientId: 'c1',
        title: 'Costume 3 pièces',
        price: 60000,
        deliveryDate: DateTime(2026, 11, 20), // loin
        createdAt: DateTime(2026, 10, 20),
      );

      final alerts = engine.currentAlerts(
        now: fixedNow,
        orders: [orderLate, orderToday, orderTomorrow, orderIn2Days, orderFar],
        apprentices: [],
        clientById: (id) => clients[id],
        remainingOfOrder: (_) => 10000,
        remainingOfApprentice: (_) => 0,
      );

      expect(alerts.any((a) => a.key == 'livraison:retard:ord-late:2026-11-04'), isTrue);
      expect(alerts.any((a) => a.key == 'livraison:aujourdhui:ord-today:2026-11-06'), isTrue);
      expect(alerts.any((a) => a.key == 'livraison:demain:ord-tomorrow:2026-11-07'), isTrue);
      expect(alerts.any((a) => a.key == 'livraison:dans_2_jours:ord-in2days:2026-11-08'), isTrue);
      // Au-delà de 2 jours : pas d'alerte de livraison
      expect(alerts.any((a) => a.targetId == 'ord-far'), isFalse);

      // Vérification que le corps ne contient AUCUN montant
      for (final a in alerts) {
        expect(a.body, contains('Amina Diallo'));
        expect(a.body, isNot(contains('10 000')));
        expect(a.body, isNot(contains('F')));
      }
    });

    test('Essayage : aujourd\'hui (avec ou sans heure) et demain', () {
      final client = Client(id: 'c1', name: 'Fatou Traoré', phone: '+22890112233');
      final clients = {'c1': client};

      final orderFittingTodayTime = Order(
        id: 'ord-fit-today-time',
        clientId: 'c1',
        title: 'Robe Mariée',
        price: 50000,
        deliveryDate: DateTime(2026, 11, 15),
        fittingDate: DateTime(2026, 11, 6, 15, 30), // aujourd'hui à 15h30
        createdAt: DateTime(2026, 10, 20),
      );

      final orderFittingTodayNoTime = Order(
        id: 'ord-fit-today-notime',
        clientId: 'c1',
        title: 'Tunique',
        price: 20000,
        deliveryDate: DateTime(2026, 11, 15),
        fittingDate: DateTime(2026, 11, 6, 0, 0), // aujourd'hui sans heure
        createdAt: DateTime(2026, 10, 20),
      );

      final orderFittingTomorrow = Order(
        id: 'ord-fit-tomorrow',
        clientId: 'c1',
        title: 'Robe Soirée',
        price: 35000,
        deliveryDate: DateTime(2026, 11, 15),
        fittingDate: DateTime(2026, 11, 7, 10, 0), // demain à 10h00
        createdAt: DateTime(2026, 10, 20),
      );

      final alerts = engine.currentAlerts(
        now: fixedNow,
        orders: [orderFittingTodayTime, orderFittingTodayNoTime, orderFittingTomorrow],
        apprentices: [],
        clientById: (id) => clients[id],
        remainingOfOrder: (_) => 0,
        remainingOfApprentice: (_) => 0,
      );

      final a1 = alerts.firstWhere((a) => a.key == 'essayage:aujourdhui:ord-fit-today-time:2026-11-06');
      expect(a1.title, equals('Essayage aujourd\'hui à 15h30'));

      final a2 = alerts.firstWhere((a) => a.key == 'essayage:aujourdhui:ord-fit-today-notime:2026-11-06');
      expect(a2.title, equals('Essayage aujourd\'hui'));

      final a3 = alerts.firstWhere((a) => a.key == 'essayage:demain:ord-fit-tomorrow:2026-11-07');
      expect(a3.title, equals('Essayage demain à 10h00'));
    });

    test('Échéances d\'apprentis : dépassée, aujourd\'hui, demain, approche (<= 7j), soldé exclu', () {
      final appOverdue = Apprentice(
        id: 'app-1',
        name: 'Koffi Mensah',
        phone: '+22891223344',
        startDate: DateTime(2026, 1, 1),
        totalFee: 100000,
        nextDue: DateTime(2026, 11, 3), // il y a 3 jours
      );

      final appToday = Apprentice(
        id: 'app-2',
        name: 'Akua Sena',
        phone: '+22891334455',
        startDate: DateTime(2026, 1, 1),
        totalFee: 100000,
        nextDue: DateTime(2026, 11, 6), // aujourd'hui
      );

      final appTomorrow = Apprentice(
        id: 'app-3',
        name: 'Yawo Agbé',
        phone: '+22891445566',
        startDate: DateTime(2026, 1, 1),
        totalFee: 100000,
        nextDue: DateTime(2026, 11, 7), // demain
      );

      final appIn5Days = Apprentice(
        id: 'app-4',
        name: 'Sika Dossou',
        phone: '+22891556677',
        startDate: DateTime(2026, 1, 1),
        totalFee: 100000,
        nextDue: DateTime(2026, 11, 11), // dans 5 jours
      );

      final appPaidInFull = Apprentice(
        id: 'app-paid',
        name: 'Foli Paul',
        phone: '+22891667788',
        startDate: DateTime(2026, 1, 1),
        totalFee: 100000,
        nextDue: DateTime(2026, 11, 6), // aujourd'hui mais soldé
      );

      final alerts = engine.currentAlerts(
        now: fixedNow,
        orders: [],
        apprentices: [appOverdue, appToday, appTomorrow, appIn5Days, appPaidInFull],
        clientById: (_) => null,
        remainingOfOrder: (_) => 0,
        remainingOfApprentice: (a) => a.id == 'app-paid' ? 0 : 25000,
      );

      expect(alerts.any((a) => a.key == 'echeance_apprenti:retard:app-1:2026-11-03'), isTrue);
      expect(alerts.any((a) => a.key == 'echeance_apprenti:aujourdhui:app-2:2026-11-06'), isTrue);
      expect(alerts.any((a) => a.key == 'echeance_apprenti:demain:app-3:2026-11-07'), isTrue);
      expect(alerts.any((a) => a.key == 'echeance_apprenti:dans_5_jours:app-4:2026-11-11'), isTrue);
      expect(alerts.any((a) => a.targetId == 'app-paid'), isFalse); // exclu car soldé
    });

    test('Exclusion commande livrée et commande avec solde 0', () {
      final client = Client(id: 'c1', name: 'Amina', phone: '+22890010203');

      final orderDelivered = Order(
        id: 'ord-deliv',
        clientId: 'c1',
        title: 'Robe Livrée',
        price: 25000,
        deliveryDate: DateTime(2026, 11, 6),
        status: OrderStatus.livree,
        createdAt: DateTime(2026, 10, 20),
      );

      final orderReadyZeroBalance = Order(
        id: 'ord-ready-0',
        clientId: 'c1',
        title: 'Robe Prête Payée',
        price: 25000,
        deliveryDate: DateTime(2026, 11, 20),
        status: OrderStatus.prete,
        createdAt: DateTime(2026, 10, 20),
      );

      final alerts = engine.currentAlerts(
        now: fixedNow,
        orders: [orderDelivered, orderReadyZeroBalance],
        apprentices: [],
        clientById: (_) => client,
        remainingOfOrder: (o) => o.id == 'ord-ready-0' ? 0 : 5000,
        remainingOfApprentice: (_) => 0,
      );

      expect(alerts, isEmpty);
    });

    test('Une alerte "demain" devient "aujourd\'hui" le jour suivant avec une clé différente', () {
      final client = Client(id: 'c1', name: 'Amina Diallo');
      final targetDate = DateTime(2026, 11, 7);

      final order = Order(
        id: 'ord-transition',
        clientId: 'c1',
        title: 'Robe Soirée',
        price: 30000,
        deliveryDate: targetDate,
        createdAt: DateTime(2026, 10, 20),
      );

      // Évaluation la veille (6 nov)
      final alertsDay6 = engine.currentAlerts(
        now: DateTime(2026, 11, 6, 14, 0),
        orders: [order],
        apprentices: [],
        clientById: (_) => client,
        remainingOfOrder: (_) => 5000,
        remainingOfApprentice: (_) => 0,
      );

      final tomorrowAlert = alertsDay6.firstWhere((a) => a.targetId == 'ord-transition');
      expect(tomorrowAlert.key, equals('livraison:demain:ord-transition:2026-11-07'));
      expect(tomorrowAlert.stage, equals(AlertStage.tomorrow));

      // Évaluation le jour même (7 nov)
      final alertsDay7 = engine.currentAlerts(
        now: DateTime(2026, 11, 7, 09, 0),
        orders: [order],
        apprentices: [],
        clientById: (_) => client,
        remainingOfOrder: (_) => 5000,
        remainingOfApprentice: (_) => 0,
      );

      final todayAlert = alertsDay7.firstWhere((a) => a.targetId == 'ord-transition');
      expect(todayAlert.key, equals('livraison:aujourdhui:ord-transition:2026-11-07'));
      expect(todayAlert.stage, equals(AlertStage.today));

      // La clé a bien changé lors du passage de l'étape
      expect(tomorrowAlert.key, isNot(equals(todayAlert.key)));
    });

    test('Tri strict par sévérité : late < today < tomorrow < upcoming < info', () {
      final client = Client(id: 'c1', name: 'Client Test');

      final orderLate = Order(
        id: 'ord-late',
        clientId: 'c1',
        title: 'En retard',
        price: 10000,
        deliveryDate: DateTime(2026, 11, 4),
        createdAt: DateTime(2026, 10, 1),
      );

      final orderToday = Order(
        id: 'ord-today',
        clientId: 'c1',
        title: 'Aujourd\'hui',
        price: 10000,
        deliveryDate: DateTime(2026, 11, 6),
        createdAt: DateTime(2026, 10, 1),
      );

      final orderTomorrow = Order(
        id: 'ord-tomorrow',
        clientId: 'c1',
        title: 'Demain',
        price: 10000,
        deliveryDate: DateTime(2026, 11, 7),
        createdAt: DateTime(2026, 10, 1),
      );

      final orderReadyWithBalance = Order(
        id: 'ord-ready',
        clientId: 'c1',
        title: 'Prête solde',
        price: 10000,
        deliveryDate: DateTime(2026, 11, 20),
        status: OrderStatus.prete,
        createdAt: DateTime(2026, 10, 1),
      );

      final alerts = engine.currentAlerts(
        now: fixedNow,
        orders: [orderTomorrow, orderReadyWithBalance, orderToday, orderLate],
        apprentices: [],
        clientById: (_) => client,
        remainingOfOrder: (_) => 5000,
        remainingOfApprentice: (_) => 0,
      );

      expect(alerts[0].severity, equals(AlertSeverity.late));
      expect(alerts[1].severity, equals(AlertSeverity.today));
      expect(alerts[2].severity, equals(AlertSeverity.tomorrow));
      expect(alerts[3].severity, equals(AlertSeverity.info));
    });
  });

  group('Invariant Décision 7 (Rappels planifiés T -> currentAlerts(T))', () {
    const engine = AlertEngine();
    final client = Client(id: 'c1', name: 'Amina', phone: '+22890000000');
    final clients = {'c1': client};

    test('Invariant vérifié sur un ensemble déterministe de commandes et apprentis', () {
      final now = DateTime(2026, 11, 6, 8, 0);

      final orders = [
        Order(
          id: 'ord-1',
          clientId: 'c1',
          title: 'Robe A',
          price: 20000,
          deliveryDate: DateTime(2026, 11, 8),
          fittingDate: DateTime(2026, 11, 7, 16, 0),
          createdAt: DateTime(2026, 11, 1),
        ),
        Order(
          id: 'ord-2',
          clientId: 'c1',
          title: 'Boubou B',
          price: 35000,
          deliveryDate: DateTime(2026, 11, 10),
          fittingDate: DateTime(2026, 11, 9, 0, 0),
          createdAt: DateTime(2026, 11, 1),
        ),
      ];

      final apprentices = [
        Apprentice(
          id: 'app-1',
          name: 'Kodjo',
          startDate: DateTime(2026, 1, 1),
          totalFee: 50000,
          nextDue: DateTime(2026, 11, 12),
        ),
      ];

      final planned = engine.plannedReminders(
        now: now,
        orders: orders,
        apprentices: apprentices,
        clientById: (id) => clients[id],
        remainingOfOrder: (_) => 10000,
        remainingOfApprentice: (_) => 20000,
      );

      expect(planned, isNotEmpty);

      // Invariant : pour chaque rappel planifié à l'instant T,
      // currentAlerts évalué avec l'horloge à T contient l'alerte correspondante (par clé ou cible+étape).
      for (final reminder in planned) {
        final alertsAtT = engine.currentAlerts(
          now: reminder.scheduledAt,
          orders: orders,
          apprentices: apprentices,
          clientById: (id) => clients[id],
          remainingOfOrder: (_) => 10000,
          remainingOfApprentice: (_) => 20000,
        );

        final match = alertsAtT.any((a) => a.key == reminder.alertKey);
        expect(match, isTrue,
            reason: 'Alerte ${reminder.alertKey} introuvable à l\'instant ${reminder.scheduledAt}');
      }
    });

    test('Invariant vérifié sur un jeu aléatoire à graine fixe (100 entités)', () {
      final rng = Random(42);
      final baseNow = DateTime(2026, 11, 6, 9, 0);

      final randomOrders = <Order>[];
      final randomApps = <Apprentice>[];

      for (var i = 0; i < 50; i++) {
        final daysAheadDelivery = rng.nextInt(40) + 2; // entre 2 et 42 jours
        final daysAheadFitting = rng.nextInt(daysAheadDelivery) + 1;
        final hour = rng.nextBool() ? rng.nextInt(12) + 8 : 0; // 8h-19h ou 0h

        randomOrders.add(Order(
          id: 'rnd-ord-$i',
          clientId: 'c1',
          title: 'Modèle $i',
          price: (rng.nextInt(50) + 10) * 1000,
          deliveryDate: DateTime(baseNow.year, baseNow.month, baseNow.day + daysAheadDelivery),
          fittingDate: DateTime(baseNow.year, baseNow.month, baseNow.day + daysAheadFitting, hour),
          createdAt: baseNow,
        ));
      }

      for (var i = 0; i < 50; i++) {
        final daysAheadDue = rng.nextInt(40) + 2;
        randomApps.add(Apprentice(
          id: 'rnd-app-$i',
          name: 'Apprenti $i',
          startDate: baseNow,
          totalFee: 100000,
          nextDue: DateTime(baseNow.year, baseNow.month, baseNow.day + daysAheadDue),
        ));
      }

      final planned = engine.plannedReminders(
        now: baseNow,
        orders: randomOrders,
        apprentices: randomApps,
        clientById: (_) => client,
        remainingOfOrder: (_) => 5000,
        remainingOfApprentice: (_) => 15000,
      );

      expect(planned, isNotEmpty);

      // Vérifier l'invariant pour chaque rappel généré
      for (final reminder in planned) {
        final alertsAtT = engine.currentAlerts(
          now: reminder.scheduledAt,
          orders: randomOrders,
          apprentices: randomApps,
          clientById: (_) => client,
          remainingOfOrder: (_) => 5000,
          remainingOfApprentice: (_) => 15000,
        );

        final hasMatch = alertsAtT.any((a) => a.key == reminder.alertKey);
        expect(hasMatch, isTrue,
            reason: 'Invariant violé pour ${reminder.alertKey} à ${reminder.scheduledAt}');
      }
    });
  });
}

