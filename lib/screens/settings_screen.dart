import '../core/app_brand.dart';
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
  Future<void> _rename(AppStore s) async {
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameAtelierDialog(initialName: s.atelierName),
    );
    if (v != null && mounted) {
      await s.setAtelierName(v);
    }
  }

  Future<void> _toggleReminder(AppStore s, Future<void> Function(bool) setVal, bool v) async {
    await setVal(v);
    if (v && !s.reminderGuideDismissed && mounted) {
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

  Widget _switch(IconData icon, String title, String sub, bool v, ValueChanged<bool> on) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: _Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        subtitle: Text(sub, style: const TextStyle(color: Pal.slate, fontSize: 11.5)),
        trailing: Transform.scale(
          scale: 0.85,
          child: Switch(
            value: v, onChanged: on,
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((st) => st.contains(WidgetState.selected) ? Pal.cobalt : const Color(0xFFD5DAEA)),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ),
      );

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
              _switch(Icons.local_shipping_outlined, 'Livraisons', 'Deux jours avant et le jour même', s.notifDelivery, (v) => _toggleReminder(s, s.setNotifDelivery, v)),
              _switch(Icons.schedule_rounded, 'Essayages', 'La veille et le matin', s.notifFitting, (v) => _toggleReminder(s, s.setNotifFitting, v)),
              _switch(Icons.account_balance_wallet_outlined, 'Paiements', 'Clients et apprentis en attente', s.notifPayments, (v) => _toggleReminder(s, s.setNotifPayments, v)),
              _switch(Icons.warning_amber_rounded, 'Commandes en retard', 'Alerte chaque matin', s.notifLate, (v) => _toggleReminder(s, s.setNotifLate, v)),
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
            onTap: () => push(context, const LockScreen(mode: LockMode.change)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              const _Icon(Icons.lock_outline_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Changer le code d'accès", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text("Modifier le code PIN et le code de récupération", style: TextStyle(color: Pal.slate, fontSize: 11.5)),
                ]),
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
