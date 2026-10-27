import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'theme.dart';

// =============================================================================
// DIRECTIVE DE MOTION DESIGN — CONSTANTES & TIMINGS (millisecondes exactes)
// =============================================================================

class MotionDurations {
  static const pageIn = Duration(milliseconds: 400);
  static const pageOut = Duration(milliseconds: 350);
  static const textAppear = Duration(milliseconds: 280);
  static const cardAppear = Duration(milliseconds: 350);
  static const staggerStep = Duration(milliseconds: 90);
  static const skeleton = Duration(milliseconds: 200);
  static const sheetRise = Duration(milliseconds: 400);
  static const heroImage = Duration(milliseconds: 400);
  static const circularScale = Duration(milliseconds: 500);
  static const pulse = Duration(milliseconds: 800);
}

class MotionCurves {
  static const page = Curves.easeInOut;
  static const text = Curves.easeOut;
  static const card = Curves.easeOutCubic;
  static const sheet = Curves.easeOutCubic;
  static const hero = Curves.easeOutCubic;
  static const circle = Curves.easeOutCubic;
  static const pulse = Curves.easeInOut;
}

// =============================================================================
// RÈGLE N°1 — TRANSITIONS DE PAGE (Fondu aller 400ms, retour 350ms, easeInOut)
// =============================================================================

class FadePageRoute<T> extends PageRouteBuilder<T> {
  FadePageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionDuration: MotionDurations.pageIn,
          reverseTransitionDuration: MotionDurations.pageOut,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: MotionCurves.page,
              reverseCurve: MotionCurves.page,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        );
}

class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: MotionCurves.page,
      reverseCurve: MotionCurves.page,
    );
    return FadeTransition(opacity: curved, child: child);
  }
}

// =============================================================================
// RÈGLE N°2 & N°3 — APPARITION ET CASCADE (STAGGER)
// =============================================================================

/// Apparition d'un élément avec fondu et translation Y.
/// Respecte les durées de 250-300 ms (texte/bouton) et 300-400 ms (image/carte).
class StaggeredFadeIn extends StatefulWidget {
  const StaggeredFadeIn({
    super.key,
    required this.index,
    required this.child,
    this.isCard = false,
    this.translateY = 12.0,
    this.baseDelay = Duration.zero,
    this.stepDelay = MotionDurations.staggerStep,
    this.duration,
  });

  final int index;
  final Widget child;
  final bool isCard;
  final double translateY;
  final Duration baseDelay;
  final Duration stepDelay;
  final Duration? duration;

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translate;
  Timer? _timer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    final animDuration = widget.duration ??
        (widget.isCard ? MotionDurations.cardAppear : MotionDurations.textAppear);
    final animCurve = widget.isCard ? MotionCurves.card : MotionCurves.text;

    _controller = AnimationController(vsync: this, duration: animDuration);
    _opacity = CurvedAnimation(parent: _controller, curve: animCurve);
    _translate = Tween<double>(begin: widget.translateY, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: animCurve),
    );

    final totalDelay = widget.baseDelay + (widget.stepDelay * widget.index);
    if (totalDelay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(totalDelay, () {
        if (!_disposed && mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translate.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Permet d'envelopper une liste d'enfants avec un décalage en cascade automatique.
class StaggerColumn extends StatelessWidget {
  const StaggerColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
    this.baseDelay = Duration.zero,
  });

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Duration baseDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++)
          StaggeredFadeIn(
            index: i,
            baseDelay: baseDelay,
            child: children[i],
          ),
      ],
    );
  }
}

// =============================================================================
// RÈGLE N°4 — CHARGEMENT EN DEUX TEMPS (SKELETON)
// =============================================================================

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 18,
    this.radius = 12,
    this.color,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Pal.line.withAlpha(160),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key, this.height = 78, this.radius = 24});
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Pal.line.withAlpha(120)),
      ),
      child: Row(
        children: [
          SkeletonBox(width: 54, height: 54, radius: 16, color: Pal.chalk),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SkeletonBox(width: 60, height: 24, radius: 12),
        ],
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.padding = const EdgeInsets.fromLTRB(16, 6, 16, 32)});
  final int count;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: padding,
      children: [
        for (var i = 0; i < count; i++) const SkeletonTile(),
      ],
    );
  }
}

class TwoPhaseLoader extends StatefulWidget {
  const TwoPhaseLoader({
    super.key,
    required this.child,
    this.skeleton,
    this.duration = MotionDurations.skeleton,
  });

  final Widget child;
  final Widget? skeleton;
  final Duration duration;

  @override
  State<TwoPhaseLoader> createState() => _TwoPhaseLoaderState();
}

class _TwoPhaseLoaderState extends State<TwoPhaseLoader> {
  bool _loaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionDurations.cardAppear,
      switchInCurve: MotionCurves.card,
      switchOutCurve: MotionCurves.card,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: _loaded
          ? KeyedSubtree(key: const ValueKey('loaded'), child: widget.child)
          : KeyedSubtree(
              key: const ValueKey('skeleton'),
              child: widget.skeleton ?? const SkeletonList(),
            ),
    );
  }
}

// =============================================================================
// RÈGLE N°5 — PANNEAUX ET FEUILLES (BOTTOM SHEETS)
// =============================================================================

Future<T?> showMotionBottomSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  Color? backgroundColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: backgroundColor ?? Colors.white,
    sheetAnimationStyle: AnimationStyle(
      duration: MotionDurations.sheetRise,
      reverseDuration: MotionDurations.pageOut,
      curve: MotionCurves.sheet,
      reverseCurve: Curves.easeInOut,
    ),
    builder: (ctx) => MotionSheetWrapper(child: builder(ctx)),
  );
}

class MotionSheetWrapper extends StatelessWidget {
  const MotionSheetWrapper({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Les éléments internes se cascadent juste quand le panneau est déployé
    return StaggeredFadeIn(
      index: 0,
      baseDelay: const Duration(milliseconds: 180),
      duration: MotionDurations.cardAppear,
      translateY: 10,
      child: child,
    );
  }
}

// =============================================================================
// RÈGLE N°6 — IMAGES EN VEDETTE (Hero image flou 10 -> 0 + scale 0.2 -> 1)
// =============================================================================

class FeaturedHeroImage extends StatelessWidget {
  const FeaturedHeroImage({
    super.key,
    required this.child,
    this.duration = MotionDurations.heroImage,
    this.curve = MotionCurves.hero,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, staticChild) {
        final scale = 0.2 + (0.8 * value);
        final sigma = (1.0 - value) * 10.0;
        final opacity = value.clamp(0.0, 1.0);

        Widget content = Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: staticChild),
        );

        if (sigma > 0.05) {
          content = ImageFilterWidget(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: content,
          );
        }
        return content;
      },
      child: child,
    );
  }
}

class ImageFilterWidget extends StatelessWidget {
  const ImageFilterWidget({super.key, required this.filter, required this.child});
  final ImageFilter filter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(imageFilter: filter, child: child);
  }
}

// =============================================================================
// RÈGLE N°7 — ÉLÉMENTS GRAPHIQUES CIRCULAIRES (Avatar / Logo scale 0 -> 1)
// =============================================================================

class MotionCircularScale extends StatelessWidget {
  const MotionCircularScale({
    super.key,
    required this.child,
    this.duration = MotionDurations.circularScale,
    this.curve = MotionCurves.circle,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, staticChild) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: staticChild),
        );
      },
      child: child,
    );
  }
}

// =============================================================================
// RÈGLE N°8 — PULSATION & TIMELINE DES ÉTAPES
// =============================================================================

/// Indicateur circulaire qui pulse doucement en boucle :
/// opacity 0.3 <-> 1.0, durée 800 ms, courbe easeInOut aller-retour.
class PulsingIndicator extends StatefulWidget {
  const PulsingIndicator({
    super.key,
    this.size = 10,
    this.color = Pal.cobalt,
    this.glow = true,
  });

  final double size;
  final Color color;
  final bool glow;

  @override
  State<PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<PulsingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: MotionDurations.pulse)
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.pulse),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              boxShadow: widget.glow
                  ? [
                      BoxShadow(
                        color: widget.color.withAlpha((140 * _animation.value).toInt()),
                        blurRadius: 6,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// Suite d'étapes verticale (timeline de statut) conforme à la Règle N°8 :
/// - Chaque étape (cercle + texte) apparaît en cascade (Règle N°3).
/// - L'étape active porte un indicateur qui pulse doucement (800ms aller-retour).
class VerticalProgressTimeline<T> extends StatelessWidget {
  const VerticalProgressTimeline({
    super.key,
    required this.steps,
    required this.currentStep,
    required this.labelBuilder,
    this.onSelect,
  });

  final List<T> steps;
  final T currentStep;
  final String Function(T) labelBuilder;
  final ValueChanged<T>? onSelect;

  @override
  Widget build(BuildContext context) {
    final currentIndex = steps.indexOf(currentStep);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          StaggeredFadeIn(
            index: i,
            isCard: false,
            translateY: 8,
            child: _TimelineRow(
              index: i,
              isFirst: i == 0,
              isLast: i == steps.length - 1,
              isDone: i < currentIndex,
              isActive: i == currentIndex,
              label: labelBuilder(steps[i]),
              onTap: onSelect != null ? () => onSelect!(steps[i]) : null,
            ),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.isDone,
    required this.isActive,
    required this.label,
    this.onTap,
  });

  final int index;
  final bool isFirst, isLast, isDone, isActive;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: isActive
                    ? const PulsingIndicator(size: 14, color: Pal.cobalt)
                    : isDone
                        ? Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Pal.sage),
                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                          )
                        : Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Pal.slate.withAlpha(120), width: 2),
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w800 : (isDone ? FontWeight.w600 : FontWeight.w500),
                  color: isActive ? Pal.cobalt : (isDone ? Pal.ink : Pal.slate),
                  fontSize: 14.5,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Pal.cobalt.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'En cours',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Pal.cobalt),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
