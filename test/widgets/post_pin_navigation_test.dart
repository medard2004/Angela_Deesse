import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:angela_dress/data/services/contact_launcher.dart';
import 'package:angela_dress/data/services/notification_center_service.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/shell/app_shell.dart';
import 'package:angela_dress/screens/notifications_screen.dart';
import 'package:angela_dress/screens/home_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });
  group('Routage post-déverrouillage PIN (Décision 12)', () {
    late NotificationCenterService notifService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      notifService = NotificationCenterService(prefs);
      NotificationCenterService.pendingOpenNotifications = false;
    });

    testWidgets('Lancement normal : AppShell démarre sur HomeScreen', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationCenterService>.value(value: notifService),
            ChangeNotifierProvider(create: (_) => AppStore()),
            Provider<ContactLauncher?>.value(value: null),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(NotificationsScreen), findsNothing);
    });

    testWidgets('Lancement avec notification système en attente : ouvre NotificationsScreen après le PIN', (tester) async {
      NotificationCenterService.pendingOpenNotifications = true;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationCenterService>.value(value: notifService),
            ChangeNotifierProvider(create: (_) => AppStore()),
            Provider<ContactLauncher?>.value(value: null),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();

      // AppShell a consommé le flag et ouvert NotificationsScreen directement
      expect(NotificationCenterService.pendingOpenNotifications, isFalse);
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });

    testWidgets('Notification reçue et cliquée app active : bascule vers NotificationsScreen', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationCenterService>.value(value: notifService),
            ChangeNotifierProvider(create: (_) => AppStore()),
            Provider<ContactLauncher?>.value(value: null),
          ],
          child: const MaterialApp(home: AppShell()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);

      // Simulation du clic sur la notification
      notifService.requestOpenNotifications();
      await tester.pumpAndSettle();

      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(NotificationCenterService.pendingOpenNotifications, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });
  });
}
