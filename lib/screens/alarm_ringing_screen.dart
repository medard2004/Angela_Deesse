import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/services/system_reminder_service.dart';
import '../ui.dart';

/// Écran d'alarme plein écran façon réveil de téléphone (Full-Screen Alarm).
/// Sonne et vibre en boucle, réveille le téléphone écran éteint ou s'affiche
/// par-dessus l'application si l'artisan est déjà dedans.
class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({
    super.key,
    required this.title,
    required this.body,
    this.notificationId,
    this.alertKeys = const [],
    this.timeoutSeconds = 60,
    this.onDismiss,
    this.onSnooze,
  });

  final String title;
  final String body;
  final int? notificationId;
  final List<String> alertKeys;
  final int timeoutSeconds;
  final VoidCallback? onDismiss;
  final VoidCallback? onSnooze;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  Timer? _countdownTimer;
  Timer? _vibrationTimer;
  late int _remainingSeconds;
  late String _currentTime;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    _currentTime = DateFormat('HH:mm').format(DateTime.now());

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Mise à jour de l'horloge
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateFormat('HH:mm').format(DateTime.now());
        });
      }
    });

    // Vibration continue
    _startVibrationLoop();

    // Minuterie d'extinction automatique (1 minute / 60s)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _handleStop(timeout: true);
      } else {
        if (mounted) {
          setState(() => _remainingSeconds--);
        }
      }
    });
  }

  void _startVibrationLoop() {
    // Vibration tactile périodique
    HapticFeedback.vibrate();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      HapticFeedback.vibrate();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _countdownTimer?.cancel();
    _vibrationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleStop({bool timeout = false}) async {
    _vibrationTimer?.cancel();
    if (widget.notificationId != null) {
      final reminderService = context.read<SystemReminderService?>();
      if (reminderService != null) {
        await reminderService.plugin.cancel(id: widget.notificationId!);
      }
    }
    widget.onDismiss?.call();
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Future<void> _handleSnooze() async {
    _vibrationTimer?.cancel();
    final reminderService = context.read<SystemReminderService?>();
    if (widget.notificationId != null && reminderService != null) {
      await reminderService.plugin.cancel(id: widget.notificationId!);
      await reminderService.scheduleRingerTest(
        delay: const Duration(minutes: 10),
      );
    }
    widget.onSnooze?.call();
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF071228),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Badge d'alerte urgent
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Pal.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Pal.orange.withValues(alpha: 0.6)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.alarm_rounded, color: Pal.orange, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'RAPPEL D\'ATELIER EN DIRECT',
                        style: TextStyle(
                          color: Pal.orange,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Horloge géante
                Text(
                  _currentTime,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 72,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),

                // Icône cloche pulsante
                ScaleTransition(
                  scale: _pulseScale,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Pal.cobalt.withValues(alpha: 0.3),
                      border: Border.all(color: Pal.cobalt, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Pal.cobalt.withValues(alpha: 0.5),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_active_rounded,
                      size: 54,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Titre et détails de l'événement
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Text(
                        widget.body,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Compte à rebours
                Text(
                  'Arrêt automatique dans ${_remainingSeconds}s',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Boutons d'action géants
                Row(
                  children: [
                    // Bouton Reporter
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton.icon(
                          onPressed: _handleSnooze,
                          icon: const Icon(Icons.snooze_rounded, color: Colors.white, size: 20),
                          label: const Text(
                            'Reporter 10m',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Bouton Arrêter
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: () => _handleStop(timeout: false),
                          icon: const Icon(Icons.stop_circle_outlined, size: 22),
                          label: const Text(
                            'ARRÊTER',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: Pal.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

