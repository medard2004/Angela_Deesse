import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models.dart';
import 'alert_engine.dart';
import 'notification_center_service.dart';

/// Gestionnaire d'actions en arrière-plan invoqué par Android lorsque l'app est fermée (Décision 21).
/// Strictement isolé : n'accède à aucune base SQLite, aucun réseau, aucune outbox.
@pragma('vm:entry-point')
void notificationActionBackgroundHandler(NotificationResponse response) async {
  final actionId = response.actionId;
  final notificationId = response.id;
  final payloadRaw = response.payload;

  if (notificationId == null) return;

  final plugin = FlutterLocalNotificationsPlugin();

  if (actionId == SystemReminderService.kActionDone) {
    // Action « Fait » : annule simplement la notification
    await plugin.cancel(id: notificationId);
    return;
  }

  if (actionId == SystemReminderService.kActionSnooze) {
    // Action « Reporter 10 min » : replanifie à +10 minutes
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
        });

        await plugin.zonedSchedule(
          id: snoozeId,
          title: title,
          body: body,
          scheduledDate: snoozeTime,
          notificationDetails: SystemReminderService.notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: snoozePayload,
        );
      } catch (_) {
        // Ignorer silencieusement toute anomalie de désérialisation
      }
    }
  }
}

/// Service central des rappels système push local avec sonnerie d'alarme (Décisions 13-23).
class SystemReminderService {
  SystemReminderService({
    FlutterLocalNotificationsPlugin? plugin,
    this.alertEngine = const AlertEngine(),
  }) : plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin plugin;
  final AlertEngine alertEngine;

  static const String kChannelId = 'rappels_sonores_v1';
  static const String kChannelName = 'Rappels de production';
  static const String kChannelDesc =
      'Rappels sonores pour les livraisons, essayages et échéances d\'apprentis';

  static const String kActionDone = 'action_done';
  static const String kActionSnooze = 'action_snooze';

  static const String kPayloadTypePlan = 'plan';
  static const String kPayloadTypeSnooze = 'snooze';
  static const String kPayloadTypeTest = 'test';

  Timer? _debounceTimer;

  static NotificationDetails get notificationDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          kChannelId,
          kChannelName,
          channelDescription: kChannelDesc,
          importance: Importance.max,
          priority: Priority.max,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
          icon: 'ic_stat_notification',
          color: Color(0xFF002B49), // Pal.cobalt
          visibility: NotificationVisibility.private, // Masqué sur écran verrouillé
          autoCancel: false,
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

  /// Initialise le plugin de notification et configure les fuseaux horaires.
  Future<void> init({
    void Function(NotificationResponse)? onSelectNotification,
  }) async {
    tz.initializeTimeZones();

    // Configuration par défaut sur le fuseau local
    try {
      final String currentTimeZone = DateTime.now().timeZoneName;
      if (tz.timeZoneDatabase.locations.containsKey(currentTimeZone)) {
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
      } else {
        // Repli par défaut sur heure locale Afrique de l'Ouest (Lomé / GMT)
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
        if (response.actionId == null || response.actionId!.isEmpty) {
          // Clic direct sur la notification : marque la destination pour après le PIN
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
  }

  /// Vérifie si l'application dispose de l'autorisation de poster des notifications.
  Future<bool> areNotificationsGranted() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final androidImpl =
        plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await androidImpl?.areNotificationsEnabled() ?? false;
  }

  /// Demande la permission POST_NOTIFICATIONS à l'utilisateur (Android 13+).
  /// Jamais demandée au lancement automatique, uniquement sur action explicite (Décision 22).
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
    required bool deliveryEnabled,
    required bool fittingEnabled,
    required bool paymentsEnabled,
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
      );
    });
  }

  /// Replanifie de manière idempotente l'intégralité des rappels système actifs (Décision 20).
  /// N'annule QUE les notifications de type « plan » ; préserve les reports (« snooze »).
  Future<void> rescheduleAll({
    required List<Order> orders,
    required List<Apprentice> apprentices,
    required Client? Function(String clientId) clientById,
    required int Function(Order order) remainingOfOrder,
    required int Function(Apprentice apprentice) remainingOfApprentice,
    required bool deliveryEnabled,
    required bool fittingEnabled,
    required bool paymentsEnabled,
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
        } catch (_) {
          // Si payload inconnu, ne pas annuler pour éviter de casser un snooze
        }
      }
    }

    // 2. Génération des rappels groupés anti-fatigue via AlertEngine (Décisions 14 et 15)
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
      maxWindowDays: 45,
      maxReminders: 120,
    );

    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    for (final g in grouped) {
      final tzTime = tz.TZDateTime.from(g.scheduledAt, tz.local);
      final payload = jsonEncode({
        'type': kPayloadTypePlan,
        'title': g.title,
        'body': g.body,
        'id': g.id,
        'keys': g.alertKeys,
      });

      await plugin.zonedSchedule(
        id: g.id,
        title: g.title,
        body: g.body,
        scheduledDate: tzTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    }
  }

  /// Planifie un test de sonnerie dans 1 minute ou 30 minutes (Décision 26).
  Future<void> scheduleRingerTest({required Duration delay}) async {
    final testId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF;
    final scheduledTime = tz.TZDateTime.now(tz.local).add(delay);

    final payload = jsonEncode({
      'type': kPayloadTypeTest,
      'title': 'Test de sonnerie Angela Déesse',
      'body': 'Si vous entendez cette alarme, vos rappels fonctionneront parfaitement.',
      'id': testId,
    });

    final canExact = await canScheduleExactAlarms();
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await plugin.zonedSchedule(
      id: testId,
      title: 'Test de sonnerie Angela Déesse',
      body: 'Si vous entendez cette alarme, vos rappels fonctionneront parfaitement.',
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: scheduleMode,
      payload: payload,
    );
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
