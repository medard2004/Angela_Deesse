import 'dart:math' as math;
import '../ui.dart';
import '../screens/home_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/clients_screen.dart';
import '../screens/finance_screen.dart';
import '../screens/apprentices_screen.dart';
import '../screens/modeles_screen.dart';
import '../screens/gallery_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/order_form_screen.dart';
import '../screens/client_form_screen.dart';
import '../screens/apprentice_screen.dart';
import '../screens/modele_screen.dart';
import '../screens/workshop_selector_screen.dart';

enum Section {
  home('Accueil', Icons.home_outlined, Icons.home_rounded),
  orders('Commandes', Icons.assignment_outlined, Icons.assignment_rounded),
  clients('Clients', Icons.people_outline_rounded, Icons.people_rounded),
  finance('Finance', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  apprentices('Apprentis', Icons.school_outlined, Icons.school_rounded),
  modeles('Modèles', Icons.checkroom_outlined, Icons.checkroom_rounded),
  gallery('Galerie', Icons.image_outlined, Icons.image_rounded),
  notifications('Notifications', Icons.notifications_none_rounded, Icons.notifications_rounded),
  settings('Paramètres', Icons.tune_outlined, Icons.tune_rounded);

  const Section(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon, activeIcon;
}

/// Sections de la barre de navigation inférieure.
const _pillSections = [Section.home, Section.orders, Section.clients, Section.apprentices];

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _key = GlobalKey<ScaffoldState>();
  Section _current = Section.home;

  void _go(Section s) => setState(() => _current = s);
  void _menu() => _key.currentState?.openDrawer();

  Widget _page() => switch (_current) {
        Section.home => HomeScreen(onMenu: _menu),
        Section.orders => OrdersScreen(onMenu: _menu),
        Section.clients => ClientsScreen(onMenu: _menu),
        Section.finance => FinanceScreen(onMenu: _menu),
        Section.apprentices => ApprenticesScreen(onMenu: _menu),
        Section.modeles => ModelesScreen(onMenu: _menu),
        Section.gallery => GalleryScreen(onMenu: _menu),
        Section.notifications => NotificationsScreen(onMenu: _menu),
        Section.settings => SettingsScreen(onMenu: _menu),
      };

  void _quickAdd() {
    showMotionBottomSheet(
      context: context,
      isScrollControlled: false,
      builder: (c) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        Widget item(int index, IconData i, String t, Widget Function() page) => StaggeredFadeIn(
              index: index,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Pal.cremeCoton.withAlpha(isDark ? 30 : 150),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(i, color: Pal.terreBogolan, size: 20),
                ),
                title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                onTap: () {
                  Navigator.pop(c);
                  push(context, page());
                },
              ),
            );
        return SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 16),
            const Text(
              'Ajouter à l\'atelier',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Fraunces'),
            ),
            const SizedBox(height: 6),
            item(0, Icons.assignment_outlined, 'Nouvelle commande', () => const OrderFormScreen()),
            item(1, Icons.person_add_alt_outlined, 'Nouveau client & mesures', () => const ClientFormScreen()),
            item(2, Icons.school_outlined, 'Nouvel apprenti', () => const ApprenticeFormScreen()),
            item(3, Icons.checkroom_outlined, 'Nouveau modèle', () => const ModeleFormScreen()),
            const SizedBox(height: 12),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return ShellScope(
      openNotifications: () => _go(Section.notifications),
      goOrders: () => _go(Section.orders),
      child: PopScope(
        canPop: _current == Section.home,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _go(Section.home);
        },
        child: Scaffold(
          key: _key,
          drawerScrimColor: Pal.brunNuit.withAlpha(120),
          drawer: _AppDrawer(
            current: _current,
            onSelect: (s) {
              Navigator.pop(context);
              _go(s);
            },
          ),
          body: Stack(children: [
            const Positioned.fill(child: _Backdrop()),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: MotionDurations.pageIn,
                reverseDuration: MotionDurations.pageOut,
                switchInCurve: MotionCurves.page,
                switchOutCurve: MotionCurves.page,
                transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(key: ValueKey(_current), child: _page()),
              ),
            ),
            if (!keyboard)
              Positioned(
                left: 0,
                right: 0,
                bottom: 14 + MediaQuery.paddingOf(context).bottom,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PillNav(current: _current, onSelect: _go),
                      const SizedBox(width: 10),
                      _AddButton(onTap: _quickAdd),
                    ],
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Fond épuré aux tons terre et crème, sans bleu ni orange vif.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Pal.sombreFond : Pal.fondClair;
    return ColoredBox(color: bg);
  }
}

// ---------------------------------------------------------------------------
// Barre flottante épurée (coins 12 px, aucun effet de verre)
// ---------------------------------------------------------------------------
class _PillNav extends StatelessWidget {
  const _PillNav({required this.current, required this.onSelect});
  final Section current;
  final ValueChanged<Section> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Pal.sombreSurface : Pal.blanc;
    final border = isDark ? Pal.sombreBordure : Pal.bordure;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: softShadow(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final s in _pillSections)
            _PillItem(
              section: s,
              selected: s == current,
              onTap: () => onSelect(s),
            ),
        ],
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({required this.section, required this.selected, required this.onTap});
  final Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = Pal.terreBogolan;
    final selectedFg = Pal.cremeCoton;
    final unselectedFg = isDark ? Pal.sombreTexteSecondaire : Pal.slate;

    return Semantics(
      button: true,
      selected: selected,
      label: section.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 9),
          decoration: BoxDecoration(
            color: selected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? section.activeIcon : section.icon,
                size: 19,
                color: selected ? selectedFg : unselectedFg,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          section.label,
                          style: TextStyle(
                            color: selectedFg,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Ajouter',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Pal.ocre,
              borderRadius: BorderRadius.circular(12),
              boxShadow: softShadow(14),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Menu latéral (Drawer SaaS Multi-Ateliers)
// ---------------------------------------------------------------------------
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.current, required this.onSelect});
  final Section current;
  final ValueChanged<Section> onSelect;

  Widget _group(String? label, List<Section> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 16, 4),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                  color: Pal.ocre,
                ),
              ),
            ),
          for (final s in items)
            _DrawerItem(section: s, selected: s == current, onTap: () => onSelect(s)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerBg = isDark ? Pal.sombreSurface : Pal.blanc;
    final border = isDark ? Pal.sombreBordure : Pal.bordure;
    final textPrimary = isDark ? Pal.sombreTexte : Pal.terreBogolan;

    return Drawer(
      width: math.min(310, screenWidth * .84),
      backgroundColor: drawerBg,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 20),
          children: [
            // Logo officiel et fermeture
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Image.asset(
                    isDark
                        ? 'assets/brand/png/logo_horizontal_on_dark_2400.png'
                        : 'assets/brand/png/logo_horizontal_2400.png',
                    height: 34,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      'assets/brand/png/emblem_512.png',
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Pal.cremeCoton.withAlpha(isDark ? 30 : 120),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            // Carte Espace Atelier SaaS actif
            Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Pal.terreBogolan,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Pal.ocre.withAlpha(120), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Pal.ocre,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SAAS ATELIER PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          WorkshopSelectorSheet.show(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Pal.cremeCoton.withAlpha(40),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Pal.cremeCoton.withAlpha(80)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.swap_horiz_rounded, size: 14, color: Pal.cremeCoton),
                              SizedBox(width: 4),
                              Text(
                                'Changer',
                                style: TextStyle(
                                  color: Pal.cremeCoton,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    store.atelierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      color: Pal.cremeCoton,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '${store.currentAtelier.city} (${store.currentAtelier.country})',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            _group(null, [Section.home, Section.orders, Section.clients]),
            _group('Gestion & Ateliers', [Section.finance, Section.apprentices, Section.modeles]),
            _group('Système', [Section.gallery, Section.notifications, Section.settings]),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({required this.section, required this.selected, required this.onTap});
  final Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark ? Pal.sombreSurfaceElevated : Pal.cremeCoton.withAlpha(140);
    final selectedFg = isDark ? Pal.sombreTexte : Pal.terreBogolan;
    final unselectedFg = isDark ? Pal.sombreTexteSecondaire : Pal.slate;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected ? Border.all(color: Pal.ocre.withAlpha(90), width: 1.0) : null,
        ),
        child: Row(children: [
          Icon(
            selected ? section.activeIcon : section.icon,
            size: 19,
            color: selected ? Pal.ocre : unselectedFg,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              section.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? selectedFg : unselectedFg,
              ),
            ),
          ),
          if (selected)
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Pal.ocre, shape: BoxShape.circle),
            ),
        ]),
      ),
    );
  }
}
