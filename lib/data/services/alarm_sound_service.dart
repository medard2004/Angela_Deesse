import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service de lecture de la sonnerie d'alarme douce en boucle (Android & fallback).
class AlarmSoundService {
  static const MethodChannel _channel = MethodChannel('com.digitalvision.angela_dress/alarm_sound');

  /// Démarre la sonnerie douce en boucle sur le flux audio STREAM_ALARM.
  static Future<void> startAlarm() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startAlarm');
    } catch (_) {}
  }

  /// Arrête la sonnerie d'alarme et libère les ressources audio.
  static Future<void> stopAlarm() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopAlarm');
    } catch (_) {}
  }
}

