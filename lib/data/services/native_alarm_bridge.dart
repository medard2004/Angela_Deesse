import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'alert_engine.dart';

typedef InAppAlarmCallback = void Function(Map<String, dynamic> event);

abstract class NativeAlarmBridge {
  Future<void> replacePlan(List<GroupedReminder> alarms);
  Future<List<Map<String, dynamic>>> drainEvents();
  Future<bool> canScheduleExactAlarms();
  Future<bool> canUseFullScreenIntent();
  Future<bool> canDrawOverlays();
  Future<void> openOverlaySettings();
  Future<void> openExactAlarmSettings();
  Future<void> openFullScreenIntentSettings();
  Future<void> stopAlarm();
  Future<bool> consumeOpenNotifications();
  Future<void> setAppUnlocked(bool unlocked);
}

class MethodChannelNativeAlarmBridge implements NativeAlarmBridge {
  const MethodChannelNativeAlarmBridge([
    this.channel = const MethodChannel('com.digitalvision.angela_dress/alarm_engine'),
    this.onInAppAlarm,
  ]);

  final MethodChannel channel;
  final InAppAlarmCallback? onInAppAlarm;

  static InAppAlarmCallback? globalInAppAlarmHandler;
  static bool _handlerRegistered = false;

  static void ensureHandlerRegistered([MethodChannel channel = const MethodChannel('com.digitalvision.angela_dress/alarm_engine')]) {
    if (kIsWeb || !Platform.isAndroid) return;
    if (!_handlerRegistered) {
      _handlerRegistered = true;
      try {
        channel.setMethodCallHandler(_handleNativeMethodCall);
      } catch (_) {}
    }
  }

  static Future<dynamic> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onAlarmTriggeredInApp') {
      try {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        globalInAppAlarmHandler?.call(args);
      } catch (_) {}
    }
    return null;
  }

  static String deriveCategory(List<String> keys) {
    if (keys.isEmpty) return 'rappel';
    final first = keys.first;
    if (first.startsWith('essayage')) return 'fitting';
    if (first.startsWith('livraison')) return 'delivery';
    if (first.startsWith('echeance_apprenti')) return 'apprentice_due';
    return 'rappel';
  }

  @override
  Future<void> replacePlan(List<GroupedReminder> alarms) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final items = alarms.map((g) => {
      'id': g.id,
      'scheduledAtMs': g.scheduledAt.millisecondsSinceEpoch,
      'category': deriveCategory(g.alertKeys),
      'publicTitle': g.effectivePublicTitle,
      'publicBody': g.effectivePublicBody,
      'fullTitle': g.title,
      'fullBody': g.body,
      'itemCount': g.alertKeys.length,
      'alertKeys': g.alertKeys,
    }).toList();

    try {
      await channel.invokeMethod<bool>('replacePlan', {'items': items});
    } catch (_) {
      // Ignorer silencieusement si hors environnement Flutter Android natif
    }
  }

  @override
  Future<List<Map<String, dynamic>>> drainEvents() async {
    if (kIsWeb || !Platform.isAndroid) return const [];

    try {
      final res = await channel.invokeMethod<List<dynamic>>('drainEvents');
      if (res == null) return const [];
      return res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final res = await channel.invokeMethod<bool>('canScheduleExactAlarms');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> canUseFullScreenIntent() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final res = await channel.invokeMethod<bool>('canUseFullScreenIntent');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> canDrawOverlays() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    try {
      final res = await channel.invokeMethod<bool>('canDrawOverlays');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> openOverlaySettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await channel.invokeMethod<bool>('openOverlaySettings');
    } catch (_) {}
  }

  @override
  Future<void> openExactAlarmSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await channel.invokeMethod<bool>('openExactAlarmSettings');
    } catch (_) {}
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await channel.invokeMethod<bool>('openFullScreenIntentSettings');
    } catch (_) {}
  }

  @override
  Future<void> stopAlarm() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await channel.invokeMethod<bool>('stopAlarm');
    } catch (_) {}
  }

  @override
  Future<bool> consumeOpenNotifications() async {
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final res = await channel.invokeMethod<bool>('consumeOpenNotifications');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setAppUnlocked(bool unlocked) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      await channel.invokeMethod<bool>('setAppUnlocked', {'unlocked': unlocked});
    } catch (_) {}
  }
}

class FakeNativeAlarmBridge implements NativeAlarmBridge {
  FakeNativeAlarmBridge({
    this.canExact = true,
    this.canFullScreen = true,
    this.canOverlay = true,
  });

  bool canExact;
  bool canFullScreen;
  bool canOverlay;
  bool isUnlocked = true;
  List<GroupedReminder> lastPlan = [];
  final List<Map<String, dynamic>> queuedEvents = [];
  int stopAlarmCallCount = 0;
  int openOverlaySettingsCallCount = 0;
  int openExactAlarmSettingsCallCount = 0;
  int openFullScreenIntentSettingsCallCount = 0;
  bool pendingOpenNotifications = false;

  @override
  Future<void> setAppUnlocked(bool unlocked) async {
    isUnlocked = unlocked;
  }

  @override
  Future<void> replacePlan(List<GroupedReminder> alarms) async {
    lastPlan = List.from(alarms);
  }

  @override
  Future<List<Map<String, dynamic>>> drainEvents() async {
    final copy = List<Map<String, dynamic>>.from(queuedEvents);
    queuedEvents.clear();
    return copy;
  }

  @override
  Future<bool> canScheduleExactAlarms() async => canExact;

  @override
  Future<bool> canUseFullScreenIntent() async => canFullScreen;

  @override
  Future<bool> canDrawOverlays() async => canOverlay;

  @override
  Future<void> openOverlaySettings() async {
    openOverlaySettingsCallCount++;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    openExactAlarmSettingsCallCount++;
  }

  @override
  Future<void> openFullScreenIntentSettings() async {
    openFullScreenIntentSettingsCallCount++;
  }

  @override
  Future<void> stopAlarm() async {
    stopAlarmCallCount++;
  }

  @override
  Future<bool> consumeOpenNotifications() async {
    final val = pendingOpenNotifications;
    pendingOpenNotifications = false;
    return val;
  }
}
