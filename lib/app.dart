import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_brand.dart';
import 'core/theme.dart';
import 'data/services/app_lock_manager.dart';
import 'data/services/notification_center_service.dart';
import 'data/services/system_reminder_service.dart';
import 'data/store.dart';
import 'screens/lock_screen.dart';
import 'screens/splash_screen.dart';
import 'widgets/in_app_notification_banner.dart';

class AngelaApp extends StatefulWidget {
  const AngelaApp({super.key});

  @override
  State<AngelaApp> createState() => _AngelaAppState();
}

class _AngelaAppState extends State<AngelaApp> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  AppLockManager? _lockManager;
  StreamSubscription<Map<String, dynamic>>? _inAppEventSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Écoute des alarmes et notifications survenant pendant que l'app est active
    _inAppEventSub = SystemReminderService.inAppEventStream.stream.listen((event) {
      if (!mounted) return;
      final lockManager = _lockManager;
      if (lockManager != null && lockManager.isLocked) {
        // Écran de PIN affiché = traité comme arrière-plan, aucun bandeau in-app
        return;
      }
      final title = event['title'] as String? ?? 'Rappel atelier';
      final body = event['body'] as String? ?? '';

      final overlay = _navigatorKey.currentState?.overlay;
      final ctx = _navigatorKey.currentContext;
      if (ctx != null) {
        InAppNotificationBanner.show(
          ctx,
          overlayState: overlay,
          title: title,
          body: body,
          onTap: () {
            try {
              ctx.read<NotificationCenterService?>()?.requestOpenNotifications();
            } catch (_) {}
          },
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final reminderService = context.read<SystemReminderService?>();
        if (reminderService != null) {
          final launchedFromAlarm = await reminderService.nativeBridge.consumeOpenNotifications();
          if (launchedFromAlarm) {
            NotificationCenterService.pendingOpenNotifications = true;
          }
        }
      } catch (_) {}
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final manager = context.read<AppLockManager>();
      if (_lockManager != manager) {
        _lockManager = manager;
        _lockManager!.onLockRequired = _onLockRequired;
      }
    } catch (_) {
      // Ignorer si non fourni dans des tests isolés
    }
  }

  void _onLockRequired() {
    if (!mounted) return;
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => const LockScreen(mode: LockMode.unlock, isRoot: false),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _lockManager?.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _lockManager?.onAppResumed();
      try {
        final reminderService = context.read<SystemReminderService?>();
        reminderService?.drainNativeEvents();
        context.read<AppStore>().rescheduleReminders();
      } catch (_) {
        // En cas de test isolé sans AppStore
      }
    }
  }

  @override
  void dispose() {
    _inAppEventSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: _navigatorKey,
        title: AppBrand.appName,
        onGenerateTitle: (_) => AppBrand.appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      );
}
