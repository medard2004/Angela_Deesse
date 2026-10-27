import '../ui.dart';
import 'order_form_screen.dart';

class ModeleFormScreen extends StatefulWidget {
  const ModeleFormScreen({super.key, this.modele});
  final Modele? modele;
  @override
  State<ModeleFormScreen> createState() => _ModeleFormScreenState();
}

class _ModeleFormScreenState extends State<ModeleFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.modele?.name);
  late final _desc = TextEditingController(text: widget.modele?.description);
  late String? _photo = widget.modele?.photo;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await context.read<AppStore>().saveModele(Modele(
        id: widget.modele?.id ?? newId(), name: _name.text.trim(), description: _desc.text.trim(), photo: _photo));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.modele == null ? 'Nouveau modèle' : 'Modifier le modèle'), backgroundColor: Pal.chalk),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            StaggeredFadeIn(
              index: 0,
              child: PhotoStrip(
                photos: [if (_photo != null) _photo!],
                onAdd: () async {
                  final p = await pickPhoto(context);
                  if (p != null) setState(() => _photo = p);
                },
                onRemove: (_) => setState(() => _photo = null),
              ),
            ),
            const SizedBox(height: 14),
            StaggeredFadeIn(
              index: 1,
              child: TextFormField(
                controller: _name, textCapitalization: TextCapitalization.sentences,
                decoration: deco('Nom du modèle'),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Indiquez un nom' : null,
              ),
            ),
            const SizedBox(height: 14),
            StaggeredFadeIn(
              index: 2,
              child: TextFormField(controller: _desc, maxLines: 4, textCapitalization: TextCapitalization.sentences, decoration: deco('Description')),
            ),
            const SizedBox(height: 24),
            StaggeredFadeIn(
              index: 3,
              child: FilledButton(onPressed: _save, child: const Text('Enregistrer')),
            ),
          ]),
        ),
      );
}

class ModeleDetailScreen extends StatelessWidget {
  const ModeleDetailScreen({super.key, required this.modeleId});
  final String modeleId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final m = s.modeleById(modeleId);
    if (m == null) return const Scaffold(body: Center(child: Text('Modèle introuvable')));
    final w = MediaQuery.sizeOf(context).width - 32;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pal.chalk,
        title: const Text('Modèle'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => push(context, ModeleFormScreen(modele: m))),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Supprimer ce modèle ?', 'Les commandes déjà créées ne sont pas modifiées.')) {
                await s.deleteModele(m.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        FeaturedHeroImage(
          child: PhotoThumb(m.photo, size: w, radius: 16),
        ),
        const SizedBox(height: 16),
        StaggeredFadeIn(
          index: 0,
          child: Text(m.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        if (m.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: StaggeredFadeIn(
              index: 1,
              child: Text(m.description, style: const TextStyle(height: 1.4)),
            ),
          ),
        const SizedBox(height: 24),
        StaggeredFadeIn(
          index: 2,
          child: FilledButton.icon(
            icon: const Icon(Icons.checkroom_outlined),
            label: const Text('Créer une commande avec ce modèle'),
            onPressed: () => push(context, OrderFormScreen(modeleId: m.id)),
          ),
        ),
      ]),
    );
  }
}
