import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/services/app_lock_manager.dart';
import '../data/services/pin_security_service.dart';
import '../shell/app_shell.dart';
import '../ui.dart';
import 'forgot_pin_screen.dart';
import 'recovery_code_screen.dart';

enum LockMode {
  unlock,
  create,
  change,
}

/// Écran de verrouillage / création / modification du code PIN sécurisé.
class LockScreen extends StatefulWidget {
  final LockMode mode;
  final bool isRoot;
  final bool isResetAfterForgot;

  const LockScreen({
    super.key,
    this.mode = LockMode.unlock,
    this.isRoot = false,
    this.isResetAfterForgot = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _entry = '';
  String? _firstEntry;
  String? _oldPin;
  int _step = 0;

  String? _errorMessage;
  Duration? _lockoutRemaining;
  Timer? _countdownTimer;
  bool _isVerifying = false;
  AppLockManager? _lockManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _lockManager = context.read<AppLockManager>();
      _lockManager?.isLockScreenShowing = true;
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkLockout();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _lockManager?.isLockScreenShowing = false;
    super.dispose();
  }

  Future<void> _checkLockout() async {
    final pinService = context.read<PinSecurityService>();
    final remaining = await pinService.getLockoutRemaining();
    if (!mounted) return;
    if (remaining != null && remaining > Duration.zero) {
      _startCountdown(remaining);
    }
  }

  void _startCountdown(Duration duration) {
    _countdownTimer?.cancel();
    setState(() {
      _lockoutRemaining = duration;
      _errorMessage = null;
      _entry = '';
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

  void _digit(String d) {
    if (_lockoutRemaining != null || _isVerifying) return;
    if (_entry.length >= 4) return;

    HapticFeedback.selectionClick();
    setState(() {
      _entry += d;
      _errorMessage = null;
    });

    if (_entry.length == 4) {
      _handleCompletePin(_entry);
    }
  }

  void _backspace() {
    if (_lockoutRemaining != null || _isVerifying) return;
    if (_entry.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _entry = _entry.substring(0, _entry.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleCompletePin(String pin) async {
    final pinService = context.read<PinSecurityService>();
    final lockManager = context.read<AppLockManager>();

    if (widget.mode == LockMode.unlock) {
      setState(() => _isVerifying = true);
      final result = await pinService.verifyPin(pin);
      if (!mounted) return;

      setState(() => _isVerifying = false);

      if (result.isSuccess) {
        HapticFeedback.mediumImpact();
        lockManager.markUnlocked();
        if (widget.isRoot) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AppShell()),
          );
        } else {
          Navigator.of(context).pop(true);
        }
      } else if (result.isLocked) {
        HapticFeedback.heavyImpact();
        _startCountdown(result.lockoutRemaining ?? const Duration(seconds: 30));
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _entry = '';
          _errorMessage = 'Code d\'accès incorrect';
        });
      }
    } else if (widget.mode == LockMode.create) {
      if (_step == 0) {
        if (isTrivialPin(pin)) {
          HapticFeedback.heavyImpact();
          setState(() {
            _entry = '';
            _errorMessage = 'Code trop simple, choisissez-en un autre';
          });
          return;
        }
        setState(() {
          _firstEntry = pin;
          _entry = '';
          _step = 1;
        });
      } else {
        if (pin == _firstEntry) {
          setState(() => _isVerifying = true);
          final recoveryCode = await pinService.createPin(pin);
          if (!mounted) return;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('has_skipped_pin_setup');
          } catch (_) {}
          lockManager.markUnlocked();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => RecoveryCodeScreen(
                recoveryCode: recoveryCode,
                isRoot: widget.isRoot,
              ),
            ),
          );
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _entry = '';
            _firstEntry = null;
            _step = 0;
            _errorMessage = 'Les codes ne correspondent pas. Recommencez.';
          });
        }
      }
    } else if (widget.mode == LockMode.change) {
      if (_step == 0) {
        // Vérification de l'ancien PIN
        setState(() => _isVerifying = true);
        final result = await pinService.verifyPin(pin);
        if (!mounted) return;
        setState(() => _isVerifying = false);

        if (result.isSuccess) {
          setState(() {
            _oldPin = pin;
            _entry = '';
            _step = 1;
          });
        } else if (result.isLocked) {
          _startCountdown(result.lockoutRemaining ?? const Duration(seconds: 30));
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _entry = '';
            _errorMessage = 'Ancien code incorrect';
          });
        }
      } else if (_step == 1) {
        if (isTrivialPin(pin)) {
          HapticFeedback.heavyImpact();
          setState(() {
            _entry = '';
            _errorMessage = 'Code trop simple, choisissez-en un autre';
          });
          return;
        }
        setState(() {
          _firstEntry = pin;
          _entry = '';
          _step = 2;
        });
      } else if (_step == 2) {
        if (pin == _firstEntry) {
          setState(() => _isVerifying = true);
          final res = await pinService.changePin(
            oldPin: _oldPin!,
            newPin: pin,
          );
          if (!mounted) return;
          if (res.success && res.newRecoveryCode != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => RecoveryCodeScreen(
                  recoveryCode: res.newRecoveryCode!,
                  isRoot: false,
                ),
              ),
            );
          } else {
            setState(() {
              _isVerifying = false;
              _entry = '';
              _step = 0;
              _errorMessage = res.message ?? 'Échec du changement de code';
            });
          }
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _entry = '';
            _firstEntry = null;
            _step = 1;
            _errorMessage = 'Les codes ne correspondent pas.';
          });
        }
      }
    }
  }

  String get _title {
    if (widget.mode == LockMode.unlock) {
      return 'Entrez votre code';
    } else if (widget.mode == LockMode.create) {
      return _step == 0 ? 'Créer votre code secret' : 'Confirmez votre code';
    } else {
      if (_step == 0) return 'Code secret actuel';
      if (_step == 1) return 'Nouveau code secret';
      return 'Confirmez le nouveau code';
    }
  }

  String? get _subtitle {
    if (widget.mode == LockMode.create) {
      return _step == 0
          ? 'Choisissez un code à 4 chiffres'
          : 'Saisissez à nouveau le code à 4 chiffres';
    } else if (widget.mode == LockMode.change) {
      if (_step == 0) return 'Entrez votre code actuel pour continuer';
      if (_step == 1) return 'Choisissez un nouveau code à 4 chiffres';
      return 'Saisissez à nouveau votre nouveau code';
    }
    return null;
  }

  bool get _canPop {
    if (widget.mode == LockMode.unlock) return false;
    if (widget.mode == LockMode.create) return !widget.isRoot && !widget.isResetAfterForgot;
    return true; // change mode
  }

  Future<void> _skipPinCreation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_skipped_pin_setup', true);
    } catch (_) {}

    _lockManager?.markUnlocked();
    if (!mounted) return;

    if (widget.isRoot) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } else {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _lockoutRemaining != null && _lockoutRemaining! > Duration.zero;

    return PopScope(
      canPop: _canPop,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: Pal.cobaltGradient),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (_canPop)
                                  IconButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                                    tooltip: 'Retour',
                                  )
                                else
                                  const SizedBox(width: 48, height: 48),
                                if (widget.mode == LockMode.create && widget.isRoot)
                                  TextButton.icon(
                                    onPressed: _skipPinCreation,
                                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                                    label: const Text(
                                      'Ignorer',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                else
                                  const SizedBox(width: 48, height: 48),
                              ],
                            ),
                          ),
                          const Spacer(),
                          MotionCircularScale(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Image.asset('assets/images/logo_full.png', height: 44),
                            ),
                          ),
                          const SizedBox(height: 28),
                          StaggeredFadeIn(
                            index: 1,
                            child: Text(
                              _title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          if (_subtitle != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              _subtitle!,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 20),
                          StaggeredFadeIn(
                            index: 2,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 4; i++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.symmetric(horizontal: 9),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i < _entry.length
                                          ? Pal.orange
                                          : (_errorMessage != null
                                              ? Colors.redAccent.withAlpha(100)
                                              : Colors.transparent),
                                      border: Border.all(
                                        color: i < _entry.length
                                            ? Pal.orange
                                            : (_errorMessage != null
                                                ? Colors.redAccent
                                                : Colors.white54),
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFFFB4A9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                          if (isLocked) ...[
                            const SizedBox(height: 14),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Trop de tentatives. Réessayez dans ${_formatDuration(_lockoutRemaining!)}.',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          for (var r = 0; r < 3; r++)
                            StaggeredFadeIn(
                              index: 3 + r,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final d in const [
                                    ['1', '2', '3'],
                                    ['4', '5', '6'],
                                    ['7', '8', '9']
                                  ][r])
                                    _Key(d, isLocked ? () {} : () => _digit(d)),
                                ],
                              ),
                            ),
                          StaggeredFadeIn(
                            index: 6,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 96, height: 78),
                                _Key('0', isLocked ? () {} : () => _digit('0')),
                                SizedBox(
                                  width: 96,
                                  height: 78,
                                  child: IconButton(
                                    onPressed: isLocked ? null : _backspace,
                                    icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.mode == LockMode.unlock) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ForgotPinScreen(isRoot: widget.isRoot),
                                  ),
                                );
                              },
                              child: const Text(
                                'Code d\'accès oublié ?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                          if (widget.mode == LockMode.create && widget.isRoot) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _skipPinCreation,
                              child: const Text(
                                'Définir plus tard dans les paramètres',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 96,
        height: 78,
        child: Center(
          child: Material(
            color: Colors.white.withAlpha(30),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
