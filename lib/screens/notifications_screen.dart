import '../ui.dart';
import 'apprentice_detail_screen.dart';
import 'order_detail_screen.dart';

class _Notif {
  _Notif(this.icon, this.fg, this.bg, this.title, this.sub, this.open);
  final IconData icon;
  final Color fg, bg;
  final String title, sub;
  final void Function(BuildContext) open;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _read = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    const peach = Color(0xFFFFF0E2), orange = Color(0xFFC2570C), red = Color(0xFFFBE1E3);
    final items = <_Notif>[];

    for (final o in s.activeOrders) {
      final who = s.clientById(o.clientId)?.name ?? 'Client';
      void open(BuildContext c) => push(c, OrderDetailScreen(orderId: o.id));
      final f = o.fittingDate;
      final d = daysUntil(o.deliveryDate);
      if (f != null && daysUntil(f) >= 0 && daysUntil(f) <= 1) {
        items.add(_Notif(Icons.schedule_rounded, orange, peach, daysUntil(f) == 0 ? "Essayage aujourd'hui" : 'Essayage demain', '$who · ${o.title}', open));
      }
      if (d < 0) {
        items.add(_Notif(Icons.warning_amber_rounded, Pal.thread, red, 'Commande en retard', '$who · ${countdown(o.deliveryDate)}', open));
      } else if (d <= 2) {
        items.add(_Notif(Icons.local_shipping_outlined, Pal.sage, const Color(0xFFDDF3EA), 'Livraison ${countdown(o.deliveryDate).toLowerCase()}', '$who · ${o.title}', open));
      }
      if (o.status == OrderStatus.prete && s.remainingOf(o) > 0) {
        items.add(_Notif(Icons.account_balance_wallet_outlined, Pal.cobalt, const Color(0xFFE8EDFB), 'Solde en attente', '$who · ${fcfa(s.remainingOf(o))}', open));
      }
    }
    for (final a in s.apprentices) {
      final n = a.nextDue;
      if (n != null && s.apprenticeRemaining(a) > 0 && daysUntil(n) <= 7) {
        items.add(_Notif(Icons.school_outlined, Pal.cobalt, const Color(0xFFE8EDFB), 'Échéance apprenti ${countdown(n).toLowerCase()}',
            '${a.name} · reste ${fcfa(s.apprenticeRemaining(a))}', (c) => push(c, ApprenticeDetailScreen(apprenticeId: a.id))));
      }
    }

    return SectionPage(
      title: 'Notifications',
      eyebrow: 'Rappels',
      onMenu: widget.onMenu,
      actions: [titleAction(Icons.done_all_rounded, () => setState(() => _read = true), 'Tout marquer comme lu')],
      child: items.isEmpty
          ? ListView(children: const [EmptyState(icon: Icons.notifications_none_rounded, title: 'Aucune notification', hint: 'Les rappels de livraison, essayage et paiement apparaissent ici.')])
          : TwoPhaseLoader(
              skeleton: const SkeletonList(count: 4),
              child: ListView(padding: kListPadding, children: [
                for (var i = 0; i < items.length; i++)
                  StaggeredFadeIn(
                    index: i,
                    isCard: true,
                    child: Panel(
                      onTap: () => items[i].open(context),
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
                            Text(items[i].title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                            const SizedBox(height: 2),
                            Text(items[i].sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Pal.slate, fontSize: 13)),
                          ]),
                        ),
                        if (!_read) const PulsingIndicator(size: 9, color: Pal.orange),
                      ]),
                    ),
                  ),
              ]),
            ),
    );
  }
}
