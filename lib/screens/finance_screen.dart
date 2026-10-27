import 'package:intl/intl.dart';
import '../ui.dart';

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final now = DateTime.now();
    bool thisMonth(DateTime d) => d.year == now.year && d.month == now.month;
    final int monthTotal = s.clientPayments.where((p) => thisMonth(p.paidAt)).fold<int>(0, (t, p) => t + p.amount) +
        s.apprenticePayments.where((p) => thisMonth(p.paidAt)).fold<int>(0, (t, p) => t + p.amount);

    // Maquette : l'historique des mois précédents est fictif.
    final values = <int>[182000, 241000, 198000, 276000, 231000, monthTotal];
    final maxV = values.reduce((a, b) => a > b ? a : b).toDouble();
    final months = [for (var i = 5; i >= 0; i--) DateFormat('MMM', 'fr_FR').format(DateTime(now.year, now.month - i))];

    final moves = <({String who, String sub, int amount, DateTime date, bool apprentice})>[
      for (final p in s.clientPayments)
        (
          who: s.clientById(s.orderById(p.orderId)?.clientId)?.name ?? 'Client',
          sub: s.orderById(p.orderId)?.title ?? 'Commande',
          amount: p.amount, date: p.paidAt, apprentice: false,
        ),
      for (final p in s.apprenticePayments)
        (who: s.apprenticeById(p.apprenticeId)?.name ?? 'Apprenti', sub: 'Formation', amount: p.amount, date: p.paidAt, apprentice: true),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return SectionPage(
      title: 'Finance',
      eyebrow: 'Trésorerie',
      onMenu: onMenu,
      child: ListView(padding: kListPadding, children: [
        StaggeredFadeIn(
          index: 0,
          isCard: true,
          child: CobaltCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ENCAISSÉ EN ${DateFormat('MMMM', 'fr_FR').format(now).toUpperCase()}',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                child: Text(fcfa(monthTotal), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1.0)),
              ),
              const SizedBox(height: 14),
              Row(children: [
                _Sub('Reste à encaisser', fcfa(s.totalClientRemaining)),
                Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 14)),
                _Sub('Apprentis à recevoir', fcfa(s.totalApprenticeRemaining)),
              ]),
            ]),
          ),
        ),
        const StaggeredFadeIn(index: 1, child: Heading('Six derniers mois')),
        StaggeredFadeIn(
          index: 2,
          isCard: true,
          child: Panel(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
            child: SizedBox(
              height: 170,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(values[i] >= 1000 ? '${(values[i] / 1000).round()} k' : '${values[i]}',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: i == values.length - 1 ? Pal.cobalt : Pal.slate)),
                      const SizedBox(height: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: MotionCurves.card,
                        height: maxV == 0 ? 4 : (values[i] / maxV * 100).clamp(4, 100).toDouble(),
                        margin: const EdgeInsets.symmetric(horizontal: 7),
                        decoration: BoxDecoration(
                          gradient: i == values.length - 1 ? Pal.cobaltGradient : null,
                          color: i == values.length - 1 ? null : const Color(0xFFE8EDFB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(months[i], style: const TextStyle(fontSize: 12, color: Pal.slate, fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ]),
            ),
          ),
        ),
        const StaggeredFadeIn(index: 3, child: Heading('Derniers paiements')),
        for (var i = 0; i < moves.take(8).length; i++)
          StaggeredFadeIn(
            index: 4 + i,
            isCard: true,
            child: Panel(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: moves[i].apprentice ? const Color(0xFFE8EDFB) : const Color(0xFFDDF3EA), borderRadius: BorderRadius.circular(16)),
                  child: Icon(moves[i].apprentice ? Icons.school_outlined : Icons.south_west_rounded, color: moves[i].apprentice ? Pal.cobalt : Pal.sage),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(moves[i].who, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                    Text('${moves[i].sub} · ${fmtDate(moves[i].date)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Pal.slate, fontSize: 12.5)),
                  ]),
                ),
                Text('+ ${fcfa(moves[i].amount)}', style: const TextStyle(color: Pal.sage, fontWeight: FontWeight.w800, fontSize: 13.5)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _Sub extends StatelessWidget {
  const _Sub(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700))),
        ]),
      );
}
