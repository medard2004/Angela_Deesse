import '../data/utils/sort_utils.dart';
import '../ui.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String? _category; // null = toutes
  String? _clientId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final cats = {...kCategories, ...s.realisations.map((r) => r.category).where((c) => c.isNotEmpty)}.toList();
    final list = s.realisations
        .where((r) => (_category == null || equalsCaseAndAccentInsensitive(r.category, _category!)) && (_clientId == null || r.clientId == _clientId))
        .toList();

    Widget filtersRow = SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          for (final c in <String?>[null, ...cats])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillChip(label: c ?? 'Toutes', selected: _category == c, onTap: () => setState(() => _category = c)),
            ),
        ],
      ),
    );

    Widget clientFilter = s.clients.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: PickerField<String>(
              label: 'Filtrer par client',
              value: _clientId,
              allowClear: true,
              items: [for (final c in s.clients) (c.id, c.name)],
              onChanged: (v) => setState(() => _clientId = v),
            ),
          )
        : const SizedBox.shrink();

    return SectionPage(
      title: 'Galerie',
      eyebrow: 'Réalisations',
      onMenu: widget.onMenu,
      actions: [titleAction(Icons.add_a_photo_outlined, () => push(context, const RealisationFormScreen()), 'Ajouter une photo')],
      child: TwoPhaseLoader(
        skeleton: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: filtersRow),
            if (s.clients.isNotEmpty) SliverToBoxAdapter(child: clientFilter),
            SliverPadding(
              padding: kListPadding,
              sliver: SliverGrid.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  for (var i = 0; i < 9; i++)
                    Container(
                      decoration: BoxDecoration(color: Pal.line.withAlpha(140), borderRadius: BorderRadius.circular(10)),
                    ),
                ],
              ),
            ),
          ],
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: filtersRow),
            if (s.clients.isNotEmpty) SliverToBoxAdapter(child: clientFilter),
            if (list.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.photo_library_outlined, title: 'Aucune photo', hint: 'Ajoutez les vêtements terminés pour les retrouver comme références.'),
              )
            else
              SliverPadding(
                padding: kListPadding,
                sliver: SliverGrid.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    for (var i = 0; i < list.length; i++)
                      StaggeredFadeIn(
                        index: i,
                        isCard: true,
                        child: LayoutBuilder(builder: (_, c) => PhotoThumb(list[i].photo, size: c.maxWidth, radius: 10, onTap: () => push(context, RealisationDetailScreen(realisationId: list[i].id)))),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RealisationFormScreen extends StatefulWidget {
  const RealisationFormScreen({super.key});
  @override
  State<RealisationFormScreen> createState() => _RealisationFormScreenState();
}

class _RealisationFormScreenState extends State<RealisationFormScreen> {
  final _caption = TextEditingController();
  String? _photo;
  String _category = kCategories.last;
  String? _clientId;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_photo == null) return toast(context, 'Ajoutez une photo');
    await context.read<AppStore>().saveRealisation(Realisation(
        id: newId(), photo: _photo!, category: _category, clientId: _clientId, caption: _caption.text.trim(), createdAt: DateTime.now()));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle réalisation'), backgroundColor: Pal.chalk),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
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
          child: PickerField<String>(
            label: 'Catégorie',
            value: _category,
            items: [for (final c in kCategories) (c, c)],
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
        ),
        const SizedBox(height: 14),
        StaggeredFadeIn(
          index: 2,
          child: PickerField<String>(
            label: 'Client (facultatif)',
            value: _clientId,
            allowClear: true,
            items: [for (final c in s.clients) (c.id, c.name)],
            onChanged: (v) => setState(() => _clientId = v),
          ),
        ),
        const SizedBox(height: 14),
        StaggeredFadeIn(
          index: 3,
          child: TextField(controller: _caption, textCapitalization: TextCapitalization.sentences, decoration: deco('Légende (facultatif)')),
        ),
        const SizedBox(height: 24),
        StaggeredFadeIn(
          index: 4,
          child: FilledButton(onPressed: _save, child: const Text('Ajouter à la galerie')),
        ),
      ]),
    );
  }
}

class RealisationDetailScreen extends StatelessWidget {
  const RealisationDetailScreen({super.key, required this.realisationId});
  final String realisationId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final r = s.realisations.where((x) => x.id == realisationId).firstOrNull;
    if (r == null) return const Scaffold(body: Center(child: Text('Photo introuvable')));
    final client = s.clientById(r.clientId);
    final w = MediaQuery.sizeOf(context).width - 32;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Pal.chalk,
        title: Text(r.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await confirm(context, 'Retirer cette photo ?', 'Elle sera supprimée de la galerie.')) {
                await s.deleteRealisation(r.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
        FeaturedHeroImage(
          child: PhotoThumb(r.photo, size: w, radius: 16),
        ),
        const SizedBox(height: 14),
        if (r.caption.isNotEmpty)
          StaggeredFadeIn(
            index: 0,
            child: Text(r.caption, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        if (r.clientId != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: StaggeredFadeIn(
              index: 1,
              child: Text(client?.name ?? 'Client supprimé', style: const TextStyle(color: Pal.slate)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: StaggeredFadeIn(
            index: 2,
            child: Text(fmtDate(r.createdAt), style: const TextStyle(color: Pal.slate)),
          ),
        ),
      ]),
    );
  }
}
