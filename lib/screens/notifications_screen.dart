import '../data/db/app_database.dart' show NotificationLog;
import '../data/services/alert_engine.dart';
import '../data/services/contact_launcher.dart';
import '../data/services/notification_center_service.dart';
import '../data/utils/message_templates.dart';
import '../ui.dart';
import 'apprentice_detail_screen.dart';
import 'order_detail_screen.dart';

class _Notif {
  _Notif({
    required this.key,
    required this.icon,
    required this.fg,
    required this.bg,
    required this.title,
    required this.sub,
    required this.isLate,
    required this.open,
    this.onWhatsApp,
  });

  final String key;
  final IconData icon;
  final Color fg, bg;
  final String title, sub;
  final bool isLate;
  final void Function(BuildContext) open;
  final Future<void> Function(BuildContext)? onWhatsApp;
}

IconData _notifIcon(AppAlert a) {
  switch (a.family) {
    case AlertFamily.fitting:
      return Icons.schedule_rounded;
    case AlertFamily.pendingBalance:
      return Icons.account_balance_wallet_outlined;
    case AlertFamily.delivery:
      return a.severity == AlertSeverity.late
          ? Icons.warning_amber_rounded
          : Icons.local_shipping_outlined;
    case AlertFamily.apprenticeDue:
      return a.severity == AlertSeverity.late
          ? Icons.warning_amber_rounded
          : Icons.school_outlined;
  }
}

Color _notifFg(AppAlert a) {
  switch (a.family) {
    case AlertFamily.fitting:
      return const Color(0xFFC2570C);
    case AlertFamily.pendingBalance:
      return Pal.cobalt;
    case AlertFamily.delivery:
      return a.severity == AlertSeverity.late ? Pal.thread : Pal.sage;
    case AlertFamily.apprenticeDue:
      return a.severity == AlertSeverity.late ? Pal.thread : Pal.cobalt;
  }
}

Color _notifBg(AppAlert a) {
  switch (a.family) {
    case AlertFamily.fitting:
      return const Color(0xFFFFF0E2);
    case AlertFamily.pendingBalance:
      return const Color(0xFFE8EDFB);
    case AlertFamily.delivery:
      return a.severity == AlertSeverity.late
          ? const Color(0xFFFBE1E3)
          : const Color(0xFFDDF3EA);
    case AlertFamily.apprenticeDue:
      return a.severity == AlertSeverity.late
          ? const Color(0xFFFBE1E3)
          : const Color(0xFFE8EDFB);
  }
}

/// Écran des notifications combinant :
/// 1. Les alertes courantes « À faire »
/// 2. L'historique des 30 derniers jours (avec alarmes manquées en évidence)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final notifService = context.watch<NotificationCenterService?>();
    final logRepo = s.notificationLogRepo;
    final atelier = s.atelierName;

    const engine = AlertEngine();
    final alerts = engine.currentAlerts(
      now: DateTime.now(),
      orders: s.activeOrders,
      apprentices: s.apprentices,
      clientById: s.clientById,
      remainingOfOrder: s.remainingOf,
      remainingOfApprentice: s.apprenticeRemaining,
    );

    // Nettoyage automatique des clés d'alertes obsolètes
    if (notifService != null) {
      notifService.prune(activeKeys: alerts.map((a) => a.key).toSet());
    }

    final items = <_Notif>[];

    for (final a in alerts) {
      void open(BuildContext c) {
        if (a.targetType == 'apprentice') {
          push(c, ApprenticeDetailScreen(apprenticeId: a.targetId));
        } else {
          push(c, OrderDetailScreen(orderId: a.targetId));
        }
      }

      Future<void> onWa(BuildContext c) async {
        final launcher = c.read<ContactLauncher?>();
        if (launcher == null) return;
        final String body;

        switch (a.family) {
          case AlertFamily.fitting:
            body = MessageTemplates.rappelEssayage(
              client: a.clientName,
              orderTitle: a.entityTitle,
              fittingDate: a.fittingDate ?? a.targetDate,
              atelier: atelier,
            );
            break;
          case AlertFamily.delivery:
            if (a.orderStatus == OrderStatus.prete) {
              body = MessageTemplates.commandePrete(
                client: a.clientName,
                orderTitle: a.entityTitle,
                balance: a.remainingAmount,
                atelier: atelier,
              );
            } else {
              body = MessageTemplates.rappelLivraison(
                client: a.clientName,
                orderTitle: a.entityTitle,
                deliveryDate: a.deliveryDate ?? a.targetDate,
                atelier: atelier,
              );
            }
            break;
          case AlertFamily.pendingBalance:
            body = MessageTemplates.rappelSoldeDu(
              client: a.clientName,
              balance: a.remainingAmount,
              atelier: atelier,
            );
            break;
          case AlertFamily.apprenticeDue:
            body = MessageTemplates.echeanceApprenti(
              apprenti: a.clientName,
              dueDate: a.nextDueDate ?? a.targetDate,
              amount: a.remainingAmount,
              atelier: atelier,
            );
            break;
        }

        final res = await launcher.whatsapp(a.clientPhone, body: body);
        if (!res.success && c.mounted) {
          toast(c, res.errorMessage ?? 'Impossible d\'ouvrir WhatsApp');
        }
      }

      items.add(_Notif(
        key: a.key,
        icon: _notifIcon(a),
        fg: _notifFg(a),
        bg: _notifBg(a),
        title: a.title,
        sub: a.body,
        isLate: a.severity == AlertSeverity.late,
        open: open,
        onWhatsApp: a.clientPhone.trim().isNotEmpty ? onWa : null,
      ));
    }

    return SectionPage(
      title: 'Notifications',
      eyebrow: 'Rappels',
      onMenu: widget.onMenu,
      actions: [
        titleAction(
          Icons.done_all_rounded,
          () async {
            notifService?.markAllAsRead(items.map((i) => i.key));
            await logRepo.markAllSeen();
          },
          'Tout marquer comme vu',
        ),
      ],
      child: StreamBuilder<List<NotificationLog>>(
        stream: logRepo.watchHistory(limit: 50),
        builder: (context, snapshot) {
          final history = snapshot.data ?? const <NotificationLog>[];

          if (items.isEmpty && history.isEmpty) {
            return ListView(
              padding: kListPadding,
              children: const [
                EmptyState(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Tout est à jour à l\'atelier',
                  hint: 'Aucune alerte en attente ni rappel manqué.',
                ),
              ],
            );
          }

          // Trier l'historique pour placer les alarmes manquées non vues en tête
          final sortedHistory = List<NotificationLog>.from(history)
            ..sort((a, b) {
              final aMissedUnseen = a.outcome == 'missed' && a.seenAt == null;
              final bMissedUnseen = b.outcome == 'missed' && b.seenAt == null;
              if (aMissedUnseen && !bMissedUnseen) return -1;
              if (!aMissedUnseen && bMissedUnseen) return 1;
              return b.scheduledAt.compareTo(a.scheduledAt);
            });

          return ListView(
            padding: kListPadding,
            children: [
              // ═══ SECTION 1 : « À FAIRE » ═══
              Row(
                children: [
                  const Text(
                    'À faire',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Pal.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: items.isEmpty ? Pal.chalk : Pal.cobalt.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: items.isEmpty ? Pal.slate : Pal.cobalt,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (items.isEmpty)
                Panel(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, color: Pal.sage, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Aucune alerte en attente. Tout est à jour à l\'atelier.',
                          style: TextStyle(color: Pal.slate.withValues(alpha: 0.9), fontSize: 13.5),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < items.length; i++) ...[
                  Builder(builder: (context) {
                    final item = items[i];
                    final isRead = notifService?.isRead(item.key) ?? false;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Opacity(
                        opacity: isRead ? 0.65 : 1.0,
                        child: Panel(
                          onTap: () {
                            notifService?.markAsRead(item.key);
                            item.open(context);
                          },
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: item.bg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(item.icon, color: item.fg, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                              fontSize: 15,
                                              color: isRead ? Pal.slate : Pal.ink,
                                            ),
                                          ),
                                        ),
                                        if (item.isLate)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFDE8E8),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'En retard',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: Pal.thread,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item.sub,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Pal.slate,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.onWhatsApp != null) ...[
                                const SizedBox(width: 6),
                                IconButton(
                                  icon: const Icon(Icons.send_rounded, size: 18, color: Pal.cobalt),
                                  tooltip: 'Envoyer WhatsApp',
                                  onPressed: () => item.onWhatsApp!(context),
                                ),
                              ],
                              if (!isRead) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Pal.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],

              const SizedBox(height: 24),

              // ═══ SECTION 2 : « HISTORIQUE (30 JOURS) » ═══
              Row(
                children: [
                  const Text(
                    'Historique',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Pal.ink,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '(30 jours)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Pal.slate,
                    ),
                  ),
                  const Spacer(),
                  if (history.isNotEmpty)
                    Text(
                      '${history.length} entrées',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Pal.slate,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (sortedHistory.isEmpty)
                Panel(
                  padding: const EdgeInsets.all(16),
                  child: const Center(
                    child: Text(
                      'Aucun rappel passé enregistré pour le moment.',
                      style: TextStyle(color: Pal.slate, fontSize: 13),
                    ),
                  ),
                )
              else
                for (final log in sortedHistory) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryLogTile(
                      log: log,
                      onTap: () async {
                        if (log.seenAt == null) {
                          await logRepo.markSeen(log.id);
                        }
                      },
                    ),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _HistoryLogTile extends StatelessWidget {
  const _HistoryLogTile({
    required this.log,
    required this.onTap,
  });

  final NotificationLog log;
  final VoidCallback onTap;

  String _formatOutcome(String outcome) {
    switch (outcome) {
      case 'stopped':
        return 'Arrêtée';
      case 'snoozed':
        return 'Reportée';
      case 'missed':
        return 'Alarme manquée';
      case 'opened':
        return 'Ouverte';
      case 'dismissed':
        return 'Ignorée';
      case 'displayed':
        return 'Affichée';
      default:
        return outcome;
    }
  }

  Color _outcomeBg(String outcome, bool isMissed) {
    if (isMissed) return const Color(0xFFFDE8E8);
    switch (outcome) {
      case 'stopped':
        return const Color(0xFFDEF7EC);
      case 'snoozed':
        return const Color(0xFFFEF08A);
      case 'opened':
        return const Color(0xFFE1EFFE);
      case 'displayed':
        return const Color(0xFFE8EDFB);
      default:
        return Pal.chalk;
    }
  }

  Color _outcomeFg(String outcome, bool isMissed) {
    if (isMissed) return const Color(0xFF991B1B);
    switch (outcome) {
      case 'stopped':
        return const Color(0xFF03543F);
      case 'snoozed':
        return const Color(0xFF713F12);
      case 'opened':
        return const Color(0xFF1E429F);
      case 'displayed':
        return Pal.cobalt;
      default:
        return Pal.slate;
    }
  }

  IconData _channelIcon(String channel) {
    switch (channel) {
      case 'alarm':
        return Icons.alarm_rounded;
      case 'in_app_banner':
        return Icons.dashboard_customize_outlined;
      case 'notification':
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$d/$mo $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isMissed = log.outcome == 'missed';
    final isUnseen = log.seenAt == null;

    final tileBg = isMissed
        ? const Color(0xFFFEF2F2)
        : (isUnseen ? Colors.white : Pal.chalk);

    final border = isMissed
        ? Border.all(color: const Color(0xFFF87171), width: 1.5)
        : Border.all(color: Pal.line);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(14),
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _channelIcon(log.channel),
                    size: 16,
                    color: isMissed ? const Color(0xFF991B1B) : Pal.slate,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDateTime(log.scheduledAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMissed ? const Color(0xFF991B1B) : Pal.slate,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _outcomeBg(log.outcome, isMissed),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMissed) ...[
                          const Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFF991B1B)),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatOutcome(log.outcome),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _outcomeFg(log.outcome, isMissed),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                log.title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: isMissed ? const Color(0xFF7F1D1D) : Pal.ink,
                ),
              ),
              if (log.body.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  log.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: isMissed ? const Color(0xFF991B1B).withValues(alpha: 0.85) : Pal.slate,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
