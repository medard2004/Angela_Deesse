import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:angela_dress/data/repositories/notification_log_repository.dart';
import 'package:angela_dress/data/services/native_alarm_bridge.dart';
import 'package:angela_dress/data/services/system_reminder_service.dart';
import 'package:angela_dress/widgets/permission_onboarding_sheet.dart';

class StubNotificationLogRepo implements NotificationLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionOnboardingSheet', () {
    late FakeNativeAlarmBridge fakeBridge;
    late SystemReminderService reminderService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeBridge = FakeNativeAlarmBridge(
        canExact: true,
        canFullScreen: true,
        canOverlay: false, // Overlay non accordé au départ
      );
      reminderService = SystemReminderService(
        nativeBridge: fakeBridge,
        logRepo: StubNotificationLogRepo(),
      );
    });

    testWidgets('Affiche la feuille avec les tuiles de notifications et de plein écran', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                Provider<SystemReminderService>.value(value: reminderService),
              ],
              child: const PermissionOnboardingSheet(
                overrideNotificationsGranted: false,
                overrideOverlayGranted: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alertes de votre atelier'), findsOneWidget);
      expect(find.text('Notifications de rappels'), findsOneWidget);
      expect(find.text('Alarme plein écran'), findsOneWidget);
      expect(find.text('Continuer vers l\'atelier'), findsOneWidget);
      // Comme overlay est false, le bouton Activer doit être présent
      expect(find.text('Activer'), findsOneWidget);
    });

    testWidgets('Clic sur Activer appelle openOverlaySettings', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                Provider<SystemReminderService>.value(value: reminderService),
              ],
              child: const PermissionOnboardingSheet(
                overrideNotificationsGranted: false,
                overrideOverlayGranted: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(fakeBridge.openOverlaySettingsCallCount, equals(0));
      await tester.tap(find.text('Activer'));
      await tester.pumpAndSettle();

      expect(fakeBridge.openOverlaySettingsCallCount, equals(1));
    });
  });
}
