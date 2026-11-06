import 'package:flutter/foundation.dart';

import 'external_action_tracker.dart';
import 'pin_security_service.dart';

/// Gestionnaire de la politique de verrouillage automatique de l'application.
///
/// Règles :
/// - Verrouillé au démarrage à froid tant que le code n'a pas été validé.
/// - Verrouillé au retour d'arrière-plan si la mise en veille dépasse 2 minutes.
/// - JAMAIS verrouillé lors d'une action externe volontaire (caméra, galerie, appel, WhatsApp, SMS).
class AppLockManager {
  static const Duration backgroundLockTimeout = Duration(minutes: 2);

  final PinSecurityService _securityService;
  final ExternalActionTracker _tracker;
  final DateTime Function() _clock;

  VoidCallback? onLockRequired;

  DateTime? _pausedAt;
  bool _isLocked = true;
  bool isLockScreenShowing = false;

  AppLockManager({
    required PinSecurityService securityService,
    required ExternalActionTracker tracker,
    DateTime Function()? clock,
    this.onLockRequired,
  })  : _securityService = securityService,
        _tracker = tracker,
        _clock = clock ?? DateTime.now;

  PinSecurityService get securityService => _securityService;
  ExternalActionTracker get tracker => _tracker;

  bool get isLocked => _isLocked;

  /// Déverrouille l'application après saisie réussie du code.
  void markUnlocked() {
    _isLocked = false;
  }

  /// Verrouille explicitement l'application.
  void lock() {
    _isLocked = true;
    if (!isLockScreenShowing) {
      onLockRequired?.call();
    }
  }

  /// Appelé lorsque l'application passe en arrière-plan (paused / hidden).
  void onAppPaused() {
    if (_tracker.isActive) {
      // Une action externe est active (caméra, appel, SMS, etc.) : ne pas armer le chrono
      _pausedAt = null;
      return;
    }
    _pausedAt = _clock();
  }

  /// Appelé lorsque l'application repasse au premier plan (resumed).
  void onAppResumed() {
    if (_tracker.isActive) {
      // Retour d'une action externe : l'action s'est terminée ou est en cours, pas de verrou
      _pausedAt = null;
      return;
    }

    if (_pausedAt != null) {
      final elapsed = _clock().difference(_pausedAt!);
      _pausedAt = null;
      if (elapsed > backgroundLockTimeout) {
        lock();
      }
    }
  }
}
