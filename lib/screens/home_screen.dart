import '../ui.dart';
import '../widgets/order_tile.dart';
import 'order_detail_screen.dart';
import 'order_form_screen.dart';
import 'client_form_screen.dart';
import 'apprentice_screen.dart';

class _PriorityItem {
  _PriorityItem({
    required this.icon,
    required this.fg,
    required this.bg,
    required this.title,
    required this.sub,
    required this.orderId,
  });
  final IconData icon;
  final Color fg, bg;
  final String title, sub, orderId;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = context.watch<AppStore>();
    final active = s.activeOrders;

    // Métriques clés simples et digestes
    final inProgress = active.where((o) => o.status == OrderStatus.cours).length;
    final inFitting = active.where((o) => o.status == OrderStatus.essayage).length;
    final ready = active.where((o) => o.status == OrderStatus.prete).length;

    // Priorités réelles du jour (seulement l'essentiel)
    final prios = <_PriorityItem>[];
    for (final o in active) {
      final client = s.clientById(o.clientId);
      final clientName = client?.name ?? 'Client';
      final f = o.fittingDate;
      if (f != null && daysUntil(f) == 0) {
        prios.add(_PriorityItem(
          icon: Icons.straighten_rounded,
          fg: Pal.statutEssayageFg,
          bg: Pal.statutEssayageBg,
          title: 'Essayage avec $clientName',
          sub: o.title,
          orderId: o.id,
        ));
      } else if (daysUntil(o.deliveryDate) == 0) {
        prios.add(_PriorityItem(
          icon: Icons.checkroom_rounded,
          fg: Pal.statutPreteFg,
          bg: Pal.statutPreteBg,
          title: 'Livraison prévue aujourd\'hui',
          sub: '$clientName · ${o.title}',
          orderId: o.id,
        ));
      }
    }

    final upcoming = active.take(3).toList();

    return SectionPage(
      title: 'Miva Couture',
      eyebrow: 'Atelier',
      onMenu: onMenu,
      isHome: true,
      child: ListView(
        padding: kListPadding,
        children: [
          // 1. En-tête sobre de l'Atelier
          StaggeredFadeIn(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fmtDayLong(today()).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: Pal.ocre,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.atelierName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.tagBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Pal.ocre.withAlpha(90)),
                        ),
                        child: Text(
                          s.currentAtelier.currency,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const AfricanPatternDivider(height: 10, opacity: 0.4),
                ],
              ),
            ),
          ),

          // 2. Trois Tuiles d'Activité simples, jolies et claires
          StaggeredFadeIn(
            index: 1,
            isCard: true,
            child: Row(
              children: [
                _StatTile(
                  title: 'En cours',
                  count: '$inProgress',
                  icon: Icons.cut_outlined,
                  color: Pal.ocre,
                  onTap: () => ShellScope.maybeOf(context)?.goOrders(),
                ),
                const SizedBox(width: 8),
                _StatTile(
                  title: 'Essayages',
                  count: '$inFitting',
                  icon: Icons.straighten_rounded,
                  color: Pal.statutEssayageFg,
                  onTap: () => ShellScope.maybeOf(context)?.goOrders(),
                ),
                const SizedBox(width: 8),
                _StatTile(
                  title: 'Prêtes',
                  count: '$ready',
                  icon: Icons.checkroom_rounded,
                  color: Pal.statutPreteFg,
                  onTap: () => ShellScope.maybeOf(context)?.goOrders(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Actions Rapides d'Artisan
          StaggeredFadeIn(
            index: 2,
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Commande',
                    onTap: () => push(context, const OrderFormScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.straighten_outlined,
                    label: 'Mesures',
                    onTap: () => push(context, const ClientFormScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.school_outlined,
                    label: 'Apprenti',
                    onTap: () => push(context, const ApprenticeFormScreen()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. Priorités du jour (si existantes)
          if (prios.isNotEmpty) ...[
            StaggeredFadeIn(
              index: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'URGENCES DU JOUR (${prios.length})',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                    color: Pal.ocre,
                  ),
                ),
              ),
            ),
            for (var i = 0; i < prios.length; i++)
              StaggeredFadeIn(
                index: 4 + i,
                isCard: true,
                child: Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: () => push(context, OrderDetailScreen(orderId: prios[i].orderId)),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: prios[i].bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: prios[i].fg.withAlpha(50)),
                        ),
                        child: Icon(prios[i].icon, color: prios[i].fg, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prios[i].title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              prios[i].sub,
                              style: TextStyle(color: colors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 18),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
          ],

          // 5. Commandes récentes simples
          StaggeredFadeIn(
            index: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'EN COURS À L\'ATELIER',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ShellScope.maybeOf(context)?.goOrders(),
                  style: TextButton.styleFrom(
                    foregroundColor: Pal.ocre,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  child: const Text('Tout voir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          if (upcoming.isEmpty)
            const EmptyState(icon: Icons.checkroom_outlined, title: 'Aucune commande en cours')
          else
            for (var i = 0; i < upcoming.length; i++)
              StaggeredFadeIn(
                index: 7 + i,
                isCard: true,
                child: OrderTile(upcoming[i]),
              ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: kBorderRadius,
            border: Border.all(color: colors.border),
            boxShadow: softShadow(colors.isDark ? 4 : 8),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                count,
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: kBorderRadius,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Pal.ocre),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
