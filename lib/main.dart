import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/db/app_database.dart';
import 'data/repositories/notification_log_repository.dart';
import 'data/services/app_lock_manager.dart';
import 'data/services/contact_launcher.dart';
import 'data/services/external_action_tracker.dart';
import 'data/services/native_alarm_bridge.dart';
import 'data/services/notification_center_service.dart';
import 'data/services/photo_storage.dart';
import 'data/services/pin_security_service.dart';
import 'data/services/secure_storage.dart';
import 'data/services/system_reminder_service.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));

  final appDb = AppDatabase();
  final notificationLogRepo = DriftNotificationLogRepository(db: appDb);
  final nativeAlarmBridge = const MethodChannelNativeAlarmBridge();

  final externalActionTracker = ExternalActionTracker();
  final photoStorage = DefaultPhotoStorage(tracker: externalActionTracker);
  final contactLauncher = DefaultContactLauncher(tracker: externalActionTracker);
  final secureStorage = const FlutterSecureStorageWrapper();
  await clearKeychainIfFirstRun(secureStorage);
  final pinSecurityService = PinSecurityService(storage: secureStorage);
  final appLockManager = AppLockManager(
    securityService: pinSecurityService,
    tracker: externalActionTracker,
  );
  final notificationCenterService = await NotificationCenterService.create();
  final systemReminderService = SystemReminderService(
    nativeBridge: nativeAlarmBridge,
    logRepo: notificationLogRepo,
  );
  await systemReminderService.init(
    onSelectNotification: (_) {
      notificationCenterService.requestOpenNotifications();
    },
  );
  await systemReminderService.drainNativeEvents();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: appDb),
        Provider<NotificationLogRepository>.value(value: notificationLogRepo),
        Provider<ExternalActionTracker>.value(value: externalActionTracker),
        Provider<PhotoStorage>.value(value: photoStorage),
        Provider<ContactLauncher>.value(value: contactLauncher),
        Provider<SecureStorage>.value(value: secureStorage),
        Provider<PinSecurityService>.value(value: pinSecurityService),
        Provider<AppLockManager>.value(value: appLockManager),
        Provider<SystemReminderService>.value(value: systemReminderService),
        ChangeNotifierProvider<NotificationCenterService>.value(value: notificationCenterService),
        ChangeNotifierProvider(
          create: (_) => AppStore(
            db: appDb,
            notificationLogRepository: notificationLogRepo,
            reminderService: systemReminderService,
          ),
        ),
      ],
      child: const AngelaApp(),
    ),
  );
}
