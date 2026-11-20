import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validation du Manifeste Android (Décision 19)', () {
    late String manifestContent;

    setUpAll(() {
      final file = File('android/app/src/main/AndroidManifest.xml');
      expect(file.existsSync(), isTrue, reason: 'AndroidManifest.xml doit exister');
      manifestContent = file.readAsStringSync();
    });

    test('Permissions requises présentes', () {
      expect(manifestContent, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
      expect(manifestContent, contains('android.permission.VIBRATE'));
      expect(manifestContent, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifestContent, contains('android.permission.USE_EXACT_ALARM'));
      expect(manifestContent, contains('android.permission.SCHEDULE_EXACT_ALARM'));
      expect(manifestContent, contains('android:maxSdkVersion="32"'));
      expect(manifestContent, contains('android.permission.USE_FULL_SCREEN_INTENT'));
      expect(manifestContent, contains('android.permission.SYSTEM_ALERT_WINDOW'));
      // MainActivity ne doit jamais rester visible au-dessus de l'écran de verrouillage
      final mainActivityMatch = RegExp(r'<activity[^>]*android:name="\.MainActivity"[^>]*>', dotAll: true).firstMatch(manifestContent);
      expect(mainActivityMatch?.group(0), isNot(contains('android:showWhenLocked="true"')));
      expect(mainActivityMatch?.group(0), isNot(contains('android:turnScreenOn="true"')));

      // AlarmActivity porte légitimement showWhenLocked et turnScreenOn pour l'écran réveil
      final alarmActivityMatch = RegExp(r'<activity[^>]*android:name="\.AlarmActivity"[^>]*>', dotAll: true).firstMatch(manifestContent);
      expect(alarmActivityMatch?.group(0), contains('android:showWhenLocked="true"'));
      expect(alarmActivityMatch?.group(0), contains('android:turnScreenOn="true"'));
    });

    test('Receveurs de notifications déclarés', () {
      expect(
        manifestContent,
        contains('com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver'),
      );
      expect(
        manifestContent,
        contains('com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver'),
      );
      expect(
        manifestContent,
        contains('com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver'),
      );
      expect(manifestContent, contains('android.intent.action.BOOT_COMPLETED'));
      expect(manifestContent, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    });
  });
}

