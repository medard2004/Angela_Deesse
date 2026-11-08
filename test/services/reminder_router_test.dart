import 'package:flutter_test/flutter_test.dart';
import 'package:angela_dress/data/repositories/settings_repository.dart';
import 'package:angela_dress/data/services/reminder_router.dart';

void main() {
  group('ReminderRouter - Matrice complète des décisions', () {
    test('Mode désactivé (none) produit toujours ReminderAction.none', () {
      expect(
        ReminderRouter.decide(
          mode: ReminderMode.none,
          isForegroundAndUnlocked: true,
        ),
        equals(ReminderAction.none),
      );

      expect(
        ReminderRouter.decide(
          mode: ReminderMode.none,
          isForegroundAndUnlocked: false,
        ),
        equals(ReminderAction.none),
      );
    });

    test('Mode alarme : alarme native en arrière-plan/verrouillé, bandeau in-app si premier plan déverrouillé', () {
      // Téléphone fermé ou verrouillé : alarme réveil native
      expect(
        ReminderRouter.decide(
          mode: ReminderMode.alarm,
          isForegroundAndUnlocked: false,
        ),
        equals(ReminderAction.nativeAlarm),
      );

      // Application active au premier plan et déverrouillée : bandeau in-app non assourdissant
      expect(
        ReminderRouter.decide(
          mode: ReminderMode.alarm,
          isForegroundAndUnlocked: true,
        ),
        equals(ReminderAction.inAppBanner),
      );
    });

    test('Mode notification : notification système si fermé/verrouillé, bandeau in-app si actif déverrouillé', () {
      // Téléphone fermé ou verrouillé : notification système calme
      expect(
        ReminderRouter.decide(
          mode: ReminderMode.notification,
          isForegroundAndUnlocked: false,
        ),
        equals(ReminderAction.systemNotification),
      );

      // Application active au premier plan et déverrouillée : bandeau in-app uniquement (sans doublon push)
      expect(
        ReminderRouter.decide(
          mode: ReminderMode.notification,
          isForegroundAndUnlocked: true,
        ),
        equals(ReminderAction.inAppBanner),
      );
    });
  });
}
