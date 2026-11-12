import '../ui.dart';
import 'lock_screen.dart';
import 'workshop_setup_screen.dart';
import 'workshop_selector_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Préférences
  bool _delivery = true, _fitting = true, _payments = true, _late = true;

  Future<void> _rename(AppStore s) async {
    final ctrl = TextEditingController(text: s.atelierName);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nom de l'atelier", style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Fraunces')),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: deco('Nom de votre atelier'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Enregistrer')),
        ],
      ),
    );
    ctrl.dispose();
    if (v != null) s.setAtelierName(v);
  }

  Future<void> _editStamp(AppStore s) async {
    final titleCtrl = TextEditingController(text: s.receiptStampTitle);
    final atelierCtrl = TextEditingController(
      text: s.receiptStampAtelierName.isNotEmpty ? s.receiptStampAtelierName : s.currentAtelier.name,
    );
    final mentionCtrl = TextEditingController(text: s.receiptStampMention);
    int selectedColor = s.receiptStampColorValue;

    const colorPresets = [
      (0xFFB3362B, 'Rouge Brique'),
      (0xFF4A2E1B, 'Bogolan'),
      (0xFF0E5A3A, 'Vert Couture'),
      (0xFFC98A2B, 'Ocre Doré'),
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = AppColors.of(context);
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Personnaliser le cachet officiel',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ce tampon authentifie vos reçus de versement et s\'anime à chaque paiement.',
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontSize: 12.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Titre (ex: VERSÉ)
                    TextField(
                      controller: titleCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: deco('Titre principal (ex: VERSÉ, ACOMPTE, PAYÉ)'),
                    ),
                    const SizedBox(height: 12),

                    // Champ Atelier
                    TextField(
                      controller: atelierCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: deco('Nom de l\'atelier sur le tampon'),
                    ),
                    const SizedBox(height: 12),

                    // Champ Mention légale
                    TextField(
                      controller: mentionCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: deco('Mention de certification (ex: OFFICIEL & CERTIFIÉ)'),
                    ),
                    const SizedBox(height: 16),

                    // Teinte d'encre
                    Text(
                      'Couleur d\'encre du cachet',
                      style: TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: colorPresets.map((preset) {
                        final isSel = selectedColor == preset.$1;
                        final col = Color(preset.$1);
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedColor = preset.$1),
                          child: Column(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: col,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? Pal.ocre : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    if (isSel)
                                      BoxShadow(
                                        color: col.withAlpha(80),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: isSel
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preset.$2,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel ? colors.textPrimary : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 22),

                    FilledButton(
                      onPressed: () {
                        s.updateReceiptStamp(
                          title: titleCtrl.text,
                          atelierName: atelierCtrl.text,
                          mention: mentionCtrl.text,
                          colorValue: selectedColor,
                        );
                        Navigator.pop(ctx);
                        toast(context, 'Cachet du reçu enregistré');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Pal.terreBogolan,
                        foregroundColor: Pal.cremeCoton,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Enregistrer le cachet', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    atelierCtrl.dispose();
    mentionCtrl.dispose();
  }

  Widget _switch(IconData icon, String title, String sub, bool v, ValueChanged<bool> on) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        leading: _Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        subtitle: Text(sub, style: const TextStyle(color: Pal.slate, fontSize: 11.5)),
        trailing: Transform.scale(
          scale: 0.85,
          child: Switch(
            value: v,
            onChanged: on,
            activeColor: Pal.ocre,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Pal.sombreBordure : Pal.bordure;

    return SectionPage(
      title: 'Paramètres',
      eyebrow: 'Préférences & SaaS',
      onMenu: widget.onMenu,
      child: ListView(
        padding: kListPadding,
        children: [
          // Carte Atelier SaaS actif
          StaggeredFadeIn(
            index: 0,
            isCard: true,
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Pal.ocre, width: 1.2),
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/brand/png/emblem_512.png', fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.atelierName,
                          style: const TextStyle(fontFamily: 'Fraunces', fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${s.currentAtelier.city} (${s.currentAtelier.country}) · Devise : ${s.currentAtelier.currency}',
                          style: const TextStyle(color: Pal.slate, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _rename(s),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: Pal.ocre),
                    tooltip: 'Renommer',
                  ),
                ],
              ),
            ),
          ),

          // Gestion Multi-Ateliers SaaS
          const StaggeredFadeIn(index: 1, child: Heading('Gestion Multi-Ateliers (SaaS)')),
          StaggeredFadeIn(
            index: 2,
            isCard: true,
            child: Panel(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    leading: const _Icon(Icons.storefront_rounded),
                    title: const Text('Changer d\'atelier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: Text('${s.ateliers.length} atelier(s) configuré(s)', style: const TextStyle(color: Pal.slate, fontSize: 11.5)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Pal.slate, size: 20),
                    onTap: () => WorkshopSelectorSheet.show(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const _Icon(Icons.add_business_outlined),
                    title: const Text('Créer un nouvel atelier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Ajouter une autre succursale ou salon', style: TextStyle(color: Pal.slate, fontSize: 11.5)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Pal.slate, size: 20),
                    onTap: () => push(context, WorkshopSetupScreen(phoneNumber: s.currentAtelier.phone)),
                  ),
                ],
              ),
            ),
          ),

          // Cachet officiel sur les reçus
          const StaggeredFadeIn(index: 3, child: Heading('Cachet officiel sur les reçus')),
          StaggeredFadeIn(
            index: 4,
            isCard: true,
            child: Panel(
              onTap: () => _editStamp(s),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Aperçu miniature du tampon officiel
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(s.receiptStampColorValue).withAlpha(20),
                      border: Border.all(color: Color(s.receiptStampColorValue), width: 1.8),
                    ),
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(s.receiptStampColorValue).withAlpha(150), width: 0.9),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_rounded, size: 13, color: Color(s.receiptStampColorValue)),
                            Text(
                              s.receiptStampTitle.toUpperCase(),
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 6.5,
                                fontWeight: FontWeight.w900,
                                color: Color(s.receiptStampColorValue),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              (s.receiptStampAtelierName.isNotEmpty ? s.receiptStampAtelierName : s.currentAtelier.name).toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 4.5,
                                fontWeight: FontWeight.w700,
                                color: Color(s.receiptStampColorValue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personnaliser le cachet',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Texte : "${s.receiptStampTitle}" · ${s.receiptStampMention}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Pal.slate, fontSize: 11.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Atelier : ${s.receiptStampAtelierName.isNotEmpty ? s.receiptStampAtelierName : s.currentAtelier.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Pal.ocre, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined, color: Pal.slate, size: 20),
                ],
              ),
            ),
          ),

          // Rappels d'atelier
          const StaggeredFadeIn(index: 5, child: Heading('Rappels d\'atelier')),
          StaggeredFadeIn(
            index: 6,
            isCard: true,
            child: Panel(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _switch(Icons.local_shipping_outlined, 'Livraisons', 'Deux jours avant et le jour même', _delivery, (v) => setState(() => _delivery = v)),
                  _switch(Icons.straighten_rounded, 'Essayages', 'La veille et le matin', _fitting, (v) => setState(() => _fitting = v)),
                  _switch(Icons.account_balance_wallet_outlined, 'Acomptes & Soldes', 'Alertes paiements en attente', _payments, (v) => setState(() => _payments = v)),
                  _switch(Icons.warning_amber_rounded, 'Commandes en retard', 'Alerte chaque matin', _late, (v) => setState(() => _late = v)),
                ],
              ),
            ),
          ),

          // Sécurité
          const StaggeredFadeIn(index: 7, child: Heading('Sécurité')),
          StaggeredFadeIn(
            index: 8,
            isCard: true,
            child: Panel(
              onTap: () => push(context, const LockScreen()),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: const Row(
                children: [
                  _Icon(Icons.lock_outline_rounded),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Code d'accès atelier", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Text("Verrouillage rapide de l'application", style: TextStyle(color: Pal.slate, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Pal.slate, size: 20),
                ],
              ),
            ),
          ),

          // Données & Synchronisation
          const StaggeredFadeIn(index: 9, child: Heading('Données & Synchronisation')),
          StaggeredFadeIn(
            index: 10,
            isCard: true,
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const _Icon(Icons.cloud_done_outlined),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mode Hors-ligne', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        Text('Données stockées localement sur votre téléphone', style: TextStyle(color: Pal.slate, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Pal.statutPreteBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Pal.statutPreteFg.withAlpha(60)),
                    ),
                    child: const Text(
                      'Actif',
                      style: TextStyle(color: Pal.statutPreteFg, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const StaggeredFadeIn(
            index: 11,
            child: Center(
              child: Text(
                'MIVA COUTURE SAAS · Version 1.0\nPlateforme de Haute Couture Africaine',
                textAlign: TextAlign.center,
                style: TextStyle(color: Pal.slate, fontSize: 11.5, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  const _Icon(this.icon);
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Pal.cremeCoton.withAlpha(isDark ? 30 : 150),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 19, color: Pal.terreBogolan),
    );
  }
}
