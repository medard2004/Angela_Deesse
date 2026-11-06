import 'dart:async';

/// Suivi des actions externes volontaires (appareil photo, galerie, appel, WhatsApp, SMS).
/// Évite le déclenchement du verrouillage d'écran lors du passage en arrière-plan
/// pour exécuter une application tierce.
class ExternalActionTracker {
  bool _isActive = false;
  DateTime? _lastExternalActionCompletedAt;

  bool get isActive => _isActive;
  DateTime? get lastExternalActionCompletedAt => _lastExternalActionCompletedAt;

  /// Exécute une action externe sous la garde de l'action tracker.
  Future<T> runExternal<T>(Future<T> Function() action) async {
    _isActive = true;
    try {
      return await action();
    } finally {
      _lastExternalActionCompletedAt = DateTime.now();
      _isActive = false;
    }
  }

  /// Déclare le démarrage d'une action externe asynchrone (ex: image_picker).
  void beginExternal() {
    _isActive = true;
  }

  /// Déclare la fin d'une action externe.
  void endExternal() {
    _lastExternalActionCompletedAt = DateTime.now();
    _isActive = false;
  }
}
