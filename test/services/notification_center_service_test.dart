import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:angela_dress/data/services/alert_engine.dart';
import 'package:angela_dress/data/services/notification_center_service.dart';

void main() {
  group('NotificationCenterService (Partie B)', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('Initialisation avec SharedPreferences vide', () async {
      final service = NotificationCenterService(prefs);
      expect(service.isRead('test-key'), isFalse);
      expect(service.debugReadMap, isEmpty);
    });

    test('Marquer une alerte comme lue persiste dans SharedPreferences hors SQLite', () async {
      final service = NotificationCenterService(prefs);
      expect(service.isRead('alert:1'), isFalse);

      var notified = false;
      service.addListener(() => notified = true);

      await service.markAsRead('alert:1');

      expect(service.isRead('alert:1'), isTrue);
      expect(notified, isTrue);

      // Vérifier le stockage direct dans SharedPreferences sous forme JSON
      final raw = prefs.getString(NotificationCenterService.kStorageKey);
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded.containsKey('alert:1'), isTrue);
      expect(decoded['alert:1'], isA<int>());
    });

    test('Tout marquer comme vu enregistre toutes les clés actives', () async {
      final service = NotificationCenterService(prefs);
      final keys = ['k1', 'k2', 'k3'];

      var notificationCount = 0;
      service.addListener(() => notificationCount++);

      await service.markAllAsRead(keys);

      expect(service.isRead('k1'), isTrue);
      expect(service.isRead('k2'), isTrue);
      expect(service.isRead('k3'), isTrue);
      expect(service.isRead('k4'), isFalse);
      expect(notificationCount, equals(1));
    });

    test('Calcul du compteur unreadCount avec des alertes AppAlert', () {
      final service = NotificationCenterService(prefs);
      final now = DateTime(2026, 11, 6);

      final a1 = AppAlert(
        key: 'key-1',
        family: AlertFamily.delivery,
        stage: AlertStage.today,
        severity: AlertSeverity.today,
        title: 'Livraison 1',
        body: 'Client 1 · Robe',
        targetType: 'order',
        targetId: 'ord-1',
        targetDate: now,
        clientName: 'Client 1',
        clientPhone: '',
        entityTitle: 'Robe',
        remainingAmount: 0,
      );

      final a2 = AppAlert(
        key: 'key-2',
        family: AlertFamily.fitting,
        stage: AlertStage.today,
        severity: AlertSeverity.today,
        title: 'Essayage 2',
        body: 'Client 2 · Pagne',
        targetType: 'order',
        targetId: 'ord-2',
        targetDate: now,
        clientName: 'Client 2',
        clientPhone: '',
        entityTitle: 'Pagne',
        remainingAmount: 0,
      );

      expect(service.unreadCount([a1, a2]), equals(2));

      service.markAsRead('key-1');
      expect(service.unreadCount([a1, a2]), equals(1));

      service.markAsRead('key-2');
      expect(service.unreadCount([a1, a2]), equals(0));
    });

    test('Nettoyage (prune) : supprime les clés disparues et celles de plus de 60 jours', () async {
      final now = DateTime(2026, 11, 6, 12, 0);
      final initialMap = {
        // Clé active et récente (< 60 jours) -> DOIT ÊTRE CONSERVÉE
        'active_recent': now.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
        // Clé active mais vieille de 70 jours (> 60 jours) -> DOIT ÊTRE SUPPRIMÉE
        'active_too_old': now.subtract(const Duration(days: 70)).millisecondsSinceEpoch,
        // Clé disparue des alertes actives -> DOIT ÊTRE SUPPRIMÉE
        'disappeared': now.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
      };

      await prefs.setString(NotificationCenterService.kStorageKey, jsonEncode(initialMap));
      final service = NotificationCenterService(prefs);

      expect(service.isRead('active_recent'), isTrue);
      expect(service.isRead('active_too_old'), isTrue);
      expect(service.isRead('disappeared'), isTrue);

      await service.prune(
        activeKeys: {'active_recent', 'active_too_old'},
        now: now,
      );

      expect(service.isRead('active_recent'), isTrue);
      expect(service.isRead('active_too_old'), isFalse);
      expect(service.isRead('disappeared'), isFalse);
    });

    test('pendingOpenNotifications mémorise la destination pour post-déverrouillage', () {
      NotificationCenterService.pendingOpenNotifications = true;
      expect(NotificationCenterService.pendingOpenNotifications, isTrue);

      // Simulation de la consommation par AppShell
      NotificationCenterService.pendingOpenNotifications = false;
      expect(NotificationCenterService.pendingOpenNotifications, isFalse);
    });
  });
}

