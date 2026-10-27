import '../ui.dart';
import 'lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Interrupteurs purement visuels (maquette).
  bool _delivery = true, _fitting = true, _payments = true, _late = true;

  Future<void> _rename(AppStore s) async {
    final ctrl = TextEditingController(text: s.atelierName);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nom de l'atelier", style: TextStyle(fontWeight: FontWeight.w800)),
        content: TextField(controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.words, decoration: deco('Nom')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    ctrl.dispose();
    if (v != null) s.setAtelierName(v);
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
                  const Text('Angela Déesse', style: TextStyle(color: Pal.slate, fontSize: 12)),
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
              _switch(Icons.local_shipping_outlined, 'Livraisons', 'Deux jours avant et le jour même', _delivery, (v) => setState(() => _delivery = v)),
              _switch(Icons.schedule_rounded, 'Essayages', 'La veille et le matin', _fitting, (v) => setState(() => _fitting = v)),
              _switch(Icons.account_balance_wallet_outlined, 'Paiements', 'Clients et apprentis en attente', _payments, (v) => setState(() => _payments = v)),
              _switch(Icons.warning_amber_rounded, 'Commandes en retard', 'Alerte chaque matin', _late, (v) => setState(() => _late = v)),
            ]),
          ),
        ),
        const StaggeredFadeIn(index: 3, child: Heading('Sécurité')),
        StaggeredFadeIn(
          index: 4,
          isCard: true,
          child: Panel(
            onTap: () => push(context, const LockScreen()),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              const _Icon(Icons.lock_outline_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Code d'accès", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  Text("Aperçu de l'écran de verrouillage", style: TextStyle(color: Pal.slate, fontSize: 11.5)),
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
          child: Center(child: Text('Angela Déesse · version 0.1.0 (maquette UI)\nRéalisé par Digital Vision', textAlign: TextAlign.center, style: TextStyle(color: Pal.slate, fontSize: 11.5, height: 1.4))),
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
