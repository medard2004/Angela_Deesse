import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:angela_dress/data/db/app_database.dart' hide Order, Client;
import 'package:angela_dress/data/db/clock.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/repositories/notification_log_repository.dart';
import 'package:angela_dress/data/repositories/settings_repository.dart';
import 'package:angela_dress/data/services/native_alarm_bridge.dart';
import 'package:angela_dress/data/services/system_reminder_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;

class FakeFlutterLocalNotificationsPlugin extends Fake
    implements FlutterLocalNotificationsPlugin {
  final List<Map<String, dynamic>> scheduled = [];
  final List<int> cancelledIds = [];
  final List<PendingNotificationRequest> pending = [];
  final List<Map<String, dynamic>> shown = [];

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required dynamic scheduledDate,
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
      'details': notificationDetails,
      'payload': payload,
    });
  }

  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shown.add({
      'id': id,
      'title': title,
      'body': body,
      'details': notificationDetails,
      'payload': payload,
    });
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelledIds.add(id);
    pending.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return List.from(pending);
  }
}

void main() {
  late AppDatabase db;
  late NotificationLogRepository logRepo;
  late FakeNativeAlarmBridge fakeBridge;
  late FakeFlutterLocalNotificationsPlugin fakePlugin;
  late SystemReminderService service;

  setUp(() {
    tz.initializeTimeZones();
    db = AppDatabase(NativeDatabase.memory());
    logRepo = DriftNotificationLogRepository(
      db: db,
      clock: const SystemClock(),
    );
    fakeBridge = FakeNativeAlarmBridge();
    fakePlugin = FakeFlutterLocalNotificationsPlugin();
    service = SystemReminderService(
      plugin: fakePlugin,
      nativeBridge: fakeBridge,
      logRepo: logRepo,
    );
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  group('Synchronisation boîte aux lettres native -> Drift (notification_log)', () {
    test('Événement "fired" crée l\'entrée avec outcome fired et fired_at', () async {
      final scheduledAtMs = DateTime(2026, 11, 7, 8, 0).millisecondsSinceEpoch;
      final firedAtMs = DateTime(2026, 11, 7, 8, 0, 1).millisecondsSinceEpoch;

      fakeBridge.queuedEvents.add({
        'eventId': 'ev-1',
        'alarmId': 101,
        'category': 'fitting',
        'title': 'Essayage demain',
        'body': 'Amina · Robe Cérémonie',
        'itemCount': 1,
        'alertKeys': ['essayage:demain:ord-1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': firedAtMs,
        'eventType': 'fired',
        'snoozeCount': 0,
      });

      final drainedCount = await service.drainNativeEvents();
      expect(drainedCount, equals(1));

      final log = await logRepo.getBySourceEventId('alarm_101_$scheduledAtMs');
      expect(log, isNotNull);
      expect(log!.outcome, equals('fired'));
      expect(log.channel, equals('alarm'));
      expect(log.category, equals('fitting'));
      expect(log.firedAt, isNotNull);
      expect(log.endedAt, isNull);
    });

    test('Événement "stopped" met à jour l\'outcome à stopped et ended_at', () async {
      final scheduledAtMs = DateTime(2026, 11, 7, 8, 0).millisecondsSinceEpoch;
      final firedAtMs = DateTime(2026, 11, 7, 8, 0, 1).millisecondsSinceEpoch;
      final stoppedAtMs = DateTime(2026, 11, 7, 8, 0, 25).millisecondsSinceEpoch;

      // 1. Fired
      fakeBridge.queuedEvents.add({
        'eventId': 'ev-1',
        'alarmId': 102,
        'category': 'delivery',
        'title': 'Livraison demain',
        'body': 'Amina · Robe',
        'itemCount': 1,
        'alertKeys': ['livraison:demain:ord-1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': firedAtMs,
        'eventType': 'fired',
      });
      await service.drainNativeEvents();

      // 2. Stopped
      fakeBridge.queuedEvents.add({
        'eventId': 'ev-2',
        'alarmId': 102,
        'category': 'delivery',
        'title': 'Livraison demain',
        'body': 'Amina · Robe',
        'itemCount': 1,
        'alertKeys': ['livraison:demain:ord-1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': stoppedAtMs,
        'eventType': 'stopped',
      });
      await service.drainNativeEvents();

      final log = await logRepo.getBySourceEventId('alarm_102_$scheduledAtMs');
      expect(log, isNotNull);
      expect(log!.outcome, equals('stopped'));
      expect(log.endedAt, isNotNull);
    });

    test('Événement "snoozed" met à jour l\'outcome et snooze_count', () async {
      final scheduledAtMs = DateTime(2026, 11, 7, 8, 0).millisecondsSinceEpoch;
      final firedAtMs = DateTime(2026, 11, 7, 8, 0, 1).millisecondsSinceEpoch;
      final snoozedAtMs = DateTime(2026, 11, 7, 8, 0, 15).millisecondsSinceEpoch;

      fakeBridge.queuedEvents.add({
        'eventId': 'ev-1',
        'alarmId': 103,
        'category': 'fitting',
        'title': 'Essayage demain',
        'body': 'Amina',
        'itemCount': 1,
        'alertKeys': ['essayage:demain:ord-1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': firedAtMs,
        'eventType': 'fired',
      });
      await service.drainNativeEvents();

      fakeBridge.queuedEvents.add({
        'eventId': 'ev-3',
        'alarmId': 103,
        'category': 'fitting',
        'title': 'Essayage demain',
        'body': 'Amina',
        'itemCount': 1,
        'alertKeys': ['essayage:demain:ord-1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': snoozedAtMs,
        'eventType': 'snoozed',
        'snoozeCount': 1,
      });
      await service.drainNativeEvents();

      final log = await logRepo.getBySourceEventId('alarm_103_$scheduledAtMs');
      expect(log, isNotNull);
      expect(log!.outcome, equals('snoozed'));
      expect(log.snoozeCount, equals(1));
    });

    test('Événement "missed" met à jour outcome missed et déclenche notification système', () async {
      final scheduledAtMs = DateTime(2026, 11, 7, 8, 0).millisecondsSinceEpoch;
      final firedAtMs = DateTime(2026, 11, 7, 8, 0, 1).millisecondsSinceEpoch;
      final missedAtMs = DateTime(2026, 11, 7, 8, 5, 1).millisecondsSinceEpoch;

      fakeBridge.queuedEvents.add({
        'eventId': 'ev-1',
        'alarmId': 104,
        'category': 'delivery',
        'title': 'Livraison demain',
        'body': 'Amina',
        'itemCount': 1,
        'alertKeys': ['livraison:demain:ord-1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': firedAtMs,
        'eventType': 'fired',
      });
      await service.drainNativeEvents();

      fakeBridge.queuedEvents.add({
        'eventId': 'ev-4',
        'alarmId': 104,
        'category': 'delivery',
        'title': 'Livraison demain',
        'body': 'Amina',
        'itemCount': 1,
        'alertKeys': ['livraison:demain:ord-1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': missedAtMs,
        'eventType': 'missed',
      });
      await service.drainNativeEvents();

      final log = await logRepo.getBySourceEventId('alarm_104_$scheduledAtMs');
      expect(log, isNotNull);
      expect(log!.outcome, equals('missed'));
      expect(log.endedAt, isNotNull);

      // Notification système de rappel manqué déclenchée
      expect(fakePlugin.shown, isNotEmpty);
      expect(fakePlugin.shown.first['title'], contains('Rappel manqué'));
    });

    test('Événement "opened" marque outcome opened', () async {
      final scheduledAtMs = DateTime(2026, 11, 7, 8, 0).millisecondsSinceEpoch;
      final firedAtMs = DateTime(2026, 11, 7, 8, 0, 1).millisecondsSinceEpoch;

      fakeBridge.queuedEvents.add({
        'eventId': 'ev-1',
        'alarmId': 105,
        'category': 'delivery',
        'title': 'Livraison',
        'body': 'Amina',
        'itemCount': 1,
        'alertKeys': ['k1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': firedAtMs,
        'eventType': 'opened',
      });
      await service.drainNativeEvents();

      final log = await logRepo.getBySourceEventId('alarm_105_$scheduledAtMs');
      expect(log, isNotNull);
      expect(log!.outcome, equals('opened'));
    });

    test('Idempotence : rejouer un événement ne crée aucun doublon', () async {
      final scheduledAtMs = DateTime(2026, 11, 7, 8, 0).millisecondsSinceEpoch;
      final firedAtMs = DateTime(2026, 11, 7, 8, 0, 1).millisecondsSinceEpoch;

      final eventMap = {
        'eventId': 'ev-idempotent',
        'alarmId': 106,
        'category': 'delivery',
        'title': 'Livraison',
        'body': 'Amina',
        'itemCount': 1,
        'alertKeys': ['k1'],
        'scheduledAtMs': scheduledAtMs,
        'timestampMs': firedAtMs,
        'eventType': 'fired',
      };

      fakeBridge.queuedEvents.add(eventMap);
      await service.drainNativeEvents();

      // Rejeu du même événement
      fakeBridge.queuedEvents.add(eventMap);
      await service.drainNativeEvents();

      final allLogs = await logRepo.getHistory(limit: 100);
      final matching = allLogs.where((l) => l.sourceEventId == 'alarm_106_$scheduledAtMs');
      expect(matching.length, equals(1));
    });

    test('Signal in-app (bandeau) est tracé dans notification_log avec channel in_app_banner et outcome displayed', () async {
      await service.logInAppBanner(
        title: 'Bandeau essayage',
        body: 'Amina · Robe',
        category: 'fitting',
        alertKeys: ['essayage:ord-1'],
      );

      final allLogs = await logRepo.getHistory(limit: 10);
      expect(allLogs, isNotEmpty);
      final bannerLog = allLogs.first;
      expect(bannerLog.channel, equals('in_app_banner'));
      expect(bannerLog.category, equals('fitting'));
      expect(bannerLog.outcome, equals('displayed'));
      expect(bannerLog.firedAt, isNotNull);
      expect(bannerLog.endedAt, isNotNull);
    });
  });

  group('Séparation alarmes natives et notifications simples dans rescheduleAll', () {
    test('Rappels en mode alarme sont envoyés au pont natif, notifications au plugin', () async {
      final now = DateTime(2026, 11, 6, 8, 0);
      final client = Client(id: 'c1', name: 'Amina');

      final order1 = Order(
        id: 'ord-alarm',
        clientId: 'c1',
        title: 'Robe Alarme',
        price: 30000,
        deliveryDate: DateTime(2026, 11, 7), // Demain -> alarme
        createdAt: now,
      );

      final order2 = Order(
        id: 'ord-notif',
        clientId: 'c1',
        title: 'Robe Notification',
        price: 20000,
        fittingDate: DateTime(2026, 11, 7, 10, 0), // Demain -> notification
        deliveryDate: DateTime(2026, 11, 8),
        createdAt: now,
      );

      await service.rescheduleAll(
        orders: [order1, order2],
        apprentices: [],
        clientById: (_) => client,
        remainingOfOrder: (_) => 0,
        remainingOfApprentice: (_) => 0,
        deliveryMode: ReminderMode.alarm,
        fittingMode: ReminderMode.notification,
        customNow: now,
      );

      // Le pont natif a reçu l'alarme de livraison
      expect(fakeBridge.lastPlan, isNotEmpty);
      expect(fakeBridge.lastPlan.any((r) => r.isAlarm), isTrue);

      // Le plugin local de notifications a reçu la notification d'essayage
      expect(fakePlugin.scheduled, isNotEmpty);
      final scheduledNotif = fakePlugin.scheduled.first;
      final payload = jsonDecode(scheduledNotif['payload'] as String);
      expect(payload['isAlarm'], isFalse);
    });
  });
}
