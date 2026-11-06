import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:angela_dress/data/db/app_database.dart';
import 'package:angela_dress/data/services/system_reminder_service.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/screens/reminder_guide_screen.dart';
import 'package:angela_dress/screens/settings_screen.dart';

class FakeFlutterLocalNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  final List<PendingNotificationRequest> pending = [];
  final List<Map<String, dynamic>> scheduled = [];
  bool areNotificationsEnabledResult = true;
  bool canScheduleExactResult = true;

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return List.unmodifiable(pending);
  }

  @override
  Future<void> cancel({required int id, String? tag}) async {
    pending.removeWhere((p) => p.id == id);
    scheduled.removeWhere((s) => s['id'] == id);
  }

  @override
  Future<void> cancelAll() async {
    pending.clear();
    scheduled.clear();
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'payload': payload,
    });
    pending.add(PendingNotificationRequest(id, title ?? '', body ?? '', payload ?? ''));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting('fr_FR', null);
  });

  Widget buildTestableWidget({
    required Widget child,
    required SystemReminderService reminderService,
    required AppStore store,
  }) {
    return MultiProvider(
      providers: [
        Provider<SystemReminderService>.value(value: reminderService),
        ChangeNotifierProvider<AppStore>.value(value: store),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('Affiche le guide avec badges de statut et récapitulatif', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fakePlugin = FakeFlutterLocalNotificationsPlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);
    addTearDown(reminderService.dispose);
    final store = AppStore(db: db);

    await tester.pumpWidget(
      buildTestableWidget(
        child: const ReminderGuideScreen(),
        reminderService: reminderService,
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pour que les rappels sonnent'), findsOneWidget);
    expect(find.text('Autorisations système'), findsOneWidget);
    expect(find.text('Notifications de l\'application'), findsOneWidget);
    expect(find.text('Autorisées'), findsOneWidget);
    expect(find.text('Alarmes précises'), findsOneWidget);
    expect(find.text('Exactes'), findsOneWidget);
    expect(find.text('Optimisation de la batterie'), findsOneWidget);
    expect(find.text('Tester la sonnerie d\'alarme'), findsOneWidget);
    expect(find.text('Dans 1 min'), findsOneWidget);
    expect(find.text('Dans 30 min'), findsOneWidget);
  });

  testWidgets('Affiche les instructions spécifiques pour Tecno / Infinix / Itel', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fakePlugin = FakeFlutterLocalNotificationsPlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);
    addTearDown(reminderService.dispose);
    final store = AppStore(db: db);

    await tester.pumpWidget(
      buildTestableWidget(
        child: const ReminderGuideScreen(overrideManufacturer: 'TECNO MOBILE LIMITED'),
        reminderService: reminderService,
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('TECNO MOBILE LIMITED'), findsOneWidget);
    expect(find.textContaining('Phone Master'), findsOneWidget);
    expect(find.textContaining('Démarrage automatique'), findsWidgets);
    expect(find.textContaining('Cadenas'), findsOneWidget);
  });

  testWidgets('Planifie un test de sonnerie dans 1 minute et affiche le dialogue', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fakePlugin = FakeFlutterLocalNotificationsPlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);
    addTearDown(reminderService.dispose);
    final store = AppStore(db: db);

    await tester.pumpWidget(
      buildTestableWidget(
        child: const ReminderGuideScreen(),
        reminderService: reminderService,
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(fakePlugin.scheduled, isEmpty);

    await tester.tap(find.text('Dans 1 min'));
    await tester.pumpAndSettle();

    expect(fakePlugin.scheduled.length, 1);
    expect(fakePlugin.scheduled.first['title'], 'Test de sonnerie Angela Déesse');

    // Dialogue d'information présent
    expect(find.text('Test programmé'), findsOneWidget);
    expect(find.textContaining('Une alarme de test retentira dans 1 minute'), findsOneWidget);

    await tester.tap(find.text('Compris'));
    await tester.pumpAndSettle();
    expect(find.text('Test programmé'), findsNothing);
  });

  testWidgets('SettingsScreen affiche l\'accès au guide des rappels et l\'ouvre au clic', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final fakePlugin = FakeFlutterLocalNotificationsPlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);
    addTearDown(reminderService.dispose);
    final store = AppStore(db: db);

    await tester.pumpWidget(
      buildTestableWidget(
        child: SettingsScreen(onMenu: () {}),
        reminderService: reminderService,
        store: store,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pour que les rappels sonnent'), findsOneWidget);
    expect(find.text('Guide de réglages et test de sonnerie'), findsOneWidget);

    await tester.tap(find.text('Pour que les rappels sonnent'));
    await tester.pumpAndSettle();

    // Écran ReminderGuideScreen ouvert
    expect(find.text('Tester la sonnerie d\'alarme'), findsOneWidget);
  });
}
