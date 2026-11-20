import 'package:angela_dress/data/db/app_database.dart';
import 'package:angela_dress/data/services/app_lock_manager.dart';
import 'package:angela_dress/data/services/contact_launcher.dart';
import 'package:angela_dress/data/services/external_action_tracker.dart';
import 'package:angela_dress/data/services/notification_center_service.dart';
import 'package:angela_dress/data/services/pin_security_service.dart';
import 'package:angela_dress/data/services/secure_storage.dart';
import 'package:angela_dress/data/services/system_reminder_service.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/screens/lock_screen.dart';
import 'package:angela_dress/screens/settings_screen.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<int>> fastTestDeriver({
  required String secret,
  required List<int> salt,
  required int iterations,
}) async {
  final bytes = utf8.encode('$secret:${salt.join(',')}');
  return sha256.convert(bytes).bytes;
}

class _FakePlugin extends Fake implements FlutterLocalNotificationsPlugin {
  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async => [];
}

class _InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _data.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('Possibilité d\'ignorer la création du code PIN au premier lancement', () {
    late _InMemorySecureStorage storage;
    late PinSecurityService pinService;
    late ExternalActionTracker tracker;
    late AppLockManager lockManager;
    late AppDatabase db;
    late AppStore store;
    late NotificationCenterService notifService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      notifService = NotificationCenterService(prefs);
      storage = _InMemorySecureStorage();
      pinService = PinSecurityService(
        storage: storage,
        iterations: 1000,
        deriver: fastTestDeriver,
      );
      tracker = ExternalActionTracker();
      lockManager = AppLockManager(securityService: pinService, tracker: tracker);
      db = AppDatabase(NativeDatabase.memory());
      store = AppStore(db: db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('LockScreen en mode création racine affiche le bouton Ignorer et le lien plus tard', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStore>.value(value: store),
            ChangeNotifierProvider<NotificationCenterService>.value(value: notifService),
            Provider<ContactLauncher?>.value(value: null),
            Provider<PinSecurityService>.value(value: pinService),
            Provider<AppLockManager>.value(value: lockManager),
          ],
          child: const MaterialApp(
            home: LockScreen(
              mode: LockMode.create,
              isRoot: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ignorer'), findsOneWidget);
      expect(find.text('Définir plus tard dans les paramètres'), findsOneWidget);
      expect(lockManager.isLocked, isTrue);

      // Clic sur Ignorer
      await tester.tap(find.text('Ignorer'));
      await tester.pumpAndSettle();

      // Vérifie que l'app a été déverrouillée et le flag SharedPreferences enregistré
      expect(lockManager.isLocked, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('has_skipped_pin_setup'), isTrue);
    });
  });

  group('Gestion du code PIN dans SettingsScreen', () {
    late _InMemorySecureStorage storage;
    late PinSecurityService pinService;
    late AppDatabase db;
    late AppStore store;
    late SystemReminderService reminderService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storage = _InMemorySecureStorage();
      pinService = PinSecurityService(
        storage: storage,
        iterations: 1000,
        deriver: fastTestDeriver,
      );
      db = AppDatabase(NativeDatabase.memory());
      store = AppStore(db: db);
      reminderService = SystemReminderService(plugin: _FakePlugin());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('SettingsScreen affiche Créer un code d\'accès et Non défini si aucun PIN', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStore>.value(value: store),
            Provider<SystemReminderService>.value(value: reminderService),
            Provider<PinSecurityService?>.value(value: pinService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsScreen(onMenu: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Créer un code d\'accès'), findsOneWidget);
      expect(find.text('Non défini'), findsOneWidget);
      expect(find.text('Changer le code d\'accès'), findsNothing);
    });

    testWidgets('SettingsScreen affiche Changer le code d\'accès si un PIN est déjà configuré', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Simuler un code PIN configuré valide
      await pinService.createPin('4819');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppStore>.value(value: store),
            Provider<SystemReminderService>.value(value: reminderService),
            Provider<PinSecurityService?>.value(value: pinService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SettingsScreen(onMenu: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Changer le code d\'accès'), findsOneWidget);
      expect(find.text('Non défini'), findsNothing);
      expect(find.text('Créer un code d\'accès'), findsNothing);
    });
  });
}
