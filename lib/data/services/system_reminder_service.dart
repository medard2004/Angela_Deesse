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
import '../repositories/settings_repository.dart';
import 'alert_engine.dart';
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
    // Action « Arrêter » : annule immédiatement la notification et coupe l'alarme
    await plugin.cancel(id: notificationId);
    return;
  }

  if (actionId == SystemReminderService.kActionSnooze) {
    // Action « Reporter 10 min » : annule l'alarme actuelle et replanifie à +10 minutes
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
          'isAlarm': true,
        });

        await plugin.zonedSchedule(
          id: snoozeId,
          title: title,
          body: body,
          scheduledDate: snoozeTime,
          notificationDetails: SystemReminderService.alarmNotificationDetails,
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
    this.alertEngine = const AlertEngine(),
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin plugin;
  final AlertEngine alertEngine;

  static const String kAlarmChannelId = 'alarmes_douces_v2';
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

  /// Détails pour les alarmes plein écran (sonnerie douce & vibration en continu jusqu'à 60s).
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
          timeoutAfter: 60000, // 1 minute max (60 secondes)
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
        ),
      );

  /// Configuration par défaut rétrocompatible.
  static NotificationDetails get notificationDetails => alarmNotificationDetails;

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
    final androidImpl =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.canScheduleExactNotifications() ?? true;
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
    ReminderMode? deliveryMode,
    ReminderMode? fittingMode,
    ReminderMode? paymentsMode,
    DateTime? customNow,
    Duration debounceDuration = const Duration(milliseconds: 500),
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
        deliveryMode: deliveryMode,
        fittingMode: fittingMode,
        paymentsMode: paymentsMode,
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
    ReminderMode? deliveryMode,
    ReminderMode? fittingMode,
    ReminderMode? paymentsMode,
    DateTime? customNow,
  }) async {
    final now = customNow ?? DateTime.now();

    // 1. Annule UNIQUEMENT les notifications de type « plan »
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
      deliveryMode: deliveryMode,
      fittingMode: fittingMode,
      paymentsMode: paymentsMode,
      maxWindowDays: 45,
      maxReminders: 120,
    );

    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final t in _activeTimers) {
      t.cancel();
    }
    _activeTimers.clear();

    for (final g in grouped) {
      final tzTime = tz.TZDateTime.from(g.scheduledAt, tz.local);
      final payload = jsonEncode({
        'type': kPayloadTypePlan,
        'title': g.title,
        'body': g.body,
        'id': g.id,
        'keys': g.alertKeys,
        'isAlarm': g.isAlarm,
      });

      final details = g.isAlarm ? alarmNotificationDetails : standardNotificationDetails;

      await plugin.zonedSchedule(
        id: g.id,
        title: g.title,
        body: g.body,
        scheduledDate: tzTime,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    }
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
      // Pour une notification standard in-app : annuler le push OS pour ne pas doubler avec le bandeau
      try {
        await plugin.cancel(id: id);
      } catch (_) {}
    } else {
      // Pour une alarme réveil in-app : déclencher l'alerte sonore native
      try {
        await plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
          payload: payload,
        );
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

    await plugin.zonedSchedule(
      id: testId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: details,
      androidScheduleMode: scheduleMode,
      payload: payload,
    );

    // Minuteur au premier plan : uniquement pour les tests de démonstration courts (<= 30s)
    if (delay <= const Duration(seconds: 30)) {
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
