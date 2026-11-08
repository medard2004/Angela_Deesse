import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:angela_dress/data/db/app_database.dart' hide Order, Client;
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/repositories/notification_log_repository.dart';
import 'package:angela_dress/data/services/notification_center_service.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/screens/notifications_screen.dart';
import 'package:angela_dress/widgets/common.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  Widget buildTestableWidget({
    required Widget child,
    required AppStore store,
    required NotificationCenterService notifService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStore>.value(value: store),
        ChangeNotifierProvider<NotificationCenterService>.value(value: notifService),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('État vide bienveillant : "Tout est à jour à l\'atelier" quand aucune alerte ni historique', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifService = await NotificationCenterService.create(prefs);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = AppStore(db: db);
    await store.init(seedDemo: false);

    await tester.pumpWidget(
      buildTestableWidget(
        child: NotificationsScreen(onMenu: () {}),
        store: store,
        notifService: notifService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tout est à jour à l\'atelier'), findsOneWidget);
    expect(find.text('Aucune alerte en attente ni rappel manqué.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('Rendu des deux sections : "À faire" et "Historique (30 jours)"', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifService = await NotificationCenterService.create(prefs);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final logRepo = DriftNotificationLogRepository(db: db);
    final store = AppStore(db: db, notificationLogRepository: logRepo);
    await store.init(seedDemo: false);

    // 1. Ajouter un client et une commande pour générer une alerte courante "À faire"
    final now = DateTime.now();
    final client = Client(id: 'c-1', name: 'Amina Diallo', phone: '+22890000000');
    await store.saveClient(client);
    final order = Order(
      id: 'o-1',
      clientId: client.id,
      title: 'Robe de cocktail',
      price: 35000,
      deliveryDate: now.add(const Duration(days: 1)),
      createdAt: now,
    );
    await store.saveOrder(order);
    await tester.pump(const Duration(milliseconds: 100));

    // 2. Ajouter une entrée passée dans notification_log pour peupler "Historique"
    await logRepo.logEvent(
      channel: 'alarm',
      category: 'fitting',
      title: 'Rappel essayage passé',
      body: 'Amina Diallo · Robe de cocktail',
      alertKeys: ['test_key'],
      scheduledAt: now.subtract(const Duration(days: 2)),
      firedAt: now.subtract(const Duration(days: 2)),
      endedAt: now.subtract(const Duration(days: 2)),
      outcome: 'stopped',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: NotificationsScreen(onMenu: () {}),
        store: store,
        notifService: notifService,
      ),
    );
    await tester.pumpAndSettle();

    // Vérifier présence des 2 sections
    expect(find.text('À faire'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('(30 jours)'), findsOneWidget);

    // Vérifier contenu de "À faire"
    expect(find.text('Livraison demain'), findsOneWidget);

    // Vérifier contenu de "Historique"
    expect(find.text('Rappel essayage passé'), findsOneWidget);
    expect(find.text('Arrêtée'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('Affichage d\'une alarme manquée avec badge d\'alerte et son libellé', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifService = await NotificationCenterService.create(prefs);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final logRepo = DriftNotificationLogRepository(db: db);
    final store = AppStore(db: db, notificationLogRepository: logRepo);
    await store.init(seedDemo: false);

    final scheduledDate = DateTime(2026, 11, 7, 8, 0);
    await logRepo.logEvent(
      channel: 'alarm',
      category: 'delivery',
      title: 'Livraison Robe Mariée',
      body: 'Madame Marguerite',
      alertKeys: ['delivery_missed_1'],
      scheduledAt: scheduledDate,
      firedAt: scheduledDate,
      endedAt: scheduledDate.add(const Duration(minutes: 5)),
      outcome: 'missed',
    );

    await tester.pumpWidget(
      buildTestableWidget(
        child: NotificationsScreen(onMenu: () {}),
        store: store,
        notifService: notifService,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alarme manquée'), findsOneWidget);
    expect(find.text('Livraison Robe Mariée'), findsOneWidget);
    expect(find.text('Madame Marguerite'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });

  testWidgets('Bouton "Tout marquer comme vu" acquitte les alertes et marque le journal comme vu', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final notifService = await NotificationCenterService.create(prefs);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final logRepo = DriftNotificationLogRepository(db: db);
    final store = AppStore(db: db, notificationLogRepository: logRepo);
    await store.init(seedDemo: false);

    final now = DateTime.now();
    final client = Client(id: 'c-2', name: 'Amina Diallo', phone: '+22890000000');
    await store.saveClient(client);
    final order = Order(
      id: 'o-2',
      clientId: client.id,
      title: 'Robe de cérémonie',
      price: 35000,
      deliveryDate: now.add(const Duration(days: 1)),
      createdAt: now,
    );
    await store.saveOrder(order);

    final logged = await logRepo.logEvent(
      channel: 'alarm',
      category: 'fitting',
      title: 'Alarme manquée test',
      body: 'Détail',
      alertKeys: ['key_1'],
      scheduledAt: now.subtract(const Duration(hours: 1)),
      outcome: 'missed',
      seenAt: null,
    );
    expect(logged.seenAt, isNull);

    await tester.pumpWidget(
      buildTestableWidget(
        child: NotificationsScreen(onMenu: () {}),
        store: store,
        notifService: notifService,
      ),
    );
    await tester.pumpAndSettle();

    // Appui sur "Tout marquer comme vu"
    await tester.tap(find.byWidgetPredicate((w) => w is IconBox && w.tooltip == 'Tout marquer comme vu'));
    await tester.pumpAndSettle();

    // Vérifier que le journal a été marqué comme vu dans la base
    final updatedLog = await logRepo.getById(logged.id);
    expect(updatedLog?.seenAt, isNotNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
