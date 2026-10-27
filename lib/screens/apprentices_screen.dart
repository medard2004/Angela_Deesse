import '../ui.dart';
import 'apprentice_detail_screen.dart';
import 'apprentice_screen.dart';

class ApprenticesScreen extends StatelessWidget {
  const ApprenticesScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    return SectionPage(
      title: 'Apprentis',
      eyebrow: 'Formation',
      onMenu: onMenu,
      actions: [titleAction(Icons.add_rounded, () => push(context, const ApprenticeFormScreen()), 'Nouvel apprenti')],
      child: s.apprentices.isEmpty
          ? ListView(children: const [EmptyState(icon: Icons.school_outlined, title: 'Aucun apprenti', hint: 'Ajoutez un apprenti pour suivre ses paiements de formation.')])
          : TwoPhaseLoader(
              skeleton: const SkeletonList(count: 4),
              child: ListView(padding: kListPadding, children: [
                for (var i = 0; i < s.apprentices.length; i++)
                  Builder(builder: (context) {
                    final app = s.apprentices[i];
                    final paid = s.apprenticePaid(app);
                    final rem = s.apprenticeRemaining(app);
                    return StaggeredFadeIn(
                      index: i,
                      isCard: true,
                      child: Panel(
                        onTap: () => push(context, ApprenticeDetailScreen(apprenticeId: app.id)),
                        child: Row(children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFEFF3FD),
                            foregroundColor: Pal.cobalt,
                            child: Text(app.name.isEmpty ? '?' : app.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(app.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('Versé : ${fcfa(paid)} / ${fcfa(app.totalFee)}', style: const TextStyle(color: Pal.slate, fontSize: 12)),
                              if (app.nextDue != null && rem > 0)
                                Text('Échéance : ${countdown(app.nextDue!)}',
                                    style: TextStyle(color: daysUntil(app.nextDue!) < 0 ? Pal.thread : Pal.slate, fontSize: 11.5)),
                            ]),
                          ),
                          rem == 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Soldé', style: TextStyle(color: Pal.sage, fontWeight: FontWeight.w800, fontSize: 12)),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Reste', style: TextStyle(color: Pal.slate, fontSize: 10)),
                                    Text(fcfa(rem), style: const TextStyle(color: Pal.thread, fontSize: 13, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                        ]),
                      ),
                    );
                  }),
              ]),
            ),
    );
  }
}
