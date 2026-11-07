import 'package:angela_dress/data/db/app_database.dart';
import 'package:angela_dress/data/services/system_reminder_service.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/screens/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakePlugin extends Fake implements FlutterLocalNotificationsPlugin {
  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => [];
  @override
  Future<void> cancel({required int id, String? tag}) async {}
  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required dynamic scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {}
}

Widget _wrapWithStore({
  required Widget child,
  required AppStore store,
  required SystemReminderService reminderService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppStore>.value(value: store),
      Provider<SystemReminderService>.value(value: reminderService),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  testWidgets('SettingsScreen affiche les modes par défaut et permet de changer de mode', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fakePlugin = _FakePlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);
    final store = AppStore(db: db);

    await tester.pumpWidget(
      _wrapWithStore(
        child: SettingsScreen(onMenu: () {}),
        store: store,
        reminderService: reminderService,
      ),
    );
    await tester.pumpAndSettle();

    // Vérifier les libellés de catégories
    expect(find.text('Livraisons'), findsOneWidget);
    expect(find.text('Essayages'), findsOneWidget);
    expect(find.text('Échéances d\'apprentis'), findsOneWidget);
    expect(find.text('Soldes en attente'), findsOneWidget);
    expect(find.text('Commandes en retard'), findsOneWidget);

    // Par défaut : Livraisons, Essayages et Échéances d'apprentis sont en Alarme
    expect(store.deliveryMode, equals(ReminderMode.alarm));
    expect(store.fittingMode, equals(ReminderMode.alarm));
    expect(store.apprenticeMode, equals(ReminderMode.alarm));
    expect(store.paymentsMode, equals(ReminderMode.notification));
    expect(store.lateMode, equals(ReminderMode.notification));

    // Cliquer sur Livraisons pour ouvrir la sélection
    await tester.tap(find.text('Livraisons'));
    await tester.pumpAndSettle();

    // Vérifier les 3 options dans la feuille de sélection
    expect(find.text('Rappel : Livraisons'), findsOneWidget);
    expect(find.text('Alarme réveil plein écran'), findsOneWidget);
    expect(find.text('Notification standard'), findsOneWidget);
    expect(find.text('Désactivé'), findsOneWidget);

    // Changer le mode de Livraisons vers Notification standard
    await tester.tap(find.text('Notification standard'));
    await tester.pumpAndSettle();

    // Vérifier que le store a été mis à jour
    expect(store.deliveryMode, equals(ReminderMode.notification));
  });
}
