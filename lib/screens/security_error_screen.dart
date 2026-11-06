import '../ui.dart';

/// Écran d'erreur fatale affiché lorsque le stockage sécurisé est inaccessible.
/// Empêche tout accès aux données de la base tant que le stockage sécurisé n'est pas rétabli.
class SecurityErrorScreen extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const SecurityErrorScreen({
    super.key,
    this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.security_update_warning_rounded,
                      size: 48,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Erreur de sécurité',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Impossible d'accéder au stockage sécurisé de cet appareil.\n"
                  "Par mesure de protection de vos données, l'accès à l'application est temporairement suspendu.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Pal.slate,
                    height: 1.45,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      error.toString(),
                      style: const TextStyle(fontSize: 11, color: Pal.slate),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const Spacer(),
                FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.cobalt,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Réessayer',
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
