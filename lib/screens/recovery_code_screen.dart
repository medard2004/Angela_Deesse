import 'package:flutter/services.dart';
import '../shell/app_shell.dart';
import '../ui.dart';

/// Écran affichant le code de récupération à 12 caractères généré lors de la création du PIN.
/// Ce code est affiché une seule fois et permet de déverrouiller l'app en cas d'oubli.
class RecoveryCodeScreen extends StatelessWidget {
  final String recoveryCode;
  final bool isRoot;

  const RecoveryCodeScreen({
    super.key,
    required this.recoveryCode,
    this.isRoot = false,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: recoveryCode));
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code de récupération copié dans le presse-papier'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onDone(BuildContext context) {
    if (isRoot) {
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
      canPop: !isRoot,
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
                      recoveryCode,
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
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () => _copyToClipboard(context),
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Pal.cobalt),
                    label: const Text(
                      'Copier le code',
                      style: TextStyle(
                        color: Pal.cobalt,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
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
