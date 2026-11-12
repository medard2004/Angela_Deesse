import '../ui.dart';
import '../widgets/order_tile.dart';
import 'order_form_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'all';

  static const _filters = <(String, String)>[
    ('all', 'Toutes'), ('attente', 'En attente'), ('cours', 'En cours'),
    ('essayage', 'Essayage'), ('prete', 'Prêtes'), ('retard', 'En retard'), ('livree', 'Livrées'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    var list = s.orders.where((o) {
      switch (_filter) {
        case 'all': return true;
        case 'retard': return o.isActive && daysUntil(o.deliveryDate) < 0;
        default: return o.status.name == _filter;
      }
    }).toList();
    // Livraisons les plus proches d'abord ; les commandes livrées en dernier.
    list.sort((a, b) {
      if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
      return a.isActive ? a.deliveryDate.compareTo(b.deliveryDate) : b.deliveryDate.compareTo(a.deliveryDate);
    });

    Widget filtersRow = SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        children: [
          for (var i = 0; i < _filters.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: StaggeredFadeIn(
                index: i,
                isCard: false,
                child: PillChip(
                  label: _filters[i].$2,
                  selected: _filter == _filters[i].$1,
                  onTap: () => setState(() => _filter = _filters[i].$1),
                ),
              ),
            ),
        ],
      ),
    );

    return SectionPage(
      title: 'Commandes',
      eyebrow: 'Suivi',
      onMenu: widget.onMenu,
      actions: [titleAction(Icons.add_rounded, () => push(context, const OrderFormScreen()), 'Nouvelle commande')],
      child: TwoPhaseLoader(
        skeleton: ListView(
          padding: kListPadding,
          children: [
            filtersRow,
            const SizedBox(height: 8),
            const SkeletonList(count: 5, padding: EdgeInsets.zero),
          ],
        ),
        child: ListView(
          padding: kListPadding,
          children: [
            filtersRow,
            const SizedBox(height: 8),
            if (list.isEmpty)
              const EmptyState(icon: Icons.checkroom_outlined, title: 'Aucune commande', hint: 'Les commandes apparaissent ici.')
            else
              for (var i = 0; i < list.length; i++)
                StaggeredFadeIn(
                  index: i,
                  isCard: true,
                  child: OrderTile(list[i]),
                ),
          ],
        ),
      ),
    );
  }
}
