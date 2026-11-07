import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_brand.dart';
import '../core/theme.dart';
import '../data/services/photo_storage.dart';
import '../data/services/pin_security_service.dart';
import '../data/store.dart';
import '../shell/app_shell.dart';
import '../widgets/common.dart';
import 'lock_screen.dart';
import 'security_error_screen.dart';

/// Écran de splash épuré au lancement, sans page d'introduction ni bouton :
/// - De 0 à 450 ms : apparition au centre avec fondu et zoom progressif (~55% à taille normale).
/// - De 450 à 650 ms : maintien en place au centre.
/// - De 650 à 1 250 ms : déplacement fluide vers le centre de la barre supérieure en réduisant
///   progressivement la taille jusqu'à l'en-tête (22 px).
/// - De 950 à 1 250 ms (~300 ms) : effacement du splash et apparition en fondu du contenu principal.
/// - Durée totale : environ 1,4 seconde (1 400 ms).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _entryFade;
  late final Animation<double> _entryZoom;
  late final Animation<double> _flightAnimation;
  late final Animation<double> _contentFadeAnimation;

  Future<void>? _initFuture;
  String? _initError;

  @override
  void initState() {
    super.initState();

    // Durée totale : 2,2 secondes (2 200 ms) pour une animation ralentie et plus majestueuse
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // De 0 à 550 ms : fondu d'apparition (0 -> 1) et zoom progressif (55% -> 100%)
    _entryFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0 / 2200, 550.0 / 2200, curve: Curves.easeOut),
      ),
    );

    _entryZoom = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0 / 2200, 550.0 / 2200, curve: Curves.easeOutCubic),
      ),
    );

    // De 550 à 850 ms : maintien en place au centre (pause de 300 ms)

    // De 850 à 1 900 ms (durée de 1 050 ms) : déplacement fluide, ralenti et élégant vers le centre de la barre supérieure
    _flightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(850.0 / 2200, 1900.0 / 2200, curve: Curves.easeInOutCubic),
      ),
    );

    // De 1 450 à 1 950 ms (500 ms) : fondu d'apparition doux de l'accueil et effacement du splash
    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(1450.0 / 2200, 1950.0 / 2200, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;
        if (_initFuture != null) {
          try {
            await _initFuture;
          } catch (e) {
            _initError = e.toString();
          }
        }
        if (!mounted) return;
        if (_initError != null) {
          setState(() {});
          return;
        }

        // Récupération des photos perdues suite à destruction d'activité Android (avant le verrou)
        try {
          final photoStorage = context.read<PhotoStorage>();
          await photoStorage.retrieveLostData();
        } catch (_) {}

        if (!mounted) return;
        await _checkPinAndNavigate();
      }
    });

    // Démarrage automatique dès le lancement
    _controller.forward();
  }

  Future<void> _checkPinAndNavigate() async {
    PinSecurityService? pinService;
    try {
      pinService = context.read<PinSecurityService>();
    } catch (_) {}

    if (pinService == null) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AppShell(),
          transitionDuration: Duration.zero,
        ),
      );
      return;
    }

    final pinStatus = await pinService.getPinStatus();
    if (!mounted) return;

    if (pinStatus.status == PinStatus.storageError) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SecurityErrorScreen(
            error: pinStatus.error,
            onRetry: () => _checkPinAndNavigate(),
          ),
        ),
      );
    } else if (pinStatus.status == PinStatus.unconfigured) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LockScreen(
            mode: LockMode.create,
            isRoot: true,
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const LockScreen(
            mode: LockMode.unlock,
            isRoot: true,
          ),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initFuture ??= context.read<AppStore>().init().catchError((Object err) {
      _initError = err.toString();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        backgroundColor: Pal.chalk,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Pal.thread),
                const SizedBox(height: 16),
                const Text(
                  "Impossible d'ouvrir la base de données",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Pal.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Pal.slate),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _initError = null;
                      _initFuture = context.read<AppStore>().init().catchError((Object e) {
                        setState(() => _initError = e.toString());
                      });
                    });
                  },
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    final centerY = screenHeight / 2;
    final centerX = screenWidth / 2;

    // Position finale calculée dynamiquement selon la barre supérieure et la largeur de l'écran
    final targetOffset = computeAppBarLogoCenter(context, label: AppBrand.appName);
    final targetX = targetOffset.dx;
    final targetY = targetOffset.dy;

    return Scaffold(
      backgroundColor: Pal.chalk,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final entryFade = _entryFade.value;
          final entryZoom = _entryZoom.value;
          final flight = _flightAnimation.value;
          final contentFade = _contentFadeAnimation.value;

          // Position continue du logo pendant le vol
          final curX = centerX + (targetX - centerX) * flight;
          final curY = centerY + (targetY - centerY) * flight;

          // Tailles : de 55% à 100% à l'entrée, puis rétrécissement vers 22 px pendant le vol
          final basePastilleSize = 86.0 * (flight > 0 ? 1.0 : entryZoom);
          final baseLogoSize = 42.0 * (flight > 0 ? 1.0 : entryZoom);

          final curPastilleSize = flight > 0 ? (86.0 - (86.0 - 22.0) * flight) : basePastilleSize;
          final curLogoSize = flight > 0 ? (42.0 - (42.0 - 22.0) * flight) : baseLogoSize;

          // Atténuation du halo et contour
          final haloOpacity = flight > 0 ? (1.0 - flight).clamp(0.0, 1.0) : entryFade;
          final bgOpacity = flight > 0 ? (1.0 - flight).clamp(0.0, 1.0) : entryFade;
          final logoOpacity = flight > 0 ? 1.0 : entryFade;

          return Stack(
            children: [
              // Contenu principal qui apparaît en fondu pendant le déplacement (sur ~300 ms)
              if (contentFade > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: SplashScope(
                      showLogo: flight >= 0.98,
                      child: Opacity(
                        opacity: contentFade,
                        child: const AppShell(),
                      ),
                    ),
                  ),
                ),

              // Fond épuré du splash qui s'efface
              if (contentFade < 1.0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: (1.0 - contentFade).clamp(0.0, 1.0),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -100,
                            right: -100,
                            child: Container(
                              width: 380,
                              height: 380,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0x40A9C2F5), Color(0x00A9C2F5)],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: -80,
                            left: -80,
                            child: Container(
                              width: 340,
                              height: 340,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0x25FF8A1F), Color(0x00FF8A1F)],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Logo voyageant continûment vers sa place dans l'en-tête
              if (entryFade > 0)
                Positioned(
                  left: curX - (curPastilleSize / 2),
                  top: curY - (curPastilleSize / 2),
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: logoOpacity,
                      child: Container(
                        width: curPastilleSize,
                        height: curPastilleSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha((255 * bgOpacity).toInt()),
                          border: haloOpacity > 0.05
                              ? Border.all(
                                  color: Pal.cobalt.withAlpha((40 * haloOpacity).toInt()),
                                  width: 1.5,
                                )
                              : null,
                          boxShadow: haloOpacity > 0.05
                              ? [
                                  BoxShadow(
                                    color: Pal.cobalt.withAlpha((50 * haloOpacity).toInt()),
                                    blurRadius: 36 * haloOpacity,
                                    spreadRadius: 2 * haloOpacity,
                                    offset: Offset(0, 10 * haloOpacity),
                                  ),
                                ]
                              : null,
                        ),
                        child: Image.asset(
                          'assets/images/logo_mark.png',
                          width: curLogoSize,
                          height: curLogoSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
