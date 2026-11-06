import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/services/system_reminder_service.dart';

/// Faux plugin FlutterLocalNotifications pour tester unitairement la planification.
class FakeFlutterLocalNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  final List<PendingNotificationRequest> pending = [];
  final List<Map<String, dynamic>> scheduled = [];
  final List<int> cancelledIds = [];
  bool areNotificationsEnabledResult = true;
  bool canScheduleExactResult = true;

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return List.unmodifiable(pending);
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledIds.add(id);
    pending.removeWhere((p) => p.id == id);
    scheduled.removeWhere((s) => s['id'] == id);
  }

  @override
  Future<void> cancelAll() async {
    cancelledIds.addAll(pending.map((p) => p.id));
    pending.clear();
    scheduled.clear();
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'androidScheduleMode': androidScheduleMode,
      'payload': payload,
    });
    pending.add(PendingNotificationRequest(id, title ?? '', body ?? '', payload ?? ''));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));
  });

  group('SystemReminderService (Décisions 13-23)', () {
    late FakeFlutterLocalNotificationsPlugin fakePlugin;
    late SystemReminderService service;

    setUp(() {
      fakePlugin = FakeFlutterLocalNotificationsPlugin();
      service = SystemReminderService(plugin: fakePlugin);
    });

    tearDown(() {
      service.dispose();
    });

    test('Replanification idempotente n\'annule QUE les demandes de type "plan", préserve les reports "snooze"', () async {
      // 1. Ajouter manuellement un rappel existant de type 'plan' et un report de type 'snooze'
      fakePlugin.pending.add(PendingNotificationRequest(
        1001,
        'Rappel 1',
        'Corps 1',
        jsonEncode({'type': 'plan', 'id': 1001}),
      ));
      fakePlugin.pending.add(PendingNotificationRequest(
        2002,
        'Report 10 min',
        'Corps report',
        jsonEncode({'type': 'snooze', 'id': 2002}),
      ));

      expect(fakePlugin.pending.length, equals(2));

      // 2. Déclencher rescheduleAll
      final now = DateTime(2026, 11, 6, 8, 0);
      await service.rescheduleAll(
        orders: [],
        apprentices: [],
        clientById: (_) => null,
        remainingOfOrder: (_) => 0,
        remainingOfApprentice: (_) => 0,
        deliveryEnabled: true,
        fittingEnabled: true,
        paymentsEnabled: true,
        customNow: now,
      );

      // Le rappel 1001 (plan) doit avoir été annulé
      expect(fakePlugin.cancelledIds, contains(1001));
      // Le rappel 2002 (snooze) NE DOIT PAS être annulé
      expect(fakePlugin.cancelledIds, isNot(contains(2002)));
      expect(fakePlugin.pending.any((p) => p.id == 2002), isTrue);
    });

    test('Planification exacte en instants absolus avec payload complet', () async {
      final now = DateTime(2026, 11, 6, 8, 0);
      final client = Client(id: 'c1', name: 'Amina');

      final order = Order(
        id: 'ord-sched-1',
        clientId: 'c1',
        title: 'Robe Cérémonie',
        price: 25000,
        deliveryDate: DateTime(2026, 11, 7), // demain
        createdAt: now,
      );

      await service.rescheduleAll(
        orders: [order],
        apprentices: [],
        clientById: (_) => client,
        remainingOfOrder: (_) => 5000,
        remainingOfApprentice: (_) => 0,
        deliveryEnabled: true,
        fittingEnabled: true,
        paymentsEnabled: true,
        customNow: now,
      );

      expect(fakePlugin.scheduled, isNotEmpty);
      final firstScheduled = fakePlugin.scheduled.first;
      expect(firstScheduled['title'], equals('Livraison demain'));

      final payloadStr = firstScheduled['payload'] as String;
      final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
      expect(payload['type'], equals('plan'));
      expect(payload['title'], equals('Livraison demain'));
      expect(payload['keys'], isNotEmpty);
    });

    test('Interrupteur désactivé = aucun rappel système généré pour cette catégorie', () async {
      final now = DateTime(2026, 11, 6, 8, 0);
      final client = Client(id: 'c1', name: 'Amina');

      final order = Order(
        id: 'ord-disabled',
        clientId: 'c1',
        title: 'Robe Désactivée',
        price: 25000,
        deliveryDate: DateTime(2026, 11, 7),
        createdAt: now,
      );

      // Désactiver explicitement les livraisons
      await service.rescheduleAll(
        orders: [order],
        apprentices: [],
        clientById: (_) => client,
        remainingOfOrder: (_) => 5000,
        remainingOfApprentice: (_) => 0,
        deliveryEnabled: false, // désactivé !
        fittingEnabled: true,
        paymentsEnabled: true,
        customNow: now,
      );

      expect(fakePlugin.scheduled, isEmpty);
    });

    test('Temporisation anti-rafale (debounce) : 10 appels rapides = 1 seule replanification', () async {
      final now = DateTime(2026, 11, 6, 8, 0);
      final client = Client(id: 'c1', name: 'Amina');
      final order = Order(
        id: 'ord-debounce',
        clientId: 'c1',
        title: 'Robe Debounce',
        price: 25000,
        deliveryDate: DateTime(2026, 11, 7),
        createdAt: now,
      );

      // Déclencher 10 fois d'affilée
      for (var i = 0; i < 10; i++) {
        service.scheduleRescheduleDebounced(
          orders: [order],
          apprentices: [],
          clientById: (_) => client,
          remainingOfOrder: (_) => 5000,
          remainingOfApprentice: (_) => 0,
          deliveryEnabled: true,
          fittingEnabled: true,
          paymentsEnabled: true,
          debounceDuration: const Duration(milliseconds: 50),
        );
      }

      // Immédiatement : rien n'a encore été planifié
      expect(fakePlugin.scheduled, isEmpty);

      // Attendre la fin du délai anti-rafale
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Exactement les notifications d'une seule replanification
      expect(fakePlugin.scheduled, isNotEmpty);
      expect(fakePlugin.scheduled.length, equals(2)); // veille 18h et jour J 8h
    });
  });
}
