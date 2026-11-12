import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/store.dart';
import 'auth_phone_screen.dart';

/// Écran Onboarding Miva Couture reproduit fidèlement d'après les maquettes fournies :
/// - Sélecteur "FR Français" & Bouton "Passer"
/// - Disque beige couture avec contour en pointillés et ciseaux qui coupent
/// - 4 étapes clés :
///   1. "Toutes vos clientes et leurs mesures au même endroit"
///   2. "Ne ratez plus aucune livraison ni aucun essayage"
///   3. "Suivez chaque acompte et chaque reste à payer"
///   4. "Travaillez même sans internet, tout est sauvegardé"
/// - Indicateurs 4 points & Bouton "Suivant" / "Commencer"
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<({String title, IconData icon})> _slides = const [
    (
      title: 'Toutes vos clientes et\nleurs mesures au même\nendroit',
      icon: Icons.people_outline_rounded,
    ),
    (
      title: 'Ne ratez plus aucune\nlivraison ni aucun\nessayage',
      icon: Icons.calendar_month_outlined,
    ),
    (
      title: 'Suivez chaque acompte\net chaque reste à payer',
      icon: Icons.account_balance_wallet_outlined,
    ),
    (
      title: 'Travaillez même sans\ninternet, tout est\nsauvegardé',
      icon: Icons.cloud_done_outlined,
    ),
  ];

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _goToAuth();
    }
  }

  void _goToAuth() {
    context.read<AppStore>().completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthPhoneScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Barre supérieure : Bouton "FR Français" et "Passer"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: softShadow(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'FR ',
                          style: TextStyle(
                            fontFamily: 'Public Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Français',
                          style: TextStyle(
                            fontFamily: 'Public Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _goToAuth,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      textStyle: const TextStyle(
                        fontFamily: 'Public Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    child: const Text('Passer'),
                  ),
                ],
              ),
            ),

            // Carrousel des 4 slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final slide = _slides[index];

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 1),

                        // Médaillon élégant avec cercle en pointillés et ciseaux de coupe
                        _ScissorsCutCircle(icon: slide.icon),

                        const SizedBox(height: 36),

                        // Titre en Fraunces marron terre bogolan (taille proportionnée et lisible)
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 21.5,
                            fontWeight: FontWeight.w700,
                            height: 1.28,
                            color: colors.textPrimary,
                          ),
                        ),

                        const Spacer(flex: 2),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination 4 tirets/points fins
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (idx) {
                final isSelected = idx == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 24 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Pal.ocre : Pal.cremeCoton.withAlpha(colors.isDark ? 60 : 180),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Bouton inférieur "Suivant" ou "Commencer"
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.terreBogolan,
                    foregroundColor: Pal.cremeCoton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLast ? 'Commencer' : 'Suivant',
                    style: const TextStyle(
                      fontFamily: 'Public Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disque beige doux entouré d'une couture pointillée et de ciseaux de tailleur
class _ScissorsCutCircle extends StatelessWidget {
  const _ScissorsCutCircle({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final discColor = colors.isDark ? Pal.sombreSurfaceElevated : const Color(0xFFF1E5CF);
    final strokeColor = Pal.ocre.withAlpha(colors.isDark ? 100 : 180);

    return SizedBox(
      width: 184,
      height: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Disque beige de fond
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: discColor,
            ),
          ),

          // Ligne circulaire pointillée
          CustomPaint(
            size: const Size(146, 146),
            painter: _DashedCirclePainter(color: strokeColor),
          ),

          // Icône centrale marron couture
          Icon(
            icon,
            size: 54,
            color: colors.isDark ? Pal.sombreTexte : Pal.terreBogolan,
          ),

          // Ciseaux de couture sur le tracé pointillé en haut à droite
          Positioned(
            top: 15,
            right: 14,
            child: Transform.rotate(
              angle: -0.4,
              child: const Icon(
                Icons.content_cut_rounded,
                size: 23,
                color: Pal.terreRouge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Traceur de cercle en pointillés
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    const totalDashes = 36;
    const dashArc = (2 * math.pi) / totalDashes;
    const drawFraction = 0.55;

    for (int i = 0; i < totalDashes; i++) {
      final startAngle = i * dashArc;
      final sweepAngle = dashArc * drawFraction;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) => oldDelegate.color != color;
}
