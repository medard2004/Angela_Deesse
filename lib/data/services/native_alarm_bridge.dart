import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'alert_engine.dart';

abstract class NativeAlarmBridge {
  Future<void> replacePlan(List<GroupedReminder> alarms);
  Future<List<Map<String, dynamic>>> drainEvents();
  Future<bool> canScheduleExactAlarms();
  Future<bool> canUseFullScreenIntent();
  Future<void> stopAlarm();
  Future<bool> consumeOpenNotifications();
}

class MethodChannelNativeAlarmBridge implements NativeAlarmBridge {
  const MethodChannelNativeAlarmBridge([
    this.channel = const MethodChannel('com.digitalvision.angela_dress/alarm_engine'),
  ]);

  final MethodChannel channel;

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
}

class FakeNativeAlarmBridge implements NativeAlarmBridge {
  FakeNativeAlarmBridge({
    this.canExact = true,
    this.canFullScreen = true,
  });

  bool canExact;
  bool canFullScreen;
  List<GroupedReminder> lastPlan = [];
  final List<Map<String, dynamic>> queuedEvents = [];
  int stopAlarmCallCount = 0;
  bool pendingOpenNotifications = false;

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
