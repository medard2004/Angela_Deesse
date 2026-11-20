import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import '../data/services/notification_center_service.dart';
import '../ui.dart';
import '../widgets/permission_onboarding_sheet.dart';
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

enum Section {
  home('Accueil', Icons.home_outlined, Icons.home_rounded),
  orders('Commandes', Icons.assignment_outlined, Icons.assignment_rounded),
  clients('Clients', Icons.people_outline_rounded, Icons.people_rounded),
  finance('Finance', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  apprentices('Apprentis', Icons.school_outlined, Icons.school_rounded),
  modeles('Modèles', Icons.checkroom_outlined, Icons.checkroom_rounded),
  gallery('Galerie', Icons.image_outlined, Icons.image_rounded),
  notifications('Notifications', Icons.notifications_none_rounded, Icons.notifications_rounded),
  settings('Paramètres', Icons.lock_outline_rounded, Icons.lock_rounded);

  const Section(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon, activeIcon;
}

/// Sections de la pilule flottante ; le reste est dans le menu latéral.
const _pillSections = [Section.home, Section.orders, Section.clients, Section.apprentices];

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _key = GlobalKey<ScaffoldState>();
  Section _current = Section.home;

  @override
  void initState() {
    super.initState();
    if (NotificationCenterService.pendingOpenNotifications) {
      NotificationCenterService.pendingOpenNotifications = false;
      _current = Section.notifications;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PermissionOnboardingSheet.showIfNeeded(context);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifService = context.watch<NotificationCenterService?>();
    if (notifService != null && NotificationCenterService.pendingOpenNotifications) {
      NotificationCenterService.pendingOpenNotifications = false;
      if (_current != Section.notifications) {
        _current = Section.notifications;
      }
    }
  }

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
        Widget item(int index, IconData i, String t, Widget Function() page) => StaggeredFadeIn(
              index: index,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFE8EDFB), borderRadius: BorderRadius.circular(13)),
                  child: Icon(i, color: Pal.cobalt, size: 20),
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
            const Text('Ajouter', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            item(0, Icons.assignment_outlined, 'Nouvelle commande', () => const OrderFormScreen()),
            item(1, Icons.person_add_alt_outlined, 'Nouveau client', () => const ClientFormScreen()),
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
          drawerScrimColor: Pal.ink.withAlpha(90),
          drawer: _AppDrawer(current: _current, onSelect: (s) {
            Navigator.pop(context);
            _go(s);
          }),
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
                left: 0, right: 0, bottom: 16 + MediaQuery.paddingOf(context).bottom,
                child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _PillNav(current: _current, onSelect: _go),
                  const SizedBox(width: 12),
                  _AddButton(onTap: _quickAdd),
                ])),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Fond clair avec halos bleu pâle et pêche, comme la maquette.
class _Backdrop extends StatelessWidget {
  const _Backdrop();
  static Widget _halo(double s, Color c) => IgnorePointer(
        child: Container(
          width: s, height: s,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [c, c.withAlpha(0)])),
        ),
      );
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: ColoredBox(color: Pal.chalk)),
        Positioned(top: -140, right: -140, child: _halo(420, const Color(0x55A9C2F5))),
        Positioned(top: 380, left: -170, child: _halo(380, const Color(0x30FF8A1F))),
      ]);
}

// ---------------------------------------------------------------------------
// Menu flottant en pilule
// ---------------------------------------------------------------------------
class _PillNav extends StatelessWidget {
  const _PillNav({required this.current, required this.onSelect});
  final Section current;
  final ValueChanged<Section> onSelect;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(32), boxShadow: softShadow(32)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(225),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final s in _pillSections) _PillItem(section: s, selected: s == current, onTap: () => onSelect(s)),
              ]),
            ),
          ),
        ),
      );
}

class _PillItem extends StatelessWidget {
  const _PillItem({required this.section, required this.selected, required this.onTap});
  final Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true, selected: selected, label: section.label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: selected ? 13 : 9),
            decoration: BoxDecoration(
              gradient: selected ? Pal.cobaltGradient : null,
              borderRadius: BorderRadius.circular(22),
              boxShadow: selected ? [BoxShadow(color: Pal.cobalt.withAlpha(90), blurRadius: 14, offset: const Offset(0, 5))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(selected ? section.activeIcon : section.icon, size: 20, color: selected ? Colors.white : Pal.slate),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: Text(section.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                      )
                    : const SizedBox.shrink(),
              ),
            ]),
          ),
        ),
      );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true, label: 'Ajouter',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: Pal.orangeGradient, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Pal.orange.withAlpha(110), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Menu latéral
// ---------------------------------------------------------------------------
class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.current, required this.onSelect});
  final Section current;
  final ValueChanged<Section> onSelect;

  Widget _group(String? label, List<Section> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 16, 4),
            child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: Pal.slate)),
          ),
        for (final s in items) _DrawerItem(section: s, selected: s == current, onTap: () => onSelect(s)),
      ]);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Drawer(
      width: math.min(300, screenWidth * .82),
      backgroundColor: Colors.white.withAlpha(245),
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 14, 6),
            child: Row(children: [
              Image.asset('assets/images/logo_full.png', height: 28),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: const BoxDecoration(color: Color(0xFFE8EDFB), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 18, color: Pal.cobalt),
                ),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: Pal.cobaltGradient, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Pal.cobaltDark.withAlpha(70), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ESPACE ATELIER', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
              const SizedBox(height: 4),
              Text(store.atelierName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Fraunces', color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Row(children: [
                Icon(Icons.wifi_off_rounded, size: 12, color: Colors.white70),
                SizedBox(width: 6),
                Text('Données disponibles hors ligne', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 4),
          _group(null, [Section.home, Section.orders, Section.clients]),
          _group('Gestion', [Section.finance, Section.apprentices, Section.modeles]),
          _group('Atelier', [Section.gallery, Section.notifications, Section.settings]),
        ]),
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
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
          decoration: BoxDecoration(
            gradient: selected ? Pal.cobaltGradient : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected ? [BoxShadow(color: Pal.cobalt.withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))] : null,
          ),
          child: Row(children: [
            Icon(selected ? section.activeIcon : section.icon, size: 19, color: selected ? Colors.white : Pal.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Text(section.label, style: TextStyle(fontSize: 13.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? Colors.white : const Color(0xFF6B7592))),
            ),
            if (selected) Container(width: 6, height: 6, decoration: const BoxDecoration(color: Pal.orange, shape: BoxShape.circle)),
          ]),
        ),
      );
}
