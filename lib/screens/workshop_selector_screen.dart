import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../widgets/common.dart';
import 'workshop_setup_screen.dart';

/// Modal / Écran de sélection et de gestion multi-ateliers SaaS.
class WorkshopSelectorSheet extends StatelessWidget {
  const WorkshopSelectorSheet({super.key});

  static Future<void> show(BuildContext context) => showMotionBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const WorkshopSelectorSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Pal.sombreSurface : Pal.blanc;
    final textPrimary = isDark ? Pal.sombreTexte : Pal.terreBogolan;
    final borderColor = isDark ? Pal.sombreBordure : Pal.bordure;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de préhension
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Pal.cremeCoton,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // En-tête
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MES ATELIERS SAAS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: Pal.ocre,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Changer d\'atelier',
                        style: TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    push(
                        context,
                        WorkshopSetupScreen(
                            phoneNumber: store.currentAtelier.phone));
                  },
                  icon: const Icon(Icons.add, size: 18, color: Pal.ocre),
                  label: const Text(
                    'Nouvel atelier',
                    style: TextStyle(
                        color: Pal.ocre,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Liste des ateliers
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: store.ateliers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final atelier = store.ateliers[index];
                  final isCurrent = atelier.id == store.currentAtelierId;

                  return GestureDetector(
                    onTap: () {
                      store.switchAtelier(atelier.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Atelier actif : ${atelier.name}'),
                          backgroundColor: Pal.terreBogolan,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: kBorderRadius),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? (isDark
                                ? Pal.sombreSurfaceElevated
                                : Pal.cremeCoton.withAlpha(120))
                            : cardBg,
                        borderRadius: kBorderRadius,
                        border: Border.all(
                          color: isCurrent ? Pal.ocre : borderColor,
                          width: isCurrent ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? Pal.ocre
                                  : Pal.cremeCoton.withAlpha(isDark ? 40 : 160),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 20,
                                color: isCurrent
                                    ? Colors.white
                                    : (isDark ? Pal.cremeCoton : Pal.terreBogolan),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        atelier.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14.5,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Pal.ocre,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'ACTIF',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 9.5,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${atelier.city}, ${atelier.country} · ${atelier.currency}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimary.withAlpha(170),
                                  ),
                                ),
                                if (atelier.specialties.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    atelier.specialties,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: Pal.ocre,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
