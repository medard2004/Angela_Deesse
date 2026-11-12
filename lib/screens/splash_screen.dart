import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../data/store.dart';
import '../shell/app_shell.dart';
import 'onboarding_screen.dart';

/// Écran Splash Miva Couture avec le LOGO ANIMÉ officiel fidèle au SVG et à la maquette :
/// - Fond beige coton #FAF6EC avec fine trame diagonale de surpiqûres
/// - Emblème officiel animé avec précision vectorielle (60 FPS) :
///     1. Disque terre bogolan qui grandit avec rebond
///     2. Anneau doré en pointillés
///     3. 16 losanges crème et 16 perles dorées qui apparaissent en cascade circulaire
///     4. Cercle d'or qui se trace à 360°
///     5. Disque intérieur brun nuit
///     6. Aiguille de couture qui descend du haut
///     7. Fil d'or cousu en courbe S à travers le chas de l'aiguille
/// - Titre "MivaCouture" (Miva terre bogolan, Couture terre rouge) & devise "Ton atelier dans ta poche"
/// - Transition fluide de sortie vers l'Onboarding
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Timer? _timer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Durée totale de la timeline d'animation (3600 ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _proceed();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _timer = Timer(const Duration(milliseconds: 400), _proceed);
      } else {
        _controller.forward();
      }
    });
  }

  void _proceed() {
    if (_navigated || !mounted) return;
    _navigated = true;

    final store = context.read<AppStore>();
    final destination = (store.hasCompletedOnboarding && store.isAuthenticated)
        ? const AppShell()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Trame diagonale pointillée de couture (fond identique à la capture)
          CustomPaint(
            painter: _StitchedDiagonalBackgroundPainter(
              lineColor: Pal.bordure.withAlpha(colors.isDark ? 30 : 90),
            ),
          ),

          // Contenu central centré verticalement et horizontalement
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = reduceMotion ? 1.0 : _controller.value;

              // Fondu de sortie (de 0.88 à 1.0)
              final exitOpacity = (t > 0.88)
                  ? ((1.0 - t) / 0.12).clamp(0.0, 1.0)
                  : 1.0;

              // Fondu des textes (apparaissent après le tracé du fil, de 0.65 à 0.82)
              final textOpacity = reduceMotion
                  ? 1.0
                  : ((t - 0.65) / 0.17).clamp(0.0, 1.0);
              final textSlideY = reduceMotion
                  ? 0.0
                  : (1.0 - textOpacity) * 8.0;

              return Center(
                child: Opacity(
                  opacity: exitOpacity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // LOGO ANIMÉ VECTORIEL OFFICIEL (Emblème rond 136 px)
                      SizedBox(
                        width: 136,
                        height: 136,
                        child: CustomPaint(
                          size: const Size(136, 136),
                          painter: _AnimatedMivaEmblemPainter(
                            progress: t,
                            reduceMotion: reduceMotion,
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // Titre "MivaCouture" en Fraunces
                      Transform.translate(
                        offset: Offset(0, textSlideY),
                        child: Opacity(
                          opacity: textOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'Fraunces',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Miva',
                                      style: TextStyle(color: colors.textPrimary),
                                    ),
                                    const TextSpan(
                                      text: 'Couture',
                                      style: TextStyle(color: Pal.terreRouge),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 7),

                              // Devise officielle "Ton atelier dans ta poche"
                              Text(
                                'Ton atelier dans ta poche',
                                style: TextStyle(
                                  fontFamily: 'Public Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textSecondary,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Peintre du fond avec lignes diagonales pointillées à 45°
class _StitchedDiagonalBackgroundPainter extends CustomPainter {
  final Color lineColor;
  const _StitchedDiagonalBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;

    const step = 24.0;
    final total = size.width + size.height;

    for (double i = -size.height; i < total; i += step) {
      double startX = i;
      double startY = 0;

      const dashWidth = 2.5;
      const dashSpace = 3.8;
      double curX = startX;
      double curY = startY;

      while (curY < size.height && curX < size.width + size.height) {
        canvas.drawLine(
          Offset(curX, curY),
          Offset(curX + dashWidth * 0.707, curY + dashWidth * 0.707),
          paint,
        );
        curX += (dashWidth + dashSpace) * 0.707;
        curY += (dashWidth + dashSpace) * 0.707;
      }
    }
  }

  @override
  bool shouldRepaint(_StitchedDiagonalBackgroundPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

/// Peintre vectoriel 60 FPS fidèle aux keyframes de `logo_anime_emblem.svg`
class _AnimatedMivaEmblemPainter extends CustomPainter {
  final double progress; // 0.0 à 1.0
  final bool reduceMotion;

  const _AnimatedMivaEmblemPainter({
    required this.progress,
    required this.reduceMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Normalisation de l'espace de dessin 200x200 du SVG vers la taille réelle
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale, scale);

    const center = Offset(100, 100);

    // -------------------------------------------------------------
    // 1) Disque principal terre bogolan (0.00s à 0.20s -> Interval 0.00 to 0.20)
    // -------------------------------------------------------------
    final discT = reduceMotion
        ? 1.0
        : Curves.easeOutBack.transform((progress / 0.20).clamp(0.0, 1.0));
    final discPaint = Paint()
      ..color = Pal.terreBogolan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 96.0 * discT, discPaint);

    if (discT < 0.2) {
      canvas.restore();
      return;
    }

    // -------------------------------------------------------------
    // 2) Anneau doré extérieur en pointillés fins (fade 0.10 à 0.26)
    // -------------------------------------------------------------
    final outerRingT = reduceMotion
        ? 1.0
        : ((progress - 0.10) / 0.16).clamp(0.0, 1.0);
    if (outerRingT > 0) {
      final ringPaint = Paint()
        ..color = Pal.ocre.withAlpha((255 * outerRingT).toInt())
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      const totalDashes = 72;
      const stepArc = (2 * math.pi) / totalDashes;
      for (int i = 0; i < totalDashes; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 88),
          i * stepArc,
          stepArc * 0.45,
          false,
          ringPaint,
        );
      }
    }

    // -------------------------------------------------------------
    // 3) 16 losanges crème et 16 perles dorées en cascade circulaire
    //    (0.12s à 0.38s avec décalage de 0.015s par pétale)
    // -------------------------------------------------------------
    const int petalCount = 16;
    final petalPaint = Paint()
      ..color = Pal.cremeCoton
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()
      ..color = Pal.ocre
      ..style = PaintingStyle.fill;

    for (int i = 0; i < petalCount; i++) {
      final petalStart = 0.12 + (i * 0.012);
      final petalLocalT = reduceMotion
          ? 1.0
          : Curves.easeOutBack.transform(
              ((progress - petalStart) / 0.12).clamp(0.0, 1.0),
            );

      if (petalLocalT > 0) {
        final angle = (i * 2 * math.pi) / petalCount - (math.pi / 2);

        // Losange
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle + (math.pi / 2));
        canvas.scale(petalLocalT, petalLocalT);

        // Sommets du losange (centré en Y=-76)
        final diamondPath = Path()
          ..moveTo(0, -89) // haut
          ..lineTo(6.5, -76) // droite
          ..lineTo(0, -63) // bas
          ..lineTo(-6.5, -76) // gauche
          ..close();
        canvas.drawPath(diamondPath, petalPaint);
        canvas.restore();
      }

      // Perle dorée intercalée
      final dotStart = 0.15 + (i * 0.012);
      final dotLocalT = reduceMotion
          ? 1.0
          : Curves.easeOutBack.transform(
              ((progress - dotStart) / 0.10).clamp(0.0, 1.0),
            );

      if (dotLocalT > 0) {
        final dotAngle = ((i + 0.5) * 2 * math.pi) / petalCount - (math.pi / 2);
        final dotPos = Offset(
          center.dx + 76 * math.cos(dotAngle),
          center.dy + 76 * math.sin(dotAngle),
        );
        canvas.drawCircle(dotPos, 2.4 * dotLocalT, dotPaint);
      }
    }

    // -------------------------------------------------------------
    // 4) Cercle d'or tracé à 360° (0.32s à 0.50s)
    // -------------------------------------------------------------
    final goldRingT = reduceMotion
        ? 1.0
        : Curves.easeInOut.transform(((progress - 0.32) / 0.18).clamp(0.0, 1.0));
    if (goldRingT > 0) {
      final ringPaint = Paint()
        ..color = Pal.ocre
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 56),
        -math.pi / 2,
        2 * math.pi * goldRingT,
        false,
        ringPaint,
      );
    }

    // -------------------------------------------------------------
    // 5) Disque intérieur brun nuit (0.38s à 0.52s)
    // -------------------------------------------------------------
    final innerDiscT = reduceMotion
        ? 1.0
        : Curves.easeOutCubic.transform(((progress - 0.38) / 0.14).clamp(0.0, 1.0));
    if (innerDiscT > 0) {
      final innerPaint = Paint()
        ..color = Pal.brunNuit
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 46.0 * innerDiscT, innerPaint);
    }

    // -------------------------------------------------------------
    // 6) Cercle pointillé intérieur façon surpiqûre (0.42s à 0.58s)
    // -------------------------------------------------------------
    final innerStitchT = reduceMotion
        ? 1.0
        : ((progress - 0.42) / 0.16).clamp(0.0, 1.0);
    if (innerStitchT > 0) {
      final stitchPaint = Paint()
        ..color = Pal.cremeCoton.withAlpha((255 * innerStitchT).toInt())
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;

      const totalStitches = 32;
      const stitchStep = (2 * math.pi) / totalStitches;
      for (int i = 0; i < totalStitches; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: 50.5),
          i * stitchStep,
          stitchStep * 0.5,
          false,
          stitchPaint,
        );
      }
    }

    // -------------------------------------------------------------
    // 7) Aiguille de tailleur qui descend du haut (0.48s à 0.68s)
    // -------------------------------------------------------------
    final needleT = reduceMotion
        ? 1.0
        : Curves.bounceOut.transform(((progress - 0.48) / 0.20).clamp(0.0, 1.0));
    if (needleT > 0) {
      final needleOffsetY = (1.0 - needleT) * -38.0;

      canvas.save();
      canvas.translate(0, needleOffsetY);

      // Corps de l'aiguille crème coton
      final needlePath = Path()
        ..moveTo(96.8, 60)
        ..lineTo(103.2, 60)
        ..lineTo(103.2, 130)
        ..lineTo(100.0, 146) // pointe effilée
        ..lineTo(96.8, 130)
        ..close();

      final needlePaint = Paint()
        ..color = Pal.cremeCoton
        ..style = PaintingStyle.fill;
      canvas.drawPath(needlePath, needlePaint);

      // Chas de l'aiguille (ovale brun nuit)
      final eyePaint = Paint()
        ..color = Pal.brunNuit
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(100, 70), width: 5.2, height: 10.8),
        eyePaint,
      );

      canvas.restore();
    }

    // -------------------------------------------------------------
    // 8) Fil d'or cousu en courbe S à travers l'aiguille (0.62s à 0.85s)
    // -------------------------------------------------------------
    final threadT = reduceMotion
        ? 1.0
        : Curves.easeInOutCubic.transform(((progress - 0.62) / 0.23).clamp(0.0, 1.0));
    if (threadT > 0) {
      // Courbe S officielle du fil d'or Miva Couture
      final fullPath = Path()
        ..moveTo(100, 70)
        ..cubicTo(72, 78, 132, 98, 88, 120)
        ..cubicTo(80, 124, 74, 120, 76, 114);

      // Tracé partiel selon le progrès
      final pathMetrics = fullPath.computeMetrics();
      for (final metric in pathMetrics) {
        final extract = metric.extractPath(0.0, metric.length * threadT);
        final threadPaint = Paint()
          ..color = Pal.ocre
          ..strokeWidth = 3.2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        canvas.drawPath(extract, threadPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnimatedMivaEmblemPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.reduceMotion != reduceMotion;
}
