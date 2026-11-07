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
      // MainActivity ne doit jamais rester visible au-dessus de l'écran de verrouillage
      expect(manifestContent, isNot(contains('android:name=".MainActivity"\n            android:exported="true"\n            android:launchMode="singleTop"\n            android:taskAffinity=""\n            android:theme="@style/LaunchTheme"\n            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"\n            android:hardwareAccelerated="true"\n            android:windowSoftInputMode="adjustResize"\n            android:showWhenLocked="true"')));
      expect(manifestContent, isNot(contains('android:showWhenLocked="true"')));
      expect(manifestContent, isNot(contains('android:turnScreenOn="true"')));
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

