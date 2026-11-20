import '../core/app_brand.dart';
import '../data/services/pin_security_service.dart';
import '../data/services/system_reminder_service.dart';
import '../ui.dart';
import 'lock_screen.dart';
import 'reminder_guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    try {
      final pinService = context.read<PinSecurityService?>();
      if (pinService != null) {
        final isSet = await pinService.isPinSet();
        if (mounted) {
          setState(() {
            _hasPin = isSet;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handlePinAction() async {
    if (_hasPin) {
      await push(context, const LockScreen(mode: LockMode.change));
    } else {
      await push(context, const LockScreen(mode: LockMode.create, isRoot: false));
    }
    if (mounted) {
      await _checkPinStatus();
    }
  }

  Future<void> _rename(AppStore s) async {
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameAtelierDialog(initialName: s.atelierName),
    );
    if (v != null && mounted) {
      await s.setAtelierName(v);
    }
  }

  Future<void> _chooseReminderMode({
    required BuildContext context,
    required AppStore s,
    required String title,
    required ReminderMode currentMode,
    required Future<void> Function(ReminderMode) onSelect,
  }) async {
    final selected = await showModalBottomSheet<ReminderMode>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Pal.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Rappel : $title',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choisissez comment vous souhaitez être alerté :',
                style: TextStyle(color: Pal.slate, fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              _modeOption(
                ctx,
                mode: ReminderMode.alarm,
                selected: currentMode == ReminderMode.alarm,
                icon: Icons.alarm_rounded,
                iconColor: const Color(0xFFB45309),
                title: 'Alarme réveil plein écran',
                subtitle: 'Sonne et vibre en plein écran jusqu\'à arrêt ou report (1 min max)',
              ),
              const SizedBox(height: 8),
              _modeOption(
                ctx,
                mode: ReminderMode.notification,
                selected: currentMode == ReminderMode.notification,
                icon: Icons.notifications_active_outlined,
                iconColor: Pal.cobalt,
                title: 'Notification standard',
                subtitle: 'Bip discret et notification push ou bandeau in-app',
              ),
              const SizedBox(height: 8),
              _modeOption(
                ctx,
                mode: ReminderMode.none,
                selected: currentMode == ReminderMode.none,
                icon: Icons.notifications_off_outlined,
                iconColor: Pal.slate,
                title: 'Désactivé',
                subtitle: 'Aucune alerte ni notification pour cet événement',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      if (selected != ReminderMode.none) {
        final reminderService = context.read<SystemReminderService?>();
        if (reminderService != null) {
          final notifs = await reminderService.areNotificationsGranted();
          if (!notifs) {
            final granted = await reminderService.requestNotificationsPermission();
            if (!granted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Autorisation manquante : les notifications doivent être activées pour choisir ce mode.'),
                    backgroundColor: Pal.thread,
                  ),
                );
              }
              return; // Bloquer l'activation
            }
          }

          if (selected == ReminderMode.alarm && mounted) {
            final canOverlay = await reminderService.canDrawOverlays();
            if (!canOverlay && mounted) {
              final setupOverlay = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Alarme plein écran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  content: const Text(
                    'Pour que l\'alarme prenne tout l\'écran même si votre téléphone est allumé ou sur une autre application, autorisez "Afficher sur les autres applications".',
                    style: TextStyle(fontSize: 13.5, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Plus tard', style: TextStyle(color: Pal.slate)),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: FilledButton.styleFrom(backgroundColor: Pal.cobalt),
                      child: const Text('Activer', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              );
              if (setupOverlay == true) {
                await reminderService.openOverlaySettings();
              }
            }
          }
        }
      }

      await onSelect(selected);

      if (selected != ReminderMode.none && !s.reminderGuideDismissed && mounted) {
        await s.setReminderGuideDismissed(true);
        final open = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Pour que vos rappels sonnent bien', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            content: const Text(
              'Certains téléphones (Tecno, Infinix, Xiaomi...) coupent les rappels lorsque l\'écran est éteint.\n\nSouhaitez-vous voir comment régler votre téléphone en 1 minute ?',
              style: TextStyle(fontSize: 13.5, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Plus tard', style: TextStyle(color: Pal.slate)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Pal.cobalt),
                child: const Text('Voir le guide', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        if (open == true && mounted) {
          push(context, const ReminderGuideScreen());
        }
      }
    }
  }

  static Widget _modeOption(
    BuildContext ctx, {
    required ReminderMode mode,
    required bool selected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? iconColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? iconColor : Pal.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: selected ? iconColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Pal.slate, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _reminderRow({
    required IconData icon,
    required String title,
    required String sub,
    required ReminderMode mode,
    required VoidCallback onTap,
  }) {
    final (Color bg, Color fg, IconData modeIcon, String modeText) = switch (mode) {
      ReminderMode.alarm => (
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
        Icons.alarm_rounded,
        'Alarme',
      ),
      ReminderMode.notification => (
        const Color(0xFFE8EDFB),
        Pal.cobalt,
        Icons.notifications_active_outlined,
        'Notif',
      ),
      ReminderMode.none => (
        const Color(0xFFF1F5F9),
        Pal.slate,
        Icons.notifications_off_outlined,
        'Off',
      ),
    };

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      leading: _Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      subtitle: Text(sub, style: const TextStyle(color: Pal.slate, fontSize: 11.5)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(modeIcon, size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              modeText,
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg),
            ),
            const SizedBox(width: 2),
            Icon(Icons.unfold_more_rounded, size: 14, color: fg),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    return SectionPage(
      title: 'Paramètres',
      eyebrow: 'Préférences',
      onMenu: widget.onMenu,
      child: ListView(padding: kListPadding, children: [
        StaggeredFadeIn(
          index: 0,
          isCard: true,
          child: Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Image.asset('assets/images/logo_mark.png', height: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.atelierName, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 17, fontWeight: FontWeight.w700)),
                  const Text(AppBrand.appName, style: TextStyle(color: Pal.slate, fontSize: 12)),
                ]),
              ),
              IconButton(onPressed: () => _rename(s), icon: const Icon(Icons.edit_outlined, size: 18, color: Pal.cobalt), tooltip: 'Renommer'),
            ]),
          ),
        ),
        const StaggeredFadeIn(index: 1, child: Heading('Rappels')),
        StaggeredFadeIn(
          index: 2,
          isCard: true,
          child: Panel(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(children: [
              _reminderRow(
                icon: Icons.local_shipping_outlined,
                title: 'Livraisons',
                sub: 'La veille à 18h et le jour J à 8h',
                mode: s.deliveryMode,
                onTap: () => _chooseReminderMode(
                  context: context,
                  s: s,
                  title: 'Livraisons',
                  currentMode: s.deliveryMode,
                  onSelect: s.setDeliveryMode,
                ),
              ),
              _reminderRow(
                icon: Icons.schedule_rounded,
                title: 'Essayages',
                sub: 'La veille à 18h et le jour J',
                mode: s.fittingMode,
                onTap: () => _chooseReminderMode(
                  context: context,
                  s: s,
                  title: 'Essayages',
                  currentMode: s.fittingMode,
                  onSelect: s.setFittingMode,
                ),
              ),
              _reminderRow(
                icon: Icons.school_outlined,
                title: 'Échéances d\'apprentis',
                sub: 'Le jour J à 8h',
                mode: s.apprenticeMode,
                onTap: () => _chooseReminderMode(
                  context: context,
                  s: s,
                  title: 'Échéances d\'apprentis',
                  currentMode: s.apprenticeMode,
                  onSelect: s.setApprenticeMode,
                ),
              ),
              _reminderRow(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Soldes en attente',
                sub: 'Commandes prêtes avec solde dû (in-app)',
                mode: s.paymentsMode,
                onTap: () => _chooseReminderMode(
                  context: context,
                  s: s,
                  title: 'Soldes en attente',
                  currentMode: s.paymentsMode,
                  onSelect: s.setPaymentsMode,
                ),
              ),
              _reminderRow(
                icon: Icons.warning_amber_rounded,
                title: 'Commandes en retard',
                sub: 'Commandes dépassées non livrées (in-app)',
                mode: s.lateMode,
                onTap: () => _chooseReminderMode(
                  context: context,
                  s: s,
                  title: 'Commandes en retard',
                  currentMode: s.lateMode,
                  onSelect: s.setLateMode,
                ),
              ),
              const Divider(height: 1, indent: 14, endIndent: 14, color: Pal.line),
              ListTile(
                onTap: () => push(context, const ReminderGuideScreen()),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                leading: const _Icon(Icons.help_outline_rounded),
                title: const Text('Pour que les rappels sonnent', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                subtitle: const Text('Guide de réglages et test de sonnerie', style: TextStyle(color: Pal.slate, fontSize: 11.5)),
                trailing: const Icon(Icons.chevron_right_rounded, color: Pal.slate, size: 20),
              ),
            ]),
          ),
        ),
        const StaggeredFadeIn(index: 3, child: Heading('Sécurité')),
        StaggeredFadeIn(
          index: 4,
          isCard: true,
          child: Panel(
            onTap: _handlePinAction,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              _Icon(_hasPin ? Icons.lock_outline_rounded : Icons.lock_open_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    _hasPin ? "Changer le code d'accès" : "Créer un code d'accès",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  Text(
                    _hasPin
                        ? "Modifier le code PIN et le code de récupération"
                        : "Protéger l'accès à l'atelier par code PIN",
                    style: const TextStyle(color: Pal.slate, fontSize: 11.5),
                  ),
                ]),
              ),
              if (!_hasPin)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: Pal.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Pal.orange.withAlpha(60)),
                  ),
                  child: const Text(
                    'Non défini',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Pal.orange,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: Pal.slate, size: 20),
            ]),
          ),
        ),
        const StaggeredFadeIn(index: 5, child: Heading('Données')),
        StaggeredFadeIn(
          index: 6,
          isCard: true,
          child: Panel(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              const _Icon(Icons.cloud_done_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sauvegarde', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text('Données disponibles hors ligne', style: TextStyle(color: Pal.slate, fontSize: 11.5)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFDEBDD), borderRadius: BorderRadius.circular(12)),
                child: const Text('Maquette', style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        const StaggeredFadeIn(
          index: 7,
          child: Center(child: Text('${AppBrand.appName} · version 0.1.0\nRéalisé par Digital Vision', textAlign: TextAlign.center, style: TextStyle(color: Pal.slate, fontSize: 11.5, height: 1.4))),
        ),
      ]),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: const Color(0xFFE8EDFB), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Pal.cobalt, size: 18),
      );
}

class _RenameAtelierDialog extends StatefulWidget {
  const _RenameAtelierDialog({required this.initialName});
  final String initialName;

  @override
  State<_RenameAtelierDialog> createState() => _RenameAtelierDialogState();
}

class _RenameAtelierDialogState extends State<_RenameAtelierDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nom de l'atelier", style: TextStyle(fontWeight: FontWeight.w800)),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: deco('Nom'),
        onSubmitted: (val) => Navigator.pop(context, val),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(context, _ctrl.text), child: const Text('Enregistrer')),
      ],
    );
  }
}
