import 'package:angela_dress/data/services/system_reminder_service.dart';
import 'package:angela_dress/screens/alarm_ringing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class _FakePlugin extends Fake implements FlutterLocalNotificationsPlugin {
  final List<int> cancelled = [];
  final List<Map<String, dynamic>> scheduled = [];

  @override
  Future<void> cancel({
    required int id,
    String? tag,
  }) async {
    cancelled.add(id);
  }

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
  }) async {
    scheduled.add({
      'id': id,
      'title': title,
      'body': body,
      'scheduledDate': scheduledDate,
      'payload': payload,
    });
  }
}

void main() {
  setUpAll(() {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Africa/Lome'));
    } catch (_) {}
  });

  testWidgets('AlarmRingingScreen affiche les informations d\'alarme et les boutons d\'action', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakePlugin = _FakePlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SystemReminderService>.value(value: reminderService),
        ],
        child: const MaterialApp(
          home: AlarmRingingScreen(
            title: 'Livraison Robe de Mariée',
            body: 'Amina Sow - Reste: 15 000 F CFA',
            notificationId: 42,
            timeoutSeconds: 60,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Titre et contenu de l'alarme
    expect(find.text('Livraison Robe de Mariée'), findsOneWidget);
    expect(find.text('Amina Sow - Reste: 15 000 F CFA'), findsOneWidget);
    expect(find.text('RAPPEL D\'ATELIER EN DIRECT'), findsOneWidget);

    // Boutons d'action
    expect(find.text('ARRÊTER'), findsOneWidget);
    expect(find.text('Reporter 10m'), findsOneWidget);

    // Compteur d'arrêt automatique
    expect(find.textContaining('Arrêt automatique dans 60s'), findsOneWidget);
  });

  testWidgets('Cliquer sur ARRÊTER ferme l\'alarme et annule la sonnerie', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakePlugin = _FakePlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SystemReminderService>.value(value: reminderService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AlarmRingingScreen(
                        title: 'Alerte Essayage',
                        body: 'Fanta Keita',
                        notificationId: 99,
                      ),
                    ),
                  );
                },
                child: const Text('Ouvrir alarme'),
              ),
            ),
          ),
        ),
      ),
    );

    // Ouvrir l'alarme
    await tester.tap(find.text('Ouvrir alarme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Alerte Essayage'), findsOneWidget);

    // Cliquer sur Arrêter
    await tester.tap(find.text('ARRÊTER'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // L'écran d'alarme est fermé
    expect(find.text('Alerte Essayage'), findsNothing);
    expect(fakePlugin.cancelled, contains(99));
  });

  testWidgets('Cliquer sur Reporter 10m replanifie l\'alarme et ferme l\'écran', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakePlugin = _FakePlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SystemReminderService>.value(value: reminderService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AlarmRingingScreen(
                        title: 'Paiement en attente',
                        body: 'Mariam Traoré',
                        notificationId: 77,
                      ),
                    ),
                  );
                },
                child: const Text('Ouvrir alarme'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir alarme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Paiement en attente'), findsOneWidget);

    // Reporter 10m
    await tester.tap(find.text('Reporter 10m'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Paiement en attente'), findsNothing);
    expect(fakePlugin.cancelled, contains(77));
    expect(fakePlugin.scheduled, isNotEmpty);
  });

  testWidgets('Arrêt automatique au bout du délai imparti (timeoutSeconds configuré)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakePlugin = _FakePlugin();
    final reminderService = SystemReminderService(plugin: fakePlugin);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SystemReminderService>.value(value: reminderService),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AlarmRingingScreen(
                        title: 'Timeout Alarme',
                        body: 'Événement',
                        notificationId: 55,
                        timeoutSeconds: 2,
                      ),
                    ),
                  );
                },
                child: const Text('Ouvrir alarme'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir alarme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Timeout Alarme'), findsOneWidget);

    // Avancer le temps de 1 seconde
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Arrêt automatique dans 1s'), findsOneWidget);

    // Avancer d'une autre seconde pour déclencher le timeout
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // L'écran s'est auto-fermé
    expect(find.text('Timeout Alarme'), findsNothing);
  });
}
