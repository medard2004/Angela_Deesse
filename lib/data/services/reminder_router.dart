import '../repositories/settings_repository.dart';

enum ReminderAction {
  nativeAlarm,
  systemNotification,
  inAppBanner,
  none,
}

/// Routeur de rappels pur (Décision Commit 4).
///
/// Détermine l'action appropriée selon le mode configuré pour la catégorie
/// et la visibilité/sécurité de l'application.
class ReminderRouter {
  const ReminderRouter();

  static ReminderAction decide({
    required ReminderMode mode,
    required bool isForegroundAndUnlocked,
  }) {
    switch (mode) {
      case ReminderMode.none:
        return ReminderAction.none;
      case ReminderMode.alarm:
        return isForegroundAndUnlocked
            ? ReminderAction.inAppBanner
            : ReminderAction.nativeAlarm;
      case ReminderMode.notification:
        return isForegroundAndUnlocked
            ? ReminderAction.inAppBanner
            : ReminderAction.systemNotification;
    }
  }
}
