import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/app_brand.dart';
import '../models.dart';
import '../repositories/notification_log_repository.dart';
import '../repositories/settings_repository.dart';
import 'alert_engine.dart';
import 'native_alarm_bridge.dart';
import 'notification_center_service.dart';

/// Gestionnaire d'actions en arrière-plan invoqué par Android lorsque l'app est fermée.
/// Strictement isolé : n'accède à aucune base SQLite, aucun réseau, aucune outbox.
@pragma('vm:entry-point')
void notificationActionBackgroundHandler(NotificationResponse response) async {
  final actionId = response.actionId;
  final notificationId = response.id;
  final payloadRaw = response.payload;

  if (notificationId == null) return;

  final plugin = FlutterLocalNotificationsPlugin();

  if (actionId == SystemReminderService.kActionDone) {
    // Action « Fait » / « Arrêter » : annule immédiatement la notification
    await plugin.cancel(id: notificationId);
    return;
  }

  if (actionId == SystemReminderService.kActionSnooze) {
    // Action « Reporter 10 min » : annule et replanifie à +10 minutes
    await plugin.cancel(id: notificationId);

    if (payloadRaw != null && payloadRaw.isNotEmpty) {
      try {
        final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
        final title = payload['title'] as String? ?? 'Rappel';
        final body = payload['body'] as String? ?? '';
        final snoozeId = (notificationId | 0x40000000) & 0x7FFFFFFF;

        tz.initializeTimeZones();
        final snoozeTime = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10));

        final snoozePayload = jsonEncode({
          'type': 'snooze',
          'title': title,
          'body': body,
          'id': snoozeId,
          'isAlarm': false,
        });

        await plugin.zonedSchedule(
          id: snoozeId,
          title: title,
          body: body,
          scheduledDate: snoozeTime,
          notificationDetails: SystemReminderService.standardNotificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: snoozePayload,
        );
      } catch (_) {
        // Ignorer silencieusement toute anomalie de désérialisation
      }
    }
  }
}

/// Service central des rappels système push local et alarmes plein écran (Décisions 13-26).
class SystemReminderService {
  SystemReminderService({
    FlutterLocalNotificationsPlugin? plugin,
    NativeAlarmBridge? nativeBridge,
    this.logRepo,
    this.alertEngine = const AlertEngine(),
  })  : plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        nativeBridge = nativeBridge ?? const MethodChannelNativeAlarmBridge();

  final FlutterLocalNotificationsPlugin plugin;
  final NativeAlarmBridge nativeBridge;
  final NotificationLogRepository? logRepo;
  final AlertEngine alertEngine;

  static const String kAlarmChannelId = 'alarmes_douces_v3';
  static const String kAlarmChannelName = 'Alarmes d\'atelier (Mélodie douce)';
  static const String kAlarmChannelDesc =
      'Sonnerie douce et plein écran pour les essayages et livraisons';

  static const String kStandardChannelId = 'notifications_standard_v1';
  static const String kStandardChannelName = 'Notifications simples';
  static const String kStandardChannelDesc =
      'Notifications discrètes pour les paiements et rappels de production';

  static const String kActionDone = 'action_done';
  static const String kActionSnooze = 'action_snooze';

  static const String kPayloadTypePlan = 'plan';
  static const String kPayloadTypeSnooze = 'snooze';
  static const String kPayloadTypeTest = 'test';

  /// Flux diffusant les notifications ou alarmes survenant quand l'app est active.
  static final StreamController<Map<String, dynamic>> inAppEventStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Timer? _debounceTimer;
  final List<Timer> _activeTimers = [];

  /// Détails pour les alarmes plein écran (utilisé comme référence / repli).
  static NotificationDetails get alarmNotificationDetails => NotificationDetails(
        android: AndroidNotificationDetails(
          kAlarmChannelId,
          kAlarmChannelName,
          channelDescription: kAlarmChannelDesc,
          importance: Importance.max,
          priority: Priority.max,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
          fullScreenIntent: true,
          sound: const RawResourceAndroidNotificationSound('gentle_alarm'),
          playSound: true,
          additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT : sonne en boucle
          timeoutAfter: 60000,
          icon: 'ic_stat_notification',
          color: const Color(0xFF1747B8),
          visibility: NotificationVisibility.private,
          autoCancel: false,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(
              kActionDone,
              'Arrêter',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              kActionSnooze,
              'Reporter 10 min',
              showsUserInterface: false,
            ),
          ],
        ),
      );

  /// Détails pour les notifications standards calmes.
  static NotificationDetails get standardNotificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          kStandardChannelId,
          kStandardChannelName,
          channelDescription: kStandardChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
          fullScreenIntent: false,
          icon: 'ic_stat_notification',
          color: Color(0xFF1747B8),
          visibility: NotificationVisibility.private,
          autoCancel: true,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              kActionDone,
              'Fait',
              showsUserInterface: false,
              cancelNotification: true,
            ),
            AndroidNotificationAction(
              kActionSnooze,
              'Reporter 10 min',
              showsUserInterface: false,
            ),
          ],
        ),
      );

  /// Configuration par défaut rétrocompatible.
  static NotificationDetails get notificationDetails => standardNotificationDetails;

  /// Initialise le plugin de notification et configure les fuseaux horaires.
  Future<void> init({
    void Function(NotificationResponse)? onSelectNotification,
  }) async {
    tz.initializeTimeZones();

    try {
      final String currentTimeZone = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(currentTimeZone)) {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
      } else {
        tz.setLocalLocation(tz.getLocation('Africa/Lome'));
      }
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Lome'));
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('ic_stat_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final map = jsonDecode(response.payload!) as Map<String, dynamic>;
            inAppEventStream.add(map);
          } catch (_) {}
        }

        if (response.actionId == null || response.actionId!.isEmpty) {
          NotificationCenterService.pendingOpenNotifications = true;
          onSelectNotification?.call(response);
        } else if (response.actionId == kActionDone) {
          if (response.id != null) plugin.cancel(id: response.id!);
        } else if (response.actionId == kActionSnooze) {
          notificationActionBackgroundHandler(response);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationActionBackgroundHandler,
    );

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final androidImpl = plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              kAlarmChannelId,
              kAlarmChannelName,
              description: kAlarmChannelDesc,
              importance: Importance.max,
              sound: RawResourceAndroidNotificationSound('gentle_alarm'),
              playSound: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              enableVibration: true,
            ),
          );
          await androidImpl.createNotificationChannel(
            const AndroidNotificationChannel(
              kStandardChannelId,
              kStandardChannelName,
              description: kStandardChannelDesc,
              importance: Importance.high,
              enableVibration: true,
            ),
          );
        }
      } catch (_) {}
    }

    try {
      final launchDetails = await plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        NotificationCenterService.pendingOpenNotifications = true;
        if (launchDetails.notificationResponse != null) {
          onSelectNotification?.call(launchDetails.notificationResponse!);
        }
      }
    } catch (_) {}

    try {
      final launchedFromNativeAlarm = await nativeBridge.consumeOpenNotifications();
      if (launchedFromNativeAlarm) {
        NotificationCenterService.pendingOpenNotifications = true;
      }
    } catch (_) {}
  }

  /// Vérifie si l'application dispose de l'autorisation de poster des notifications.
  Future<bool> areNotificationsGranted() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final androidImpl =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.areNotificationsEnabled() ?? false;
  }

  /// Demande la permission POST_NOTIFICATIONS à l'utilisateur (Android 13+).
  Future<bool> requestNotificationsPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final androidImpl =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Vérifie si les alarmes exactes sont autorisées par le système Android.
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final bridgeVal = await nativeBridge.canScheduleExactAlarms();
    if (bridgeVal) return true;
    final androidImpl =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.canScheduleExactNotifications() ?? true;
  }

  /// Vérifie si l'intention plein écran est utilisable (Android 14+).
  Future<bool> canUseFullScreenIntent() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    return await nativeBridge.canUseFullScreenIntent();
  }

  /// Déclenche une replanification complète avec temporisation anti-rafales (debounce).
  void scheduleRescheduleDebounced({
    required List<Order> orders,
    required List<Apprentice> apprentices,
    required Client? Function(String clientId) clientById,
    required int Function(Order order) remainingOfOrder,
    required int Function(Apprentice apprentice) remainingOfApprentice,
    bool deliveryEnabled = true,
    bool fittingEnabled = true,
    bool paymentsEnabled = true,
    bool apprenticeEnabled = true,
    ReminderMode? deliveryMode,
    ReminderMode? fittingMode,
    ReminderMode? paymentsMode,
    ReminderMode? apprenticeMode,
    DateTime? customNow,
    Duration debounceDuration = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      rescheduleAll(
        orders: orders,
        apprentices: apprentices,
        clientById: clientById,
        remainingOfOrder: remainingOfOrder,
        remainingOfApprentice: remainingOfApprentice,
        deliveryEnabled: deliveryEnabled,
        fittingEnabled: fittingEnabled,
        paymentsEnabled: paymentsEnabled,
        apprenticeEnabled: apprenticeEnabled,
        deliveryMode: deliveryMode,
        fittingMode: fittingMode,
        paymentsMode: paymentsMode,
        apprenticeMode: apprenticeMode,
        customNow: customNow,
      );
    });
  }

  /// Replanifie de manière idempotente l'intégralité des rappels système actifs.
  Future<void> rescheduleAll({
    required List<Order> orders,
    required List<Apprentice> apprentices,
    required Client? Function(String clientId) clientById,
    required int Function(Order order) remainingOfOrder,
    required int Function(Apprentice apprentice) remainingOfApprentice,
    bool deliveryEnabled = true,
    bool fittingEnabled = true,
    bool paymentsEnabled = true,
    bool apprenticeEnabled = true,
    ReminderMode? deliveryMode,
    ReminderMode? fittingMode,
    ReminderMode? paymentsMode,
    ReminderMode? apprenticeMode,
    DateTime? customNow,
  }) async {
    final now = customNow ?? DateTime.now();

    // 1. Annule UNIQUEMENT les notifications de type « plan » dans le plugin
    final pending = await plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payloadStr = request.payload;
      if (payloadStr != null && payloadStr.isNotEmpty) {
        try {
          final payload = jsonDecode(payloadStr) as Map<String, dynamic>;
          if (payload['type'] == kPayloadTypePlan) {
            await plugin.cancel(id: request.id);
          }
        } catch (_) {}
      }
    }

    // 2. Génération des rappels groupés anti-fatigue via AlertEngine
    final grouped = alertEngine.groupedPlannedReminders(
      now: now,
      orders: orders,
      apprentices: apprentices,
      clientById: clientById,
      remainingOfOrder: remainingOfOrder,
      remainingOfApprentice: remainingOfApprentice,
      deliveryEnabled: deliveryEnabled,
      fittingEnabled: fittingEnabled,
      paymentsEnabled: paymentsEnabled,
      apprenticeEnabled: apprenticeEnabled,
      deliveryMode: deliveryMode,
      fittingMode: fittingMode,
      paymentsMode: paymentsMode,
      apprenticeMode: apprenticeMode,
      maxWindowDays: 45,
      maxReminders: 120,
    );

    final alarms = grouped.where((g) => g.isAlarm).toList();
    final notifications = grouped.where((g) => !g.isAlarm).toList();

    // 3. Planification des alarmes de réveil via le pont natif Kotlin
    await nativeBridge.replacePlan(alarms);

    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();

    // 4. Planification des notifications simples calmes via flutter_local_notifications
    for (final g in notifications) {
      final tzTime = tz.TZDateTime.from(g.scheduledAt, tz.local);
      final title = g.title;
      final body = g.body;

      final payload = jsonEncode({
        'type': kPayloadTypePlan,
        'title': g.title,
        'body': g.body,
        'publicTitle': g.effectivePublicTitle,
        'publicBody': g.effectivePublicBody,
        'id': g.id,
        'keys': g.alertKeys,
        'isAlarm': false,
      });

      await plugin.zonedSchedule(
        id: g.id,
        title: title,
        body: body,
        scheduledDate: tzTime,
        notificationDetails: standardNotificationDetails,
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    }
  }

  /// Vide la boîte aux lettres d'événements du moteur natif et synchronise avec Drift.
  Future<int> drainNativeEvents() async {
    final events = await nativeBridge.drainEvents();
    if (events.isEmpty) return 0;
    for (final ev in events) {
      await syncNativeEventToLog(ev);
    }
    return events.length;
  }

  /// Synchronise un événement d'alarme natif avec la table `notification_log`.
  Future<void> syncNativeEventToLog(Map<String, dynamic> ev) async {
    final repo = logRepo;
    if (repo == null) return;

    final alarmId = (ev['alarmId'] as num?)?.toInt() ?? 0;
    final scheduledAtMs = (ev['scheduledAtMs'] as num?)?.toInt() ?? 0;
    final timestampMs = (ev['timestampMs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    final eventType = ev['eventType'] as String? ?? 'fired';
    final category = ev['category'] as String? ?? 'rappel';
    final title = ev['title'] as String? ?? 'Rappel';
    final body = ev['body'] as String? ?? '';
    final itemCount = (ev['itemCount'] as num?)?.toInt() ?? 1;
    final alertKeys = (ev['alertKeys'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
    final snoozeCount = (ev['snoozeCount'] as num?)?.toInt() ?? 0;

    final sourceEventId = 'alarm_${alarmId}_$scheduledAtMs';
    final scheduledAt = DateTime.fromMillisecondsSinceEpoch(scheduledAtMs, isUtc: true);
    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);

    final existing = await repo.getBySourceEventId(sourceEventId);

    switch (eventType) {
      case 'fired':
        if (existing == null) {
          await repo.logEvent(
            channel: 'alarm',
            category: category,
            title: title,
            body: body,
            itemCount: itemCount,
            alertKeys: alertKeys,
            scheduledAt: scheduledAt,
            firedAt: timestamp,
            outcome: 'fired',
            snoozeCount: snoozeCount,
            sourceEventId: sourceEventId,
          );
        }
        break;

      case 'stopped':
        if (existing != null) {
          await repo.updateOutcome(
            existing.id,
            outcome: 'stopped',
            endedAt: timestamp,
          );
        } else {
          await repo.logEvent(
            channel: 'alarm',
            category: category,
            title: title,
            body: body,
            itemCount: itemCount,
            alertKeys: alertKeys,
            scheduledAt: scheduledAt,
            firedAt: timestamp,
            endedAt: timestamp,
            outcome: 'stopped',
            snoozeCount: snoozeCount,
            sourceEventId: sourceEventId,
          );
        }
        break;

      case 'snoozed':
        if (existing != null) {
          await repo.updateOutcome(
            existing.id,
            outcome: 'snoozed',
            endedAt: timestamp,
            snoozeCount: snoozeCount,
          );
        } else {
          await repo.logEvent(
            channel: 'alarm',
            category: category,
            title: title,
            body: body,
            itemCount: itemCount,
            alertKeys: alertKeys,
            scheduledAt: scheduledAt,
            firedAt: timestamp,
            endedAt: timestamp,
            outcome: 'snoozed',
            snoozeCount: snoozeCount,
            sourceEventId: sourceEventId,
          );
        }
        break;

      case 'missed':
        if (existing != null) {
          await repo.updateOutcome(
            existing.id,
            outcome: 'missed',
            endedAt: timestamp,
          );
        } else {
          await repo.logEvent(
            channel: 'alarm',
            category: category,
            title: title,
            body: body,
            itemCount: itemCount,
            alertKeys: alertKeys,
            scheduledAt: scheduledAt,
            firedAt: timestamp,
            endedAt: timestamp,
            outcome: 'missed',
            snoozeCount: snoozeCount,
            sourceEventId: sourceEventId,
          );
        }
        // Notification système 'Rappel manqué'
        try {
          await plugin.show(
            id: (alarmId + 900000) & 0x7FFFFFFF,
            title: 'Rappel manqué : $title',
            body: 'L\'alarme a sonné pendant 5 minutes sans réponse.',
            notificationDetails: standardNotificationDetails,
            payload: jsonEncode({
              'type': 'missed_alarm',
              'alarmId': alarmId,
            }),
          );
        } catch (_) {}
        break;

      case 'opened':
        if (existing != null) {
          await repo.updateOutcome(
            existing.id,
            outcome: 'opened',
          );
        } else {
          await repo.logEvent(
            channel: 'alarm',
            category: category,
            title: title,
            body: body,
            itemCount: itemCount,
            alertKeys: alertKeys,
            scheduledAt: scheduledAt,
            firedAt: timestamp,
            outcome: 'opened',
            snoozeCount: snoozeCount,
            sourceEventId: sourceEventId,
          );
        }
        break;
    }
  }

  /// Trace l'affichage d'un bandeau in-app dans le journal.
  Future<void> logInAppBanner({
    required String title,
    required String body,
    String category = 'rappel',
    int itemCount = 1,
    List<String> alertKeys = const [],
    DateTime? now,
  }) async {
    final repo = logRepo;
    if (repo == null) return;
    final current = now ?? DateTime.now().toUtc();
    try {
      await repo.logEvent(
        channel: 'in_app_banner',
        category: category,
        title: title,
        body: body,
        itemCount: itemCount,
        alertKeys: alertKeys,
        scheduledAt: current,
        firedAt: current,
        endedAt: current,
        outcome: 'displayed',
      );
    } catch (_) {}
  }

  void _triggerInAppForegroundAlert({
    required int id,
    required String title,
    required String body,
    required bool isAlarm,
    required NotificationDetails details,
    required String payload,
    List<String> keys = const [],
    String type = kPayloadTypePlan,
  }) async {
    final state = WidgetsBinding.instance.lifecycleState;
    final isForeground = state == null || state == AppLifecycleState.resumed;
    if (!isForeground) return;

    if (!isAlarm) {
      try {
        await plugin.cancel(id: id);
      } catch (_) {}
    }

    inAppEventStream.add({
      'type': type,
      'title': title,
      'body': body,
      'id': id,
      'keys': keys,
      'isAlarm': isAlarm,
    });

    await logInAppBanner(
      title: title,
      body: body,
      category: isAlarm ? 'alarm' : 'notification',
      itemCount: 1,
      alertKeys: keys,
    );
  }

  /// Planifie un test de sonnerie ou d'alarme plein écran.
  Future<void> scheduleRingerTest({
    required Duration delay,
    bool asAlarm = true,
  }) async {
    final testId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF;
    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

    final title = asAlarm ? 'Test de sonnerie ${AppBrand.appName}' : 'Notification ${AppBrand.appName}';
    final body = asAlarm
        ? 'Alarme plein écran avec sonnerie douce jusqu\'à confirmation.'
        : 'Notification standard d\'alerte de production.';

    final payload = jsonEncode({
      'type': kPayloadTypeTest,
      'title': title,
      'body': body,
      'id': testId,
      'isAlarm': asAlarm,
    });

    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final details = asAlarm ? alarmNotificationDetails : standardNotificationDetails;

    if (asAlarm) {
      await nativeBridge.replacePlan([
        GroupedReminder(
          id: testId,
          scheduledAt: DateTime.now().add(delay),
          title: title,
          body: body,
          alertKeys: const ['test_alert'],
          isGroup: false,
          publicTitle: 'Test de sonnerie ${AppBrand.appName}',
          publicBody: '1 rappel test',
          isAlarm: true,
        ),
      ]);
    }

    await plugin.zonedSchedule(
      id: testId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode: scheduleMode,
      payload: payload,
    );

    // Minuteur au premier plan : pour les tests courts (<= 2 min) quand l'app est active
    if (delay <= const Duration(minutes: 2)) {
      final timer = Timer(delay, () {
        _triggerInAppForegroundAlert(
          id: testId,
          title: title,
          body: body,
          isAlarm: asAlarm,
          details: details,
          payload: payload,
          type: kPayloadTypeTest,
        );
      });
      _activeTimers.add(timer);
    }
  }

  /// Liste des requêtes de notification en attente auprès du système.
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return await plugin.pendingNotificationRequests();
  }

  void dispose() {
    _debounceTimer?.cancel();
    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();
  }
}
