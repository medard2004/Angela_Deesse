import '../ui.dart';

/// Écran Galerie & Lookbook Haute Couture Africaine
/// Un design éditorial façon magazine de mode, simple mais raffiné :
/// - Catégories couture en capsules élégantes
/// - Carte vedette « Pièce Maîtresse » en tête d'affiche
/// - Grille lookbook à 2 colonnes en ratio portrait (3:4)
/// - Typographie Fraunces & Public Sans dans la palette Bogolan
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
    final colors = AppColors.of(context);
    final s = context.watch<AppStore>();
    final cats = {...kCategories, ...s.realisations.map((r) => r.category).where((c) => c.isNotEmpty)}.toList();
    final list = s.realisations
        .where((r) => (_category == null || r.category == _category) && (_clientId == null || r.clientId == _clientId))
        .toList();

    // Barre horizontale de catégories de tissus & coupes couture
    Widget categoriesPills = SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _LookbookChip(
            label: 'Toutes les créations',
            count: s.realisations.length,
            selected: _category == null,
            onTap: () => setState(() => _category = null),
          ),
          for (final c in cats)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _LookbookChip(
                label: c,
                count: s.realisations.where((r) => r.category == c).length,
                selected: _category == c,
                onTap: () => setState(() => _category = c),
              ),
            ),
        ],
      ),
    );

    // Filtre client discret
    Widget clientFilterBar = s.clients.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickClientFilter(context, s),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _clientId != null ? Pal.ocre : colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline_rounded,
                            size: 16,
                            color: _clientId != null ? Pal.ocre : colors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _clientId != null
                                  ? 'Cliente : ${s.clientById(_clientId)?.name ?? ""}'
                                  : 'Filtrer par cliente (toutes)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: _clientId != null ? FontWeight.w700 : FontWeight.w500,
                                color: _clientId != null ? colors.textPrimary : colors.textSecondary,
                              ),
                            ),
                          ),
                          if (_clientId != null)
                            GestureDetector(
                              onTap: () => setState(() => _clientId = null),
                              child: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                            )
                          else
                            Icon(Icons.arrow_drop_down_rounded, size: 20, color: colors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    // Pièce vedette (la première réalisation de la liste filtrée)
    final featured = list.isNotEmpty ? list.first : null;
    final otherItems = list.length > 1 ? list.sublist(1) : <Realisation>[];

    return SectionPage(
      title: 'Galerie',
      eyebrow: 'Lookbook Couture',
      onMenu: widget.onMenu,
      actions: [
        titleAction(
          Icons.add_a_photo_outlined,
          () => push(context, const RealisationFormScreen()),
          'Ajouter une création',
        ),
      ],
      child: TwoPhaseLoader(
        skeleton: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: categoriesPills),
            if (s.clients.isNotEmpty) SliverToBoxAdapter(child: clientFilterBar),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
                children: List.generate(4, (_) => Container(
                  decoration: BoxDecoration(color: Pal.line.withAlpha(120), borderRadius: BorderRadius.circular(12)),
                )),
              ),
            ),
          ],
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: categoriesPills),
            if (s.clients.isNotEmpty) SliverToBoxAdapter(child: clientFilterBar),

            if (list.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Pal.cremeCoton.withAlpha(colors.isDark ? 30 : 180),
                          ),
                          child: const Icon(Icons.photo_library_outlined, size: 34, color: Pal.terreBogolan),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun modèle dans cette sélection',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Photographiez vos robes, bazins et pagnes terminés pour constituer le lookbook exclusif de votre atelier.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: colors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: () => push(context, const RealisationFormScreen()),
                          icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: const Text('Ajouter une pièce'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Pal.terreBogolan,
                            foregroundColor: Pal.cremeCoton,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              // Carte Vedette « Pièce Maîtresse de l'Atelier »
              if (featured != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                    child: _FeaturedLookbookCard(
                      realisation: featured,
                      clientName: s.clientById(featured.clientId)?.name,
                      onTap: () => push(context, RealisationDetailScreen(realisationId: featured.id)),
                    ),
                  ),
                ),

              // Grille Lookbook Magazine (2 colonnes élégantes au ratio portrait 3:4)
              if (otherItems.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'COLLECTION RÉCENTE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '${otherItems.length} pièce(s)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Pal.ocre,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final r = otherItems[index];
                        return _LookbookItemCard(
                          realisation: r,
                          clientName: s.clientById(r.clientId)?.name,
                          onTap: () => push(context, RealisationDetailScreen(realisationId: r.id)),
                        );
                      },
                      childCount: otherItems.length,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickClientFilter(BuildContext context, AppStore s) async {
    final res = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = AppColors.of(ctx);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Text('Filtrer par cliente', style: TextStyle(fontFamily: 'Fraunces', fontSize: 17, fontWeight: FontWeight.w700, color: colors.textPrimary)),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Toutes les clientes', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: _clientId == null ? const Icon(Icons.check, color: Pal.ocre) : null,
                onTap: () => Navigator.pop(ctx, ''),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: s.clients.length,
                  itemBuilder: (_, i) {
                    final c = s.clients[i];
                    final isSel = c.id == _clientId;
                    return ListTile(
                      title: Text(c.name, style: TextStyle(fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                      trailing: isSel ? const Icon(Icons.check, color: Pal.ocre) : null,
                      onTap: () => Navigator.pop(ctx, c.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (res != null) {
      setState(() => _clientId = res.isEmpty ? null : res);
    }
  }
}

/// Capsule de catégorie lookbook
class _LookbookChip extends StatelessWidget {
  const _LookbookChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bg = selected ? Pal.terreBogolan : colors.surface;
    final fg = selected ? Pal.cremeCoton : colors.textPrimary;
    final border = selected ? Pal.terreBogolan : colors.border;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: softShadow(selected ? 6 : 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Public Sans',
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? Pal.ocre : Pal.cremeCoton.withAlpha(colors.isDark ? 40 : 150),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? Pal.blanc : colors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Carte vedette « Pièce Maîtresse de la Maison »
class _FeaturedLookbookCard extends StatelessWidget {
  const _FeaturedLookbookCard({
    required this.realisation,
    required this.clientName,
    required this.onTap,
  });

  final Realisation realisation;
  final String? clientName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
          boxShadow: softShadow(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de fond
            PhotoThumb(
              realisation.photo,
              size: double.infinity,
              radius: 0,
              onTap: onTap,
            ),

            // Dégradé sombre couture en bas pour lisibilité
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(30),
                      Colors.black.withAlpha(70),
                      Colors.black.withAlpha(210),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Badge Haute Couture en haut
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Pal.ocre,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: softShadow(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    const Text(
                      'PIÈCE MAÎTRESSE',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Badge Catégorie en haut à droite
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  realisation.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Pal.cremeCoton,
                  ),
                ),
              ),
            ),

            // Textes & informations en bas
            Positioned(
              bottom: 12,
              left: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    realisation.caption.isNotEmpty ? realisation.caption : 'Création ${realisation.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (clientName != null) ...[
                        const Icon(Icons.person_rounded, size: 12, color: Pal.cremeCoton),
                        const SizedBox(width: 4),
                        Text(
                          clientName!,
                          style: const TextStyle(
                            fontFamily: 'Public Sans',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Pal.cremeCoton,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('·', style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        fmtDate(realisation.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(190),
                        ),
                      ),
                    ],
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

/// Carte lookbook portrait 3:4 individuelle
class _LookbookItemCard extends StatelessWidget {
  const _LookbookItemCard({
    required this.realisation,
    required this.clientName,
    required this.onTap,
  });

  final Realisation realisation;
  final String? clientName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
          boxShadow: softShadow(3),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone visuelle avec badge tissu
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoThumb(
                    realisation.photo,
                    size: double.infinity,
                    radius: 0,
                    onTap: onTap,
                  ),

                  // Dégradé léger en bas
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(80),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Badge Catégorie
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        realisation.category,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Cartouche d'informations typographiques
            Padding(
              padding: const EdgeInsets.all(9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    realisation.caption.isNotEmpty ? realisation.caption : realisation.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          clientName ?? 'Création salon',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Public Sans',
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        fmtDate(realisation.createdAt).split(' ').first,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: colors.textSecondary.withAlpha(160),
                        ),
                      ),
                    ],
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
  String _category = kCategories.first;
  String? _clientId;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_photo == null) return toast(context, 'Ajoutez une photo pour la galerie');
    await context.read<AppStore>().saveRealisation(
          Realisation(
            id: newId(),
            photo: _photo!,
            category: _category,
            clientId: _clientId,
            caption: _caption.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle réalisation'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
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
          const SizedBox(height: 16),
          StaggeredFadeIn(
            index: 1,
            child: PickerField<String>(
              label: 'Catégorie de tenue',
              value: _category,
              items: [for (final c in kCategories) (c, c)],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 2,
            child: PickerField<String>(
              label: 'Cliente (facultatif)',
              value: _clientId,
              allowClear: true,
              items: [for (final c in s.clients) (c.id, c.name)],
              onChanged: (v) => setState(() => _clientId = v),
            ),
          ),
          const SizedBox(height: 14),
          StaggeredFadeIn(
            index: 3,
            child: TextField(
              controller: _caption,
              textCapitalization: TextCapitalization.sentences,
              decoration: deco('Légende / Modèle (ex: Robe Bazin Brodé Or)'),
            ),
          ),
          const SizedBox(height: 28),
          StaggeredFadeIn(
            index: 4,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: Pal.terreBogolan,
                foregroundColor: Pal.cremeCoton,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Ajouter au lookbook', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class RealisationDetailScreen extends StatelessWidget {
  const RealisationDetailScreen({super.key, required this.realisationId});
  final String realisationId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = context.watch<AppStore>();
    final r = s.realisations.where((x) => x.id == realisationId).firstOrNull;
    if (r == null) return const Scaffold(body: Center(child: Text('Photo introuvable')));
    final client = s.clientById(r.clientId);
    final w = MediaQuery.sizeOf(context).width - 32;

    return Scaffold(
      appBar: AppBar(
        title: Text(r.caption.isNotEmpty ? r.caption : r.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: () async {
              if (await confirm(context, 'Retirer cette photo ?', 'Elle sera retirée du lookbook de l\'atelier.')) {
                await s.deleteRealisation(r.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Grande image hero lookbook
          FeaturedHeroImage(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
                boxShadow: softShadow(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: PhotoThumb(r.photo, size: w, radius: 16),
            ),
          ),
          const SizedBox(height: 18),

          // En-tête éditorial
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Pal.cremeCoton.withAlpha(colors.isDark ? 30 : 160),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        r.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Pal.ocre,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.caption.isNotEmpty ? r.caption : 'Création ${r.category}',
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
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Cartouche cliente & date
          Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                if (client != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Pal.cremeCoton.withAlpha(colors.isDark ? 40 : 160),
                        ),
                        child: const Icon(Icons.person_rounded, size: 20, color: Pal.terreBogolan),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Confectionnée pour', style: TextStyle(fontSize: 11, color: Pal.slate)),
                            Text(client.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Pal.cremeCoton.withAlpha(colors.isDark ? 40 : 160),
                      ),
                      child: const Icon(Icons.calendar_today_outlined, size: 18, color: Pal.terreBogolan),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Date d\'ajout au lookbook', style: TextStyle(fontSize: 11, color: Pal.slate)),
                        Text(fmtDate(r.createdAt), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
