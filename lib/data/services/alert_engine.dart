import '../models.dart';
import '../repositories/settings_repository.dart';
import '../utils/alert_strings.dart';

/// Familles d'alertes prises en charge par le moteur unique.
enum AlertFamily {
  delivery,
  fitting,
  apprenticeDue,
  pendingBalance,
}

/// Étape temporelle de l'alerte (incluse dans la clé stable).
enum AlertStage {
  overdue, // En retard / Dépassée
  today, // Aujourd'hui
  tomorrow, // Demain
  upcoming, // Dans 2 jours ou à venir (<= 7 jours)
  ready, // Prête / En attente
}

/// Sévérité de l'alerte pour le tri : retard > aujourd'hui > demain > à venir > info.
enum AlertSeverity {
  late, // 0 : priorité maximale
  today, // 1 : aujourd'hui
  tomorrow, // 2 : demain
  upcoming, // 3 : dans 2 jours / à venir
  info, // 4 : solde ou info
}

/// Représentation unifiée et immuable d'une alerte in-app.
class AppAlert {
  const AppAlert({
    required this.key,
    required this.family,
    required this.stage,
    required this.severity,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetId,
    required this.targetDate,
    required this.clientName,
    required this.clientPhone,
    required this.entityTitle,
    required this.remainingAmount,
    this.orderStatus,
    this.fittingDate,
    this.deliveryDate,
    this.nextDueDate,
  });

  /// Clé stable sous la forme « famille:étape:idEntité:jourCible »
  final String key;
  final AlertFamily family;
  final AlertStage stage;
  final AlertSeverity severity;
  final String title;

  /// Corps sans aucun montant pour préserver la confidentialité.
  final String body;

  /// Cible : 'order' ou 'apprentice'
  final String targetType;
  final String targetId;
  final DateTime targetDate;

  // Données contextuelles pour affichage et actions (WhatsApp / navigation)
  final String clientName;
  final String clientPhone;
  final String entityTitle;
  final int remainingAmount;
  final OrderStatus? orderStatus;
  final DateTime? fittingDate;
  final DateTime? deliveryDate;
  final DateTime? nextDueDate;

  @override
  String toString() => 'AppAlert(key: $key, title: $title, severity: $severity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppAlert && other.key == key);

  @override
  int get hashCode => key.hashCode;
}

/// Représentation d'un rappel système planifié (push local).
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.scheduledAt,
    required this.alertKey,
    required this.family,
    required this.stage,
    required this.title,
    required this.body,
    required this.entityId,
    this.publicTitle,
    this.publicBody,
    this.isAlarm = false,
  });

  final String id;
  final DateTime scheduledAt;
  final String alertKey;
  final AlertFamily family;
  final AlertStage stage;
  final String title;
  final String body;
  final String entityId;
  final String? publicTitle;
  final String? publicBody;
  final bool isAlarm;

  String get effectivePublicTitle => publicTitle ?? title;
  String get effectivePublicBody =>
      publicBody ??
      (family == AlertFamily.apprenticeDue
          ? AlertStrings.publicBodyForApprentices(1)
          : AlertStrings.publicBodyForOrders(1));

  @override
  String toString() =>
      'PlannedReminder(id: $id, scheduledAt: $scheduledAt, alertKey: $alertKey, isAlarm: $isAlarm)';
}

/// Notification système groupée prête pour le planificateur Android (Décision 15).
class GroupedReminder {
  const GroupedReminder({
    required this.id,
    required this.scheduledAt,
    required this.title,
    required this.body,
    required this.alertKeys,
    required this.isGroup,
    this.publicTitle,
    this.publicBody,
    this.isAlarm = false,
  });

  /// Identifiant entier 31-bit stable sans collision pour le système Android.
  final int id;
  final DateTime scheduledAt;
  final String title;
  final String body;
  final List<String> alertKeys;
  final bool isGroup;
  final String? publicTitle;
  final String? publicBody;
  final bool isAlarm;

  String get effectivePublicTitle => publicTitle ?? title;
  String get effectivePublicBody => publicBody ?? body;

  @override
  String toString() =>
      'GroupedReminder(id: $id, scheduledAt: $scheduledAt, title: $title, count: ${alertKeys.length}, isAlarm: $isAlarm)';
}

/// Moteur d'alertes unique (Dart pur, sans dépendance de plugin).
/// Alimente l'accueil, NotificationsScreen et les rappels système planifiés.
class AlertEngine {
  const AlertEngine();

  /// Calcule l'écart en jours calendaires locaux entre deux dates.
  static int calendarDaysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }

  /// Formate une date en chaîne stable YYYY-MM-DD pour la clé de l'alerte.
  static String formatDayKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${h}h$m';
  }

  /// Génère les alertes courantes à l'instant [now] pour l'application.
  List<AppAlert> currentAlerts({
    required DateTime now,
    required List<Order> orders,
    required List<Apprentice> apprentices,
    required Client? Function(String clientId) clientById,
    required int Function(Order order) remainingOfOrder,
    required int Function(Apprentice apprentice) remainingOfApprentice,
  }) {
    final alerts = <AppAlert>[];

    // 1. Commandes actives (non supprimées et non livrées)
    for (final order in orders) {
      if (!order.isActive) continue;

      final client = clientById(order.clientId);
      final clientName = client?.name ?? 'Client';
      final clientPhone = client?.phone ?? '';
      final body = AlertStrings.orderBody(
        clientName: clientName,
        orderTitle: order.title,
      );

      // (a) Essayages
      final f = order.fittingDate;
      if (f != null) {
        final fDiff = calendarDaysBetween(now, f);
        final timeStr = (f.hour != 0 || f.minute != 0) ? _formatTime(f) : null;
        final fDayKey = formatDayKey(f);

        if (fDiff == 0) {
          alerts.add(AppAlert(
            key: 'essayage:aujourdhui:${order.id}:$fDayKey',
            family: AlertFamily.fitting,
            stage: AlertStage.today,
            severity: AlertSeverity.today,
            title: AlertStrings.fittingToday(timeStr),
            body: body,
            targetType: 'order',
            targetId: order.id,
            targetDate: f,
            clientName: clientName,
            clientPhone: clientPhone,
            entityTitle: order.title,
            remainingAmount: remainingOfOrder(order),
            orderStatus: order.status,
            fittingDate: f,
            deliveryDate: order.deliveryDate,
          ));
        } else if (fDiff == 1) {
          alerts.add(AppAlert(
            key: 'essayage:demain:${order.id}:$fDayKey',
            family: AlertFamily.fitting,
            stage: AlertStage.tomorrow,
            severity: AlertSeverity.tomorrow,
            title: AlertStrings.fittingTomorrow(timeStr),
            body: body,
            targetType: 'order',
            targetId: order.id,
            targetDate: f,
            clientName: clientName,
            clientPhone: clientPhone,
            entityTitle: order.title,
            remainingAmount: remainingOfOrder(order),
            orderStatus: order.status,
            fittingDate: f,
            deliveryDate: order.deliveryDate,
          ));
        }
      }

      // (b) Livraisons
      final d = order.deliveryDate;
      final dDiff = calendarDaysBetween(now, d);
      final dDayKey = formatDayKey(d);

      if (dDiff < 0) {
        alerts.add(AppAlert(
          key: 'livraison:retard:${order.id}:$dDayKey',
          family: AlertFamily.delivery,
          stage: AlertStage.overdue,
          severity: AlertSeverity.late,
          title: AlertStrings.deliveryOverdue,
          body: body,
          targetType: 'order',
          targetId: order.id,
          targetDate: d,
          clientName: clientName,
          clientPhone: clientPhone,
          entityTitle: order.title,
          remainingAmount: remainingOfOrder(order),
          orderStatus: order.status,
          deliveryDate: d,
        ));
      } else if (dDiff == 0) {
        alerts.add(AppAlert(
          key: 'livraison:aujourdhui:${order.id}:$dDayKey',
          family: AlertFamily.delivery,
          stage: AlertStage.today,
          severity: AlertSeverity.today,
          title: AlertStrings.deliveryToday,
          body: body,
          targetType: 'order',
          targetId: order.id,
          targetDate: d,
          clientName: clientName,
          clientPhone: clientPhone,
          entityTitle: order.title,
          remainingAmount: remainingOfOrder(order),
          orderStatus: order.status,
          deliveryDate: d,
        ));
      } else if (dDiff == 1) {
        alerts.add(AppAlert(
          key: 'livraison:demain:${order.id}:$dDayKey',
          family: AlertFamily.delivery,
          stage: AlertStage.tomorrow,
          severity: AlertSeverity.tomorrow,
          title: AlertStrings.deliveryTomorrow,
          body: body,
          targetType: 'order',
          targetId: order.id,
          targetDate: d,
          clientName: clientName,
          clientPhone: clientPhone,
          entityTitle: order.title,
          remainingAmount: remainingOfOrder(order),
          orderStatus: order.status,
          deliveryDate: d,
        ));
      } else if (dDiff == 2) {
        alerts.add(AppAlert(
          key: 'livraison:dans_2_jours:${order.id}:$dDayKey',
          family: AlertFamily.delivery,
          stage: AlertStage.upcoming,
          severity: AlertSeverity.upcoming,
          title: AlertStrings.deliveryIn2Days,
          body: body,
          targetType: 'order',
          targetId: order.id,
          targetDate: d,
          clientName: clientName,
          clientPhone: clientPhone,
          entityTitle: order.title,
          remainingAmount: remainingOfOrder(order),
          orderStatus: order.status,
          deliveryDate: d,
        ));
      }

      // (c) Soldes en attente (commande prête et solde restant > 0)
      final remOrder = remainingOfOrder(order);
      if (order.status == OrderStatus.prete && remOrder > 0) {
        alerts.add(AppAlert(
          key: 'solde_du:solde:${order.id}:$dDayKey',
          family: AlertFamily.pendingBalance,
          stage: AlertStage.ready,
          severity: AlertSeverity.info,
          title: AlertStrings.pendingBalance,
          body: body,
          targetType: 'order',
          targetId: order.id,
          targetDate: d,
          clientName: clientName,
          clientPhone: clientPhone,
          entityTitle: order.title,
          remainingAmount: remOrder,
          orderStatus: order.status,
          deliveryDate: d,
        ));
      }
    }

    // 2. Échéances d'apprentis
    for (final apprentice in apprentices) {
      final rem = remainingOfApprentice(apprentice);
      final due = apprentice.nextDue;
      if (due == null || rem <= 0) continue;

      final diff = calendarDaysBetween(now, due);
      final dueDayKey = formatDayKey(due);
      final body = AlertStrings.apprenticeBody(apprenticeName: apprentice.name);

      if (diff < 0) {
        alerts.add(AppAlert(
          key: 'echeance_apprenti:retard:${apprentice.id}:$dueDayKey',
          family: AlertFamily.apprenticeDue,
          stage: AlertStage.overdue,
          severity: AlertSeverity.late,
          title: AlertStrings.apprenticeOverdue,
          body: body,
          targetType: 'apprentice',
          targetId: apprentice.id,
          targetDate: due,
          clientName: apprentice.name,
          clientPhone: apprentice.phone,
          entityTitle: apprentice.name,
          remainingAmount: rem,
          nextDueDate: due,
        ));
      } else if (diff == 0) {
        alerts.add(AppAlert(
          key: 'echeance_apprenti:aujourdhui:${apprentice.id}:$dueDayKey',
          family: AlertFamily.apprenticeDue,
          stage: AlertStage.today,
          severity: AlertSeverity.today,
          title: AlertStrings.apprenticeToday,
          body: body,
          targetType: 'apprentice',
          targetId: apprentice.id,
          targetDate: due,
          clientName: apprentice.name,
          clientPhone: apprentice.phone,
          entityTitle: apprentice.name,
          remainingAmount: rem,
          nextDueDate: due,
        ));
      } else if (diff == 1) {
        alerts.add(AppAlert(
          key: 'echeance_apprenti:demain:${apprentice.id}:$dueDayKey',
          family: AlertFamily.apprenticeDue,
          stage: AlertStage.tomorrow,
          severity: AlertSeverity.tomorrow,
          title: AlertStrings.apprenticeTomorrow,
          body: body,
          targetType: 'apprentice',
          targetId: apprentice.id,
          targetDate: due,
          clientName: apprentice.name,
          clientPhone: apprentice.phone,
          entityTitle: apprentice.name,
          remainingAmount: rem,
          nextDueDate: due,
        ));
      } else if (diff >= 2 && diff <= 7) {
        alerts.add(AppAlert(
          key: 'echeance_apprenti:dans_${diff}_jours:${apprentice.id}:$dueDayKey',
          family: AlertFamily.apprenticeDue,
          stage: AlertStage.upcoming,
          severity: AlertSeverity.upcoming,
          title: AlertStrings.apprenticeInDays(diff),
          body: body,
          targetType: 'apprentice',
          targetId: apprentice.id,
          targetDate: due,
          clientName: apprentice.name,
          clientPhone: apprentice.phone,
          entityTitle: apprentice.name,
          remainingAmount: rem,
          nextDueDate: due,
        ));
      }
    }

    // Tri stable : sévérité (late > today > tomorrow > upcoming > info) puis date puis clé
    alerts.sort((a, b) {
      final s = a.severity.index.compareTo(b.severity.index);
      if (s != 0) return s;
      final d = a.targetDate.compareTo(b.targetDate);
      if (d != 0) return d;
      return a.key.compareTo(b.key);
    });

    return alerts;
  }

  /// Génère les rappels système planifiés pour le système Android (push local).
  /// Fenêtre glissante de 45 jours, rien dans le passé, respect des interrupteurs.
  List<PlannedReminder> plannedReminders({
    required DateTime now,
    required List<Order> orders,
    required List<Apprentice> apprentices,
    required Client? Function(String clientId) clientById,
    required int Function(Order order) remainingOfOrder,
    required int Function(Apprentice apprentice) remainingOfApprentice,
    bool deliveryEnabled = true,
    bool fittingEnabled = true,
    bool paymentsEnabled = true,
    bool apprenticeEnabled = true,
    ReminderMode? deliveryMode,
    ReminderMode? fittingMode,
    ReminderMode? paymentsMode,
    ReminderMode? apprenticeMode,
    int maxWindowDays = 45,
  }) {
    final dMode = deliveryMode ?? (deliveryEnabled ? ReminderMode.alarm : ReminderMode.none);
    final fMode = fittingMode ?? (fittingEnabled ? ReminderMode.alarm : ReminderMode.none);
    final aMode = apprenticeMode ?? (apprenticeEnabled ? ReminderMode.alarm : ReminderMode.none);

    final reminders = <PlannedReminder>[];
    final maxDate = now.add(Duration(days: maxWindowDays));

    for (final order in orders) {
      if (!order.isActive) continue;

      final client = clientById(order.clientId);
      final clientName = client?.name ?? 'Client';
      final body = AlertStrings.orderBody(
        clientName: clientName,
        orderTitle: order.title,
      );

      // (a) Rappels d'essayage
      final f = order.fittingDate;
      if (fMode != ReminderMode.none && f != null) {
        final fDayKey = formatDayKey(f);
        final timeStr = (f.hour != 0 || f.minute != 0) ? _formatTime(f) : null;
        final isAlarm = fMode == ReminderMode.alarm;

        // La veille à 18:00
        final eve = DateTime(f.year, f.month, f.day - 1, 18, 0);
        if (eve.isAfter(now) && !eve.isAfter(maxDate)) {
          final title = AlertStrings.fittingTomorrow(timeStr);
          reminders.add(PlannedReminder(
            id: 'fitting_eve_${order.id}_$fDayKey',
            scheduledAt: eve,
            alertKey: 'essayage:demain:${order.id}:$fDayKey',
            family: AlertFamily.fitting,
            stage: AlertStage.tomorrow,
            title: title,
            body: body,
            publicTitle: title,
            publicBody: AlertStrings.publicBodyForOrders(1),
            entityId: order.id,
            isAlarm: isAlarm,
          ));
        }

        // Le jour même : 1h avant si heure fixée, sinon 08:00
        final sameDay = (f.hour != 0 || f.minute != 0)
            ? f.subtract(const Duration(hours: 1))
            : DateTime(f.year, f.month, f.day, 8, 0);
        if (sameDay.isAfter(now) && !sameDay.isAfter(maxDate)) {
          final title = AlertStrings.fittingToday(timeStr);
          reminders.add(PlannedReminder(
            id: 'fitting_day_${order.id}_$fDayKey',
            scheduledAt: sameDay,
            alertKey: 'essayage:aujourdhui:${order.id}:$fDayKey',
            family: AlertFamily.fitting,
            stage: AlertStage.today,
            title: title,
            body: body,
            publicTitle: title,
            publicBody: AlertStrings.publicBodyForOrders(1),
            entityId: order.id,
            isAlarm: isAlarm,
          ));
        }
      }

      // (b) Rappels de livraison
      if (dMode != ReminderMode.none) {
        final d = order.deliveryDate;
        final dDayKey = formatDayKey(d);
        final isAlarm = dMode == ReminderMode.alarm;

        // La veille à 18:00
        final eve = DateTime(d.year, d.month, d.day - 1, 18, 0);
        if (eve.isAfter(now) && !eve.isAfter(maxDate)) {
          reminders.add(PlannedReminder(
            id: 'delivery_eve_${order.id}_$dDayKey',
            scheduledAt: eve,
            alertKey: 'livraison:demain:${order.id}:$dDayKey',
            family: AlertFamily.delivery,
            stage: AlertStage.tomorrow,
            title: AlertStrings.deliveryTomorrow,
            body: body,
            publicTitle: AlertStrings.deliveryTomorrow,
            publicBody: AlertStrings.publicBodyForOrders(1),
            entityId: order.id,
            isAlarm: isAlarm,
          ));
        }

        // Le jour même à 08:00
        final day = DateTime(d.year, d.month, d.day, 8, 0);
        if (day.isAfter(now) && !day.isAfter(maxDate)) {
          reminders.add(PlannedReminder(
            id: 'delivery_day_${order.id}_$dDayKey',
            scheduledAt: day,
            alertKey: 'livraison:aujourdhui:${order.id}:$dDayKey',
            family: AlertFamily.delivery,
            stage: AlertStage.today,
            title: AlertStrings.deliveryToday,
            body: body,
            publicTitle: AlertStrings.deliveryToday,
            publicBody: AlertStrings.publicBodyForOrders(1),
            entityId: order.id,
            isAlarm: isAlarm,
          ));
        }
      }
    }

    // (c) Rappels d'échéance apprenti
    if (aMode != ReminderMode.none) {
      final isAlarm = aMode == ReminderMode.alarm;
      for (final apprentice in apprentices) {
        final rem = remainingOfApprentice(apprentice);
        final due = apprentice.nextDue;
        if (due == null || rem <= 0) continue;

        final dueDayKey = formatDayKey(due);
        final body = AlertStrings.apprenticeBody(apprenticeName: apprentice.name);

        // Le jour même à 08:00
        final day = DateTime(due.year, due.month, due.day, 8, 0);
        if (day.isAfter(now) && !day.isAfter(maxDate)) {
          reminders.add(PlannedReminder(
            id: 'apprentice_due_${apprentice.id}_$dueDayKey',
            scheduledAt: day,
            alertKey: 'echeance_apprenti:aujourdhui:${apprentice.id}:$dueDayKey',
            family: AlertFamily.apprenticeDue,
            stage: AlertStage.today,
            title: AlertStrings.apprenticeToday,
            body: body,
            publicTitle: AlertStrings.apprenticeToday,
            publicBody: AlertStrings.publicBodyForApprentices(1),
            entityId: apprentice.id,
            isAlarm: isAlarm,
          ));
        }
      }
    }

    reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return reminders;
  }

  /// Génère les rappels système groupés par instant à la minute (Décision 15).
  /// Fusion anti-fatigue : n=1 rappel individuel, n>=2 titre « n rappels » et corps en lignes.
  /// Plafond de 120 notifications, les plus proches d'abord.
  List<GroupedReminder> groupedPlannedReminders({
    required DateTime now,
    required List<Order> orders,
    required List<Apprentice> apprentices,
    required Client? Function(String clientId) clientById,
    required int Function(Order order) remainingOfOrder,
    required int Function(Apprentice apprentice) remainingOfApprentice,
    bool deliveryEnabled = true,
    bool fittingEnabled = true,
    bool paymentsEnabled = true,
    bool apprenticeEnabled = true,
    ReminderMode? deliveryMode,
    ReminderMode? fittingMode,
    ReminderMode? paymentsMode,
    ReminderMode? apprenticeMode,
    int maxWindowDays = 45,
    int maxReminders = 120,
  }) {
    final raw = plannedReminders(
      now: now,
      orders: orders,
      apprentices: apprentices,
      clientById: clientById,
      remainingOfOrder: remainingOfOrder,
      remainingOfApprentice: remainingOfApprentice,
      deliveryEnabled: deliveryEnabled,
      fittingEnabled: fittingEnabled,
      paymentsEnabled: paymentsEnabled,
      apprenticeEnabled: apprenticeEnabled,
      deliveryMode: deliveryMode,
      fittingMode: fittingMode,
      paymentsMode: paymentsMode,
      apprenticeMode: apprenticeMode,
      maxWindowDays: maxWindowDays,
    );

    if (raw.isEmpty) return const [];

    // Regroupement par instant à la minute
    final groups = <DateTime, List<PlannedReminder>>{};
    for (final r in raw) {
      final minute = DateTime(
        r.scheduledAt.year,
        r.scheduledAt.month,
        r.scheduledAt.day,
        r.scheduledAt.hour,
        r.scheduledAt.minute,
      );
      groups.putIfAbsent(minute, () => []).add(r);
    }

    final sortedMinutes = groups.keys.toList()..sort();
    final result = <GroupedReminder>[];

    for (final minute in sortedMinutes) {
      if (result.length >= maxReminders) break;

      final items = groups[minute]!;
      // Identifiant entier 31-bit positif dérivé de la minute
      final int id = (minute.millisecondsSinceEpoch ~/ 60000) & 0x7FFFFFFF;
      final anyAlarm = items.any((r) => r.isAlarm);

      if (items.length == 1) {
        final single = items.first;
        result.add(GroupedReminder(
          id: id,
          scheduledAt: single.scheduledAt,
          title: single.title,
          body: single.body,
          publicTitle: single.effectivePublicTitle,
          publicBody: single.effectivePublicBody,
          alertKeys: [single.alertKey],
          isGroup: false,
          isAlarm: anyAlarm,
        ));
      } else {
        final title = '${items.length} rappels';
        final lines = <String>[];
        for (var i = 0; i < items.length && i < 4; i++) {
          lines.add('• ${items[i].title} : ${items[i].body}');
        }
        if (items.length > 4) {
          lines.add('+ ${items.length - 4} autres');
        }

        final orderCount = items
            .where((i) => i.family == AlertFamily.delivery || i.family == AlertFamily.fitting)
            .length;
        final apprenticeCount =
            items.where((i) => i.family == AlertFamily.apprenticeDue).length;
        final pubBody = AlertStrings.publicBodyForCount(
          orderCount: orderCount,
          apprenticeCount: apprenticeCount,
        );

        result.add(GroupedReminder(
          id: id,
          scheduledAt: minute,
          title: title,
          body: lines.join('\n'),
          publicTitle: title,
          publicBody: pubBody,
          alertKeys: items.map((e) => e.alertKey).toList(),
          isGroup: true,
          isAlarm: anyAlarm,
        ));
      }
    }

    return result;
  }
}

