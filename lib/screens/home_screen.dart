import '../data/services/alert_engine.dart';
import '../ui.dart';
import '../widgets/order_tile.dart';
import 'apprentice_detail_screen.dart';
import 'order_detail_screen.dart';

const _numberWords = ['Aucune priorité', 'Une priorité', 'Deux priorités', 'Trois priorités', 'Quatre priorités', 'Cinq priorités'];

IconData _alertIcon(AppAlert a) {
  switch (a.family) {
    case AlertFamily.fitting:
      return Icons.schedule_rounded;
    case AlertFamily.pendingBalance:
      return Icons.account_balance_wallet_outlined;
    case AlertFamily.delivery:
      return a.severity == AlertSeverity.late ? Icons.warning_amber_rounded : Icons.local_shipping_outlined;
    case AlertFamily.apprenticeDue:
      return a.severity == AlertSeverity.late ? Icons.warning_amber_rounded : Icons.school_outlined;
  }
}

Color _alertFg(AppAlert a) {
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

Color _alertBg(AppAlert a) {
  switch (a.family) {
    case AlertFamily.fitting:
      return const Color(0xFFFFF0E2);
    case AlertFamily.pendingBalance:
      return const Color(0xFFE8EDFB);
    case AlertFamily.delivery:
      return a.severity == AlertSeverity.late ? const Color(0xFFFBE1E3) : const Color(0xFFDDF3EA);
    case AlertFamily.apprenticeDue:
      return a.severity == AlertSeverity.late ? const Color(0xFFFBE1E3) : const Color(0xFFE8EDFB);
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final active = s.activeOrders;
    final week = active.where((o) {
      final d = daysUntil(o.deliveryDate);
      return d >= 0 && d <= 7;
    }).toList();
    final rate = s.punctualityRate;

    const engine = AlertEngine();
    final allAlerts = engine.currentAlerts(
      now: DateTime.now(),
      orders: active,
      apprentices: s.apprentices,
      clientById: s.clientById,
      remainingOfOrder: s.remainingOf,
      remainingOfApprentice: s.apprenticeRemaining,
    );

    // Priorités affichées sur l'accueil : aujourd'hui, retards et soldes en attente
    final prios = allAlerts
        .where((a) =>
            a.severity == AlertSeverity.today ||
            a.severity == AlertSeverity.late ||
            a.family == AlertFamily.pendingBalance)
        .toList();
    final upcoming = active.where((o) => daysUntil(o.deliveryDate) >= 0).take(4).toList();

    return SectionPage(
      title: "Vue d'ensemble",
      eyebrow: fmtDayLong(today()),
      onMenu: onMenu,
      isHome: true,
      child: ListView(padding: kListPadding, children: [
        StaggeredFadeIn(
          index: 0,
          child: PageTitle(
            eyebrow: fmtDayLong(today()),
            title: "Vue d'ensemble",
          ),
        ),
        StaggeredFadeIn(
          index: 1,
          isCard: true,
          child: CobaltCard(
            padding: const EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("ACTIVITÉ DE L'ATELIER", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                ),
                GestureDetector(
                  onTap: () => ShellScope.maybeOf(context)?.goOrders(),
                  child: Container(
                    width: 44, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(36), borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: Colors.white.withAlpha(60)),
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                _Big('${active.length}', 'commandes actives'),
                Container(width: 1, height: 50, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 14)),
                _Big('${week.length}', 'à livrer cette semaine'),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: rate ?? 0,
                      minHeight: 6, backgroundColor: Colors.white24, color: Pal.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rate == null ? '—' : '${(rate * 100).round()} % dans les délais',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        StaggeredFadeIn(
          index: 1,
          isCard: true,
          child: Panel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Eyebrow("Aujourd'hui"),
                    const SizedBox(height: 6),
                    Text(prios.length < _numberWords.length ? _numberWords[prios.length] : '${prios.length} priorités',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -.5)),
                  ]),
                ),
                Container(
                  width: 38, height: 34, alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFE8EDFB), borderRadius: BorderRadius.circular(12)),
                  child: Text('${prios.length}', style: const TextStyle(color: Pal.cobalt, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ]),
              const SizedBox(height: 12),
              if (prios.isEmpty)
                const Padding(padding: EdgeInsets.only(bottom: 14), child: Text("Rien d'urgent pour le moment.", style: TextStyle(color: Pal.slate, fontSize: 13))),
              for (var i = 0; i < prios.length; i++) ...[
                Container(height: 1, color: Pal.line),
                StaggeredFadeIn(
                  index: i,
                  child: InkWell(
                    onTap: () {
                      if (prios[i].targetType == 'apprentice') {
                        push(context, ApprenticeDetailScreen(apprenticeId: prios[i].targetId));
                      } else {
                        push(context, OrderDetailScreen(orderId: prios[i].targetId));
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: _alertBg(prios[i]), borderRadius: BorderRadius.circular(14), border: Border.all(color: _alertFg(prios[i]).withAlpha(40))),
                          child: Icon(_alertIcon(prios[i]), color: _alertFg(prios[i]), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(prios[i].title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: -.2)),
                            const SizedBox(height: 2),
                            Text(prios[i].body, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Pal.slate, fontSize: 12.5)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Pal.slate, size: 20),
                      ]),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 10),
        StaggeredFadeIn(
          index: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Eyebrow('Planning'),
                  SizedBox(height: 5),
                  Text('Prochaines livraisons', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -.4)),
                ]),
              ),
              TextButton(
                onPressed: () => ShellScope.maybeOf(context)?.goOrders(),
                child: const Text('Tout voir', style: TextStyle(color: Pal.cobalt, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ),
        ),
        if (upcoming.isEmpty) const EmptyState(icon: Icons.assignment_outlined, title: 'Aucune livraison prévue'),
        for (var i = 0; i < upcoming.length; i++)
          StaggeredFadeIn(
            index: 3 + i,
            isCard: true,
            child: OrderTile(upcoming[i]),
          ),
      ]),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1.0, height: 1.05)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ]),
      );
}
