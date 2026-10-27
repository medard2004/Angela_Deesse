import 'dart:async';
import 'package:flutter/services.dart';
import '../ui.dart';

/// Aperçu de l'écran de verrouillage (maquette) : n'importe quel code à 4 chiffres l'ouvre.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _entry = '';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _digit(String d) {
    if (_entry.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() => _entry += d);
    if (_entry.length == 4) {
      _timer = Timer(const Duration(milliseconds: 220), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: Pal.cobaltGradient),
          child: SafeArea(
            child: Column(children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: "Fermer l'aperçu",
                ),
              ),
              const Spacer(),
              MotionCircularScale(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                  child: Image.asset('assets/images/logo_full.png', height: 44),
                ),
              ),
              const SizedBox(height: 32),
              const StaggeredFadeIn(
                index: 1,
                child: Text('Entrez votre code', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.5)),
              ),
              const SizedBox(height: 22),
              StaggeredFadeIn(
                index: 2,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < 4; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 16, height: 16, margin: const EdgeInsets.symmetric(horizontal: 9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _entry.length ? Pal.orange : Colors.transparent,
                        border: Border.all(color: i < _entry.length ? Pal.orange : Colors.white54, width: 1.8),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 28),
              for (var r = 0; r < 3; r++)
                StaggeredFadeIn(
                  index: 3 + r,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (final d in const [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']][r])
                      _Key(d, () => _digit(d)),
                  ]),
                ),
              StaggeredFadeIn(
                index: 6,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 96, height: 78),
                  _Key('0', () => _digit('0')),
                  SizedBox(
                    width: 96, height: 78,
                    child: IconButton(
                      onPressed: () => setState(() {
                        if (_entry.isNotEmpty) _entry = _entry.substring(0, _entry.length - 1);
                      }),
                      icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
                    ),
                  ),
                ]),
              ),
              const Spacer(),
            ]),
          ),
        ),
      );
}

class _Key extends StatelessWidget {
  const _Key(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 96, height: 78,
        child: Center(
          child: Material(
            color: Colors.white.withAlpha(30),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 64, height: 64,
                child: Center(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600))),
              ),
            ),
          ),
        ),
      );
}
