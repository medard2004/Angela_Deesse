import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/system_reminder_service.dart';
import '../ui.dart';

/// Modal d'onboarding pédagogique affichant les autorisations requises
/// pour le bon fonctionnement des rappels et de l'alarme plein écran.
class PermissionOnboardingSheet extends StatefulWidget {
  const PermissionOnboardingSheet({
    super.key,
    this.overrideNotificationsGranted,
    this.overrideOverlayGranted,
  });

  final bool? overrideNotificationsGranted;
  final bool? overrideOverlayGranted;

  static const String prefKey = 'has_prompted_permissions_onboarding';

  /// Affiche la feuille d'onboarding si elle n'a pas encore été présentée
  /// et qu'au moins une permission essentielle est manquante.
  static Future<void> showIfNeeded(BuildContext context) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyPrompted = prefs.getBool(prefKey) ?? false;
      if (alreadyPrompted) return;

      if (!context.mounted) return;
      final reminderService = context.read<SystemReminderService?>();
      if (reminderService == null) return;

      final notifs = await reminderService.areNotificationsGranted();
      final overlay = await reminderService.canDrawOverlays();

      // Si toutes les autorisations sont déjà accordées, marquer comme fait sans déranger l'utilisateur
      if (notifs && overlay) {
        await prefs.setBool(prefKey, true);
        return;
      }

      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const PermissionOnboardingSheet(),
      );

      await prefs.setBool(prefKey, true);
    } catch (_) {}
  }

  @override
  State<PermissionOnboardingSheet> createState() => _PermissionOnboardingSheetState();
}

class _PermissionOnboardingSheetState extends State<PermissionOnboardingSheet>
    with WidgetsBindingObserver {
  bool _notificationsGranted = false;
  bool _overlayGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    final reminderService = context.read<SystemReminderService?>();
    if (reminderService == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final notifs = widget.overrideNotificationsGranted ??
        await reminderService.areNotificationsGranted();
    final overlay = widget.overrideOverlayGranted ??
        await reminderService.canDrawOverlays();

    if (mounted) {
      setState(() {
        _notificationsGranted = notifs;
        _overlayGranted = overlay;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotification() async {
    final reminderService = context.read<SystemReminderService?>();
    if (reminderService != null) {
      await reminderService.requestNotificationsPermission();
      await _checkPermissions();
    }
  }

  Future<void> _requestOverlay() async {
    final reminderService = context.read<SystemReminderService?>();
    if (reminderService != null) {
      await reminderService.openOverlaySettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Pal.slate.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Pal.cobalt.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: Pal.cobalt, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertes de votre atelier',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pour ne manquer aucun essayage ni livraison',
                        style: TextStyle(color: Pal.slate, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // Carte 1 : Notifications
              _PermissionTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications de rappels',
                subtitle: 'Recevez les alertes pour vos essayages et livraisons programmés.',
                isGranted: _notificationsGranted,
                buttonLabel: 'Autoriser',
                onAction: _requestNotification,
              ),
              const SizedBox(height: 12),

              // Carte 2 : Plein écran déverrouillé
              _PermissionTile(
                icon: Icons.fullscreen_rounded,
                title: 'Alarme plein écran',
                subtitle: 'Affiche le réveil sur tout l\'écran même si votre téléphone est allumé ou sur une autre application.',
                isGranted: _overlayGranted,
                buttonLabel: 'Activer',
                onAction: _requestOverlay,
              ),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: Pal.cobalt,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _notificationsGranted && _overlayGranted
                    ? 'Continuer'
                    : 'Continuer vers l\'atelier',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isGranted;
  final String buttonLabel;
  final VoidCallback onAction;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isGranted,
    required this.buttonLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Pal.chalk,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? Pal.sage.withValues(alpha: 0.3) : Pal.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isGranted ? Pal.sage : Pal.cobalt,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Pal.slate, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Pal.sage.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Pal.sage, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Activé',
                    style: TextStyle(
                      color: Pal.sage,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            )
          else
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: Pal.orange,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
