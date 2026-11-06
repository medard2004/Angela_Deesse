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
    required this.open,
    this.onWhatsApp,
  });

  final String key;
  final IconData icon;
  final Color fg, bg;
  final String title, sub;
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
        open: open,
        onWhatsApp: onWa,
      ));
    }

    return SectionPage(
      title: 'Notifications',
      eyebrow: 'Rappels',
      onMenu: widget.onMenu,
      actions: [
        titleAction(
          Icons.done_all_rounded,
          () => notifService?.markAllAsRead(items.map((i) => i.key)),
          'Tout marquer comme vu',
        ),
      ],
      child: items.isEmpty
          ? ListView(children: const [EmptyState(icon: Icons.notifications_none_rounded, title: 'Aucune notification', hint: 'Les rappels de livraison, essayage et paiement apparaissent ici.')])
          : TwoPhaseLoader(
              skeleton: const SkeletonList(count: 4),
              child: ListView(padding: kListPadding, children: [
                for (var i = 0; i < items.length; i++) ...[
                  Builder(builder: (context) {
                    final isRead = notifService?.isRead(items[i].key) ?? false;
                    return StaggeredFadeIn(
                      index: i,
                      isCard: true,
                      child: Opacity(
                        opacity: isRead ? 0.65 : 1.0,
                        child: Panel(
                          onTap: () {
                            notifService?.markAsRead(items[i].key);
                            items[i].open(context);
                          },
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(color: items[i].bg, borderRadius: BorderRadius.circular(17)),
                              child: Icon(items[i].icon, color: items[i].fg),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(
                                  items[i].title,
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 15.5,
                                    color: isRead ? Pal.slate : Pal.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(items[i].sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Pal.slate, fontSize: 13)),
                              ]),
                            ),
                            if (items[i].onWhatsApp != null)
                              IconButton(
                                icon: const Icon(Icons.send_rounded, size: 20, color: Pal.cobalt),
                                tooltip: 'Envoyer WhatsApp',
                                onPressed: () => items[i].onWhatsApp!(context),
                              ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Pal.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ]),
                        ),
                      ),
                    );
                  }),
                ],
              ]),
            ),
    );
  }
}
