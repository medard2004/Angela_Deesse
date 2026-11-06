import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:angela_dress/data/services/app_lock_manager.dart';
import 'package:angela_dress/data/services/external_action_tracker.dart';
import 'package:angela_dress/data/services/pin_security_service.dart';
import 'package:angela_dress/data/services/secure_storage.dart';
import 'package:angela_dress/screens/lock_screen.dart';
import 'package:angela_dress/ui.dart';

Future<List<int>> fastTestDeriver({
  required String secret,
  required List<int> salt,
  required int iterations,
}) async {
  final bytes = utf8.encode('$secret:${salt.join(',')}');
  return sha256.convert(bytes).bytes;
}

void main() {
  group('PinSecurityService & AppLockManager (Partie C)', () {
    late InMemorySecureStorage storage;
    late PinSecurityService service;
    late DateTime currentTime;

    DateTime testClock() => currentTime;

    setUp(() {
      storage = InMemorySecureStorage();
      currentTime = DateTime(2026, 6, 1, 10, 0, 0);
      service = PinSecurityService(
        storage: storage,
        deriver: fastTestDeriver,
        clock: testClock,
        iterations: 1000,
      );
    });

    test('1. Création, vérification, mauvais code et changement de code (ancien requis)', () async {
      // Non configuré au départ
      final initialStatus = await service.getPinStatus();
      expect(initialStatus.status, PinStatus.unconfigured);

      // Rejet des codes triviaux
      for (final trivial in ['0000', '1111', '1234', '4321', '1212', '2580', '0852']) {
        expect(() => service.createPin(trivial), throwsArgumentError);
      }

      // Création du PIN robuste
      final recoveryCode = await service.createPin('4826');
      expect(recoveryCode, matches(RegExp(r'^[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$')));

      final configuredStatus = await service.getPinStatus();
      expect(configuredStatus.status, PinStatus.configured);

      // Vérification PIN correct
      final okResult = await service.verifyPin('4826');
      expect(okResult.isSuccess, isTrue);

      // Vérification mauvais code
      final badResult = await service.verifyPin('0000');
      expect(badResult.isSuccess, isFalse);
      expect(badResult.status, PinVerifyStatus.mismatch);
      expect(badResult.failedAttempts, 1);

      // Changement de code : ancien requis
      final failChange = await service.changePin(oldPin: '9999', newPin: '7391');
      expect(failChange.success, isFalse);
      expect(failChange.message, contains('Ancien code incorrect'));

      // Changement de code valide
      final okChange = await service.changePin(oldPin: '4826', newPin: '7391');
      expect(okChange.success, isTrue);
      expect(okChange.newRecoveryCode, isNotNull);

      // L'ancien ne marche plus, le nouveau marche
      expect((await service.verifyPin('4826')).isSuccess, isFalse);
      expect((await service.verifyPin('7391')).isSuccess, isTrue);
    });

    test('2. Paliers de verrouillage, persistance du compteur et remise à zéro au succès', () async {
      await service.createPin('4826');

      // 4 premiers échecs : pas de verrou
      for (var i = 1; i <= 4; i++) {
        final r = await service.verifyPin('0000');
        expect(r.isLocked, isFalse);
        expect(r.failedAttempts, i);
        expect(r.lockoutRemaining, isNull);
      }

      // 5e échec -> verrou 30s
      final r5 = await service.verifyPin('0000');
      expect(r5.isLocked, isTrue);
      expect(r5.failedAttempts, 5);
      expect(r5.lockoutRemaining?.inSeconds, 30);

      // Pendant le verrou, un nouvel essai est rejeté immédiatement
      final rLocked = await service.verifyPin('4826');
      expect(rLocked.isLocked, isTrue);

      // Avancer le temps de 31s
      currentTime = currentTime.add(const Duration(seconds: 31));

      // 6e échec -> verrou 1 min (60s)
      final r6 = await service.verifyPin('0000');
      expect(r6.isLocked, isTrue);
      expect(r6.failedAttempts, 6);
      expect(r6.lockoutRemaining?.inSeconds, 60);

      // Avancer le temps de 61s et tester un succès -> remise à zéro
      currentTime = currentTime.add(const Duration(seconds: 61));
      final rSuccess = await service.verifyPin('4826');
      expect(rSuccess.isSuccess, isTrue);
      expect(await service.getFailedAttempts(), 0);
    });

    test('3. Le compteur survit à une fermeture (nouvelle instance du service)', () async {
      await service.createPin('7391');

      // 3 échecs avec service 1
      await service.verifyPin('0000');
      await service.verifyPin('0000');
      await service.verifyPin('0000');

      // Recréation d'une instance sur le même stockage (simule un redémarrage de l'app)
      final service2 = PinSecurityService(
        storage: storage,
        deriver: fastTestDeriver,
        clock: testClock,
        iterations: 1000,
      );

      expect(await service2.getFailedAttempts(), 3);

      // 2 nouveaux échecs avec service 2 (total 5) -> verrouille
      await service2.verifyPin('0000');
      final r5 = await service2.verifyPin('0000');
      expect(r5.isLocked, isTrue);
      expect(r5.failedAttempts, 5);
      expect(r5.lockoutRemaining?.inSeconds, 30);
    });

    test('4. L\'incrément précède la comparaison (simulation de crash entre les deux)', () async {
      await service.createPin('3915');

      // Hook pour crasher au moment exact après l'enregistrement mais avant le calcul de hash
      service.onBeforeHashComparison = () {
        throw Exception('Crash simulé par extinction soudaine');
      };

      try {
        await service.verifyPin('9999');
      } catch (_) {}

      // Malgré le crash, l'échec est persisté dans le stockage
      expect(await service.getFailedAttempts(), 1);
    });

    test('5. Garde d\'horloge : reculer l\'horloge ne raccourcit pas le verrou', () async {
      await service.createPin('6294');

      // Déclencher le verrou à 5 échecs à 10:00:00
      for (var i = 0; i < 5; i++) {
        await service.verifyPin('0000');
      }

      // À 10:00:10 (10s écoulées, reste 20s)
      currentTime = currentTime.add(const Duration(seconds: 10));
      final rem1 = await service.getLockoutRemaining();
      expect(rem1?.inSeconds, 20);

      // L'utilisateur recule son horloge système de 2 heures en arrière (08:00:00)
      currentTime = currentTime.subtract(const Duration(hours: 2));

      // La garde anti-rembobinage détecte le recul et compense l'échéance : le verrou n'est pas raccourci
      final remAfterRewind = await service.getLockoutRemaining();
      expect(remAfterRewind, isNotNull);
      expect(remAfterRewind!.inSeconds, greaterThanOrEqualTo(20));
    });

    test('6. Code de récupération : utilisable pour restaurer, essais limités, formats tolérants', () async {
      final recoveryCode = await service.createPin('8147');

      // Mauvais code de récupération
      final badRec = await service.verifyRecoveryCode('XXXX-XXXX-XXXX');
      expect(badRec.isSuccess, isFalse);
      expect(badRec.failedAttempts, 1);

      // Bon code de récupération (avec minuscules, sans tirets ni espaces)
      final stripped = recoveryCode.replaceAll('-', '').toLowerCase();
      final okRec = await service.verifyRecoveryCode(stripped);
      expect(okRec.isSuccess, isTrue);

      // Remise à zéro des compteurs après succès
      expect(await service.getFailedAttempts(), 0);
    });

    test('7. Aucun secret en clair dans le stockage (ni PIN, ni code de récupération)', () async {
      final recCode = await service.createPin('8147');

      final dumpValues = storage.dump.values.join(' ');
      final dumpKeys = storage.dump.keys.join(' ');

      // Le PIN en clair n'apparaît nulle part
      expect(dumpValues.contains('8147'), isFalse);
      expect(dumpKeys.contains('8147'), isFalse);

      // Le code de récupération en clair n'apparaît nulle part
      expect(dumpValues.contains(recCode), isFalse);
      expect(dumpValues.contains(recCode.replaceAll('-', '')), isFalse);
    });

    test('8. Verrouillage automatique AppLockManager (< 2 min vs > 2 min, action externe)', () {
      final tracker = ExternalActionTracker();
      var lockTriggered = false;

      final lockManager = AppLockManager(
        securityService: service,
        tracker: tracker,
        clock: testClock,
        onLockRequired: () => lockTriggered = true,
      );

      lockManager.markUnlocked();
      expect(lockManager.isLocked, isFalse);

      // Pause de 1 min 30 s (< 2 min) -> pas de verrou
      lockManager.onAppPaused();
      currentTime = currentTime.add(const Duration(minutes: 1, seconds: 30));
      lockManager.onAppResumed();
      expect(lockManager.isLocked, isFalse);
      expect(lockTriggered, isFalse);

      // Pause de 2 min 05 s (> 2 min) -> verrouillage automatique
      lockManager.onAppPaused();
      currentTime = currentTime.add(const Duration(minutes: 2, seconds: 5));
      lockManager.onAppResumed();
      expect(lockManager.isLocked, isTrue);
      expect(lockTriggered, isTrue);

      // Réinitialiser
      lockManager.markUnlocked();
      lockTriggered = false;

      // Action externe (ex: prise de photo / caméra / WhatsApp)
      tracker.runExternal(() async {
        lockManager.onAppPaused();
        currentTime = currentTime.add(const Duration(minutes: 5));
        lockManager.onAppResumed();
      });

      // L'action externe a protégé l'application : aucun verrouillage au retour
      expect(lockManager.isLocked, isFalse);
      expect(lockTriggered, isFalse);
    });

    test('9. Échec d\'accès au stockage sécurisé : traité comme erreur fatale (jamais aucun PIN)', () async {
      final brokenStorage = _FailingSecureStorage();
      final brokenService = PinSecurityService(storage: brokenStorage);

      final status = await brokenService.getPinStatus();
      expect(status.status, PinStatus.storageError);
      expect(status.error, isNotNull);
    });

    test('10. Vraie dérivation PBKDF2-HMAC-SHA256 (defaultPbkdf2Deriver)', () async {
      // Test de l'algorithme réel sur 100 itérations
      final salt = generateSalt(16);
      final derived1 = await defaultPbkdf2Deriver(secret: '1234', salt: salt, iterations: 100);
      final derived2 = await defaultPbkdf2Deriver(secret: '1234', salt: salt, iterations: 100);
      final derivedOther = await defaultPbkdf2Deriver(secret: '9999', salt: salt, iterations: 100);

      expect(derived1.length, 32);
      expect(constantTimeEquals(derived1, derived2), isTrue);
      expect(constantTimeEquals(derived1, derivedOther), isFalse);
    });

    testWidgets('11. Test Widget : LockScreen refuse un code arbitre et valide le bon PIN', (tester) async {
      await service.createPin('4826');
      final tracker = ExternalActionTracker();
      final lockManager = AppLockManager(
        securityService: service,
        tracker: tracker,
      );

      var unlocked = false;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<PinSecurityService>.value(value: service),
            Provider<AppLockManager>.value(value: lockManager),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final res = await Navigator.of(ctx).push(
                      MaterialPageRoute(
                        builder: (_) => const LockScreen(mode: LockMode.unlock),
                      ),
                    );
                    if (res == true) unlocked = true;
                  },
                  child: const Text('Ouvrir Verrou'),
                ),
              ),
            ),
          ),
        ),
      );

      // Ouvrir le LockScreen
      await tester.tap(find.text('Ouvrir Verrou'));
      await tester.pumpAndSettle();

      expect(find.text('Entrez votre code'), findsOneWidget);

      // Saisir un mauvais code '0000'
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('0'));
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // Le LockScreen est toujours présent et affiche une erreur
      expect(find.text('Entrez votre code'), findsOneWidget);
      expect(find.text("Code d'accès incorrect"), findsOneWidget);
      expect(unlocked, isFalse);

      // Saisir le bon code '4826'
      await tester.tap(find.text('4'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();

      // Le LockScreen s'est fermé avec succès
      expect(find.text('Entrez votre code'), findsNothing);
      expect(unlocked, isTrue);
    });

    testWidgets('12. Test Widget : Création de PIN refuse les codes triviaux', (tester) async {
      final tracker = ExternalActionTracker();
      final lockManager = AppLockManager(
        securityService: service,
        tracker: tracker,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<PinSecurityService>.value(value: service),
            Provider<AppLockManager>.value(value: lockManager),
          ],
          child: const MaterialApp(
            home: LockScreen(mode: LockMode.create),
          ),
        ),
      );

      expect(find.text('Créer votre code secret'), findsOneWidget);

      // Taper 2580 (trivial)
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('5'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      // Refusé avec message
      expect(find.text('Code trop simple, choisissez-en un autre'), findsOneWidget);
      expect(find.text('Confirmez votre code'), findsNothing);
    });
  });
}

class _FailingSecureStorage implements SecureStorage {
  @override
  Future<String?> read(String key) async => throw Exception('Stockage sécurisé inaccessible');

  @override
  Future<void> write(String key, String value) async => throw Exception('Stockage sécurisé inaccessible');

  @override
  Future<void> delete(String key) async => throw Exception('Stockage sécurisé inaccessible');

  @override
  Future<void> deleteAll() async => throw Exception('Stockage sécurisé inaccessible');
}
