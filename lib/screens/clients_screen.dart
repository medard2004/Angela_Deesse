import '../ui.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final q = _q.trim().toLowerCase();
    final list = s.clients.where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();

    return SectionPage(
      title: 'Clients',
      eyebrow: 'Carnet',
      onMenu: widget.onMenu,
      actions: [titleAction(Icons.person_add_alt_1_outlined, () => push(context, const ClientFormScreen()), 'Nouveau client')],
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: deco('Rechercher un client').copyWith(prefixIcon: const Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: TwoPhaseLoader(
            skeleton: const SkeletonList(count: 6),
            child: list.isEmpty
                ? ListView(children: [
                    EmptyState(
                      icon: Icons.people_outline,
                      title: s.clients.isEmpty ? 'Aucun client' : 'Aucun résultat',
                      hint: s.clients.isEmpty ? 'Créez une fiche avec le bouton en haut à droite.' : null,
                    ),
                  ])
                : ListView(padding: kListPadding, children: [
                    for (var i = 0; i < list.length; i++)
                      StaggeredFadeIn(
                        index: i,
                        isCard: true,
                        child: Panel(
                          onTap: () => push(context, ClientDetailScreen(clientId: list[i].id)),
                          child: Row(children: [
                            CircleAvatar(
                              backgroundColor: Pal.chalk,
                              child: Text(list[i].name.isEmpty ? '?' : list[i].name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(list[i].name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                if (list[i].phone.isNotEmpty) Text(list[i].phone, style: const TextStyle(color: Pal.slate)),
                              ]),
                            ),
                            if (s.clientRemaining(list[i].id) > 0)
                              Text(fcfa(s.clientRemaining(list[i].id)), style: const TextStyle(color: Pal.thread, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                  ]),
          ),
        ),
      ]),
    );
  }
}
