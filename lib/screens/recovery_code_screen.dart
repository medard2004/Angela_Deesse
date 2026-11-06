import 'dart:async';
import 'package:flutter/services.dart';
import '../shell/app_shell.dart';
import '../ui.dart';

/// Écran affichant le code de récupération à 12 caractères généré lors de la création du PIN.
/// Ce code est affiché une seule fois et permet de déverrouiller l'app en cas d'oubli.
class RecoveryCodeScreen extends StatefulWidget {
  final String recoveryCode;
  final bool isRoot;

  const RecoveryCodeScreen({
    super.key,
    required this.recoveryCode,
    this.isRoot = false,
  });

  @override
  State<RecoveryCodeScreen> createState() => _RecoveryCodeScreenState();
}

class _RecoveryCodeScreenState extends State<RecoveryCodeScreen> {
  Timer? _clipboardClearTimer;

  @override
  void dispose() {
    _clipboardClearTimer?.cancel();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.recoveryCode));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié. Il sera effacé du presse-papiers dans 60 secondes.'),
        duration: Duration(seconds: 4),
      ),
    );

    _clipboardClearTimer?.cancel();
    _clipboardClearTimer = Timer(const Duration(seconds: 60), () async {
      if (!mounted) return;
      try {
        final currentData = await Clipboard.getData(Clipboard.kTextPlain);
        if (currentData?.text == widget.recoveryCode) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {}
    });
  }

  void _onDone(BuildContext context) {
    if (widget.isRoot) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isRoot,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Pal.chalk,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      size: 44,
                      color: Pal.cobalt,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Code de récupération',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Conservez précieusement ce code en lieu sûr.\n'
                  'Il est affiché une seule fois et sera le seul moyen de récupérer l\'accès si vous oubliez votre code d\'accès.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Pal.slate,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: SelectableText(
                      widget.recoveryCode,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: Pal.cobalt,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy_rounded, size: 18, color: Pal.cobalt),
                      label: const Text(
                        'Copier le code',
                        style: TextStyle(
                          color: Pal.cobalt,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        side: const BorderSide(color: Pal.line),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _onDone(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.cobalt,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "J'ai bien noté mon code",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
