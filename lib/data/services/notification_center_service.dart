import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alert_engine.dart';

/// Service de gestion du centre de notifications in-app et des états vu / non vu.
///
/// Règles strictes :
/// - Stockage local dans SharedPreferences (clé JSON hors base SQLite et hors settings).
/// - Jamais synchronisé.
/// - Nettoyage automatique des clés d'alertes disparues ou vieilles de plus de 60 jours.
/// - Mise à jour réactive via ChangeNotifier pour rafraîchir le compteur sans rechargement.
class NotificationCenterService extends ChangeNotifier {
  NotificationCenterService(this._prefs) {
    _load();
  }

  static const String kStorageKey = 'in_app_notifications_read_v1';
  static const int kMaxAgeDays = 60;

  final SharedPreferences _prefs;

  /// Map associative : clé de l'alerte -> horodatage de lecture en millisecondes.
  Map<String, int> _readMap = {};

  /// Destination en attente après déverrouillage du code PIN (Décision 12).
  static bool pendingOpenNotifications = false;

  static Future<NotificationCenterService> create([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return NotificationCenterService(p);
  }

  void _load() {
    final raw = _prefs.getString(kStorageKey);
    if (raw == null || raw.isEmpty) {
      _readMap = {};
      return;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _readMap = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      _readMap = {};
    }
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_readMap);
    await _prefs.setString(kStorageKey, encoded);
  }

  /// Indique si une alerte a déjà été marquée comme lue.
  bool isRead(String alertKey) => _readMap.containsKey(alertKey);

  /// Marque une alerte spécifique comme lue.
  Future<void> markAsRead(String alertKey) async {
    if (_readMap.containsKey(alertKey)) return;
    _readMap[alertKey] = DateTime.now().millisecondsSinceEpoch;
    await _persist();
    notifyListeners();
  }

  /// Marque un ensemble d'alertes comme lues (« Tout marquer comme vu »).
  Future<void> markAllAsRead(Iterable<String> alertKeys) async {
    var changed = false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final key in alertKeys) {
      if (!_readMap.containsKey(key)) {
        _readMap[key] = nowMs;
        changed = true;
      }
    }
    if (changed) {
      await _persist();
      notifyListeners();
    }
  }

  /// Calcule le nombre d'alertes non vues parmi les alertes actives fournies.
  int unreadCount(List<AppAlert> alerts) {
    return alerts.where((a) => !isRead(a.key)).length;
  }

  /// Nettoie les clés d'alertes disparues des données actives ou vieilles de plus de 60 jours.
  Future<void> prune({
    required Set<String> activeKeys,
    DateTime? now,
  }) async {
    final referenceTime = now ?? DateTime.now();
    var changed = false;

    final keysToRemove = <String>[];
    for (final entry in _readMap.entries) {
      final key = entry.key;
      final readAt = DateTime.fromMillisecondsSinceEpoch(entry.value);

      // Supprime si l'alerte n'est plus active
      if (!activeKeys.contains(key)) {
        keysToRemove.add(key);
        changed = true;
        continue;
      }

      // Supprime si la lecture a plus de 60 jours
      if (referenceTime.difference(readAt).inDays > kMaxAgeDays) {
        keysToRemove.add(key);
        changed = true;
      }
    }

    for (final k in keysToRemove) {
      _readMap.remove(k);
    }

    if (changed) {
      await _persist();
      notifyListeners();
    }
  }

  /// Retourne une copie non modifiable des clés lues (pour les tests).
  @visibleForTesting
  Map<String, int> get debugReadMap => Map.unmodifiable(_readMap);
}

