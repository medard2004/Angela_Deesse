import '../ui.dart';
import 'modele_screen.dart';

class ModelesScreen extends StatelessWidget {
  const ModelesScreen({super.key, required this.onMenu});
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    return SectionPage(
      title: 'Modèles',
      eyebrow: 'Catalogue',
      onMenu: onMenu,
      actions: [titleAction(Icons.add_rounded, () => push(context, const ModeleFormScreen()), 'Nouveau modèle')],
      child: s.modeles.isEmpty
          ? ListView(children: const [EmptyState(icon: Icons.dry_cleaning_outlined, title: 'Aucun modèle', hint: 'Enregistrez un modèle avec sa photo pour le réutiliser dans vos commandes.')])
          : TwoPhaseLoader(
              skeleton: GridView.count(
                padding: kListPadding,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .82,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Pal.line.withAlpha(120))),
                      child: Column(children: [
                        Expanded(child: Container(color: Pal.chalk)),
                        const Padding(padding: EdgeInsets.all(12), child: SkeletonBox(height: 14)),
                      ]),
                    ),
                ],
              ),
              child: GridView.count(
                padding: kListPadding,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .82,
                children: [
                  for (var i = 0; i < s.modeles.length; i++)
                    StaggeredFadeIn(
                      index: i,
                      isCard: true,
                      child: Material(
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Pal.cobalt.withAlpha(50),
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: InkWell(
                          onTap: () => push(context, ModeleDetailScreen(modeleId: s.modeles[i].id)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Expanded(child: LayoutBuilder(builder: (_, c) => PhotoThumb(s.modeles[i].photo, size: c.maxWidth, radius: 0, onTap: () => push(context, ModeleDetailScreen(modeleId: s.modeles[i].id))))),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(s.modeles[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
