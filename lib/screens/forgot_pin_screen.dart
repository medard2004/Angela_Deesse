import 'dart:async';

import '../data/services/pin_security_service.dart';
import '../ui.dart';
import 'lock_screen.dart';

/// Écran de récupération du code PIN oublié via le code de récupération à 12 caractères.
class ForgotPinScreen extends StatefulWidget {
  final bool isRoot;

  const ForgotPinScreen({super.key, this.isRoot = false});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  final _controller = TextEditingController();
  Timer? _countdownTimer;
  Duration? _lockoutRemaining;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLockout();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLockout() async {
    final pinService = context.read<PinSecurityService>();
    final remaining = await pinService.getLockoutRemaining();
    if (!mounted) return;
    if (remaining != null && remaining > Duration.zero) {
      _startCountdown(remaining);
    } else {
      setState(() {
        _lockoutRemaining = null;
      });
    }
  }

  void _startCountdown(Duration duration) {
    _countdownTimer?.cancel();
    setState(() {
      _lockoutRemaining = duration;
      _errorMessage = null;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final newSeconds = (_lockoutRemaining?.inSeconds ?? 0) - 1;
      if (newSeconds <= 0) {
        timer.cancel();
        setState(() {
          _lockoutRemaining = null;
        });
      } else {
        setState(() {
          _lockoutRemaining = Duration(seconds: newSeconds);
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final s = duration.inSeconds;
    if (s < 60) return '$s s';
    final m = duration.inMinutes;
    final remS = s % 60;
    return remS > 0 ? '$m min $remS s' : '$m min';
  }

  Future<void> _submit() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _errorMessage = 'Veuillez saisir le code de récupération');
      return;
    }

    final pinService = context.read<PinSecurityService>();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await pinService.verifyRecoveryCode(raw);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result.isLocked) {
      _startCountdown(result.lockoutRemaining ?? const Duration(seconds: 30));
    } else if (result.isSuccess) {
      // Rediriger vers la création d'un nouveau PIN
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LockScreen(
            mode: LockMode.create,
            isRoot: widget.isRoot,
            isResetAfterForgot: true,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Code de récupération incorrect';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _lockoutRemaining != null && _lockoutRemaining! > Duration.zero;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Pal.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Code d\'accès oublié',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: Pal.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre code de récupération à 12 caractères pour réinitialiser votre code PIN.',
                style: TextStyle(fontSize: 13.5, color: Pal.slate, height: 1.45),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                enabled: !isLocked && !_isLoading,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  fontFamily: 'monospace',
                  color: Pal.cobalt,
                ),
                decoration: InputDecoration(
                  labelText: 'Code de récupération',
                  hintText: 'XXXX-XXXX-XXXX',
                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: Pal.slate),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Pal.cobalt, width: 2),
                  ),
                ),
                onSubmitted: (_) => isLocked || _isLoading ? null : _submit(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (isLocked) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock_rounded, color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Trop de tentatives. Réessayez dans ${_formatDuration(_lockoutRemaining!)}.',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: isLocked || _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Pal.cobalt,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Valider et réinitialiser',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Si vous ne disposez pas de votre code de récupération, veuillez contacter le support de l\'atelier.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Pal.slate, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
