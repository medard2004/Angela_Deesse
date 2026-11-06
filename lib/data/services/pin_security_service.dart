import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'secure_storage.dart';

/// Statut de configuration du PIN dans le stockage sécurisé.
enum PinStatus {
  unconfigured,
  configured,
  storageError,
}

class PinStatusResult {
  final PinStatus status;
  final Object? error;
  const PinStatusResult(this.status, [this.error]);
}

/// Statut de vérification du PIN.
enum PinVerifyStatus {
  success,
  mismatch,
  locked,
  storageError,
}

class PinVerifyResult {
  final PinVerifyStatus status;
  final int failedAttempts;
  final Duration? lockoutRemaining;
  final Object? error;

  const PinVerifyResult({
    required this.status,
    this.failedAttempts = 0,
    this.lockoutRemaining,
    this.error,
  });

  bool get isSuccess => status == PinVerifyStatus.success;
  bool get isLocked => status == PinVerifyStatus.locked;
}

/// Statut de vérification du code de récupération.
enum RecoveryVerifyStatus {
  success,
  mismatch,
  locked,
  storageError,
}

class RecoveryVerifyResult {
  final RecoveryVerifyStatus status;
  final int failedAttempts;
  final Duration? lockoutRemaining;
  final Object? error;

  const RecoveryVerifyResult({
    required this.status,
    this.failedAttempts = 0,
    this.lockoutRemaining,
    this.error,
  });

  bool get isSuccess => status == RecoveryVerifyStatus.success;
  bool get isLocked => status == RecoveryVerifyStatus.locked;
}

/// Résultat d'un changement de PIN.
class ChangePinResult {
  final bool success;
  final String? message;
  final String? newRecoveryCode;
  final Duration? lockoutRemaining;

  const ChangePinResult({
    required this.success,
    this.message,
    this.newRecoveryCode,
    this.lockoutRemaining,
  });
}

/// Type de fonction pour la dérivation de clé PBKDF2 (permet l'injection dans les tests).
typedef Pbkdf2Deriver = Future<List<int>> Function({
  required String secret,
  required List<int> salt,
  required int iterations,
});

/// Dérivation PBKDF2-HMAC-SHA256 par défaut exécutée dans un Isolate séparé.
Future<List<int>> defaultPbkdf2Deriver({
  required String secret,
  required List<int> salt,
  required int iterations,
}) async {
  return await Isolate.run(() async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    final secretKey = SecretKey(utf8.encode(secret));
    final derived = await pbkdf2.deriveKey(secretKey: secretKey, nonce: salt);
    return await derived.extractBytes();
  });
}

/// Comparaison en temps constant pour éviter les attaques temporelles.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

/// Alphabet Crockford Base32 sans ambiguïté visuelle (sans 0, 1, I, L, O, U).
const String crockfordAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/// Génère un code de récupération de 12 caractères formaté `XXXX-XXXX-XXXX`.
String generateRecoveryCode() {
  final rng = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < 12; i++) {
    if (i > 0 && i % 4 == 0) buffer.write('-');
    buffer.write(crockfordAlphabet[rng.nextInt(crockfordAlphabet.length)]);
  }
  return buffer.toString();
}

/// Normalise la saisie utilisateur d'un code de récupération (supprime tirets et espaces, majuscules).
String normalizeRecoveryCode(String input) {
  return input.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
}

/// Génère un sel cryptographique aléatoire de 16 octets.
List<int> generateSalt([int length = 16]) {
  final rng = Random.secure();
  return List<int>.generate(length, (_) => rng.nextInt(256));
}

/// Service de gestion du verrouillage PIN sécurisé.
class PinSecurityService {
  static const String keyPinSaltHex = 'sec_pin_salt_hex';
  static const String keyPinHashHex = 'sec_pin_hash_hex';
  static const String keyPinIter = 'sec_pin_iter';
  static const String keyRecoverySaltHex = 'sec_rec_salt_hex';
  static const String keyRecoveryHashHex = 'sec_rec_hash_hex';
  static const String keyRecoveryIter = 'sec_rec_iter';
  static const String keyFailedAttempts = 'sec_failed_attempts';
  static const String keyLockedUntilMs = 'sec_locked_until_ms';
  static const String keyLastSeenMs = 'sec_last_seen_ms';

  /// Nombre d'itérations mesuré pour environ 300-370 ms de dérivation.
  static const int defaultIterations = 30000;

  final SecureStorage _storage;
  final Pbkdf2Deriver _deriver;
  final DateTime Function() _clock;
  final int _iterations;

  /// Hook optionnel pour tester la résilience aux crashs (appelé entre l'incrément et le hachage).
  void Function()? onBeforeHashComparison;

  PinSecurityService({
    required SecureStorage storage,
    Pbkdf2Deriver? deriver,
    DateTime Function()? clock,
    int iterations = defaultIterations,
  })  : _storage = storage,
        _deriver = deriver ?? defaultPbkdf2Deriver,
        _clock = clock ?? DateTime.now,
        _iterations = iterations;

  /// Vérifie si un code PIN est déjà configuré dans le stockage sécurisé.
  Future<PinStatusResult> getPinStatus() async {
    try {
      final salt = await _storage.read(keyPinSaltHex);
      final hash = await _storage.read(keyPinHashHex);
      if (salt != null && hash != null) {
        return const PinStatusResult(PinStatus.configured);
      }
      return const PinStatusResult(PinStatus.unconfigured);
    } catch (e) {
      return PinStatusResult(PinStatus.storageError, e);
    }
  }

  /// Retourne le nombre d'échecs consécutifs actuels.
  Future<int> getFailedAttempts() async {
    try {
      final str = await _storage.read(keyFailedAttempts);
      return str != null ? int.tryParse(str) ?? 0 : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Calcule la durée de verrouillage selon les paliers progressifs :
  /// 5 échecs -> 30 s
  /// 6 échecs -> 1 min (60 s)
  /// 7 échecs -> 5 min (300 s)
  /// 8 échecs -> 15 min (900 s)
  /// >= 9 échecs -> 1 h (3600 s)
  static Duration? computeLockout(int failedAttempts) {
    if (failedAttempts < 5) return null;
    switch (failedAttempts) {
      case 5:
        return const Duration(seconds: 30);
      case 6:
        return const Duration(minutes: 1);
      case 7:
        return const Duration(minutes: 5);
      case 8:
        return const Duration(minutes: 15);
      default:
        return const Duration(hours: 1);
    }
  }

  /// Calcule le temps de verrouillage restant en tenant compte de la garde anti-rembobinage.
  Future<Duration?> getLockoutRemaining() async {
    try {
      final lockedUntilStr = await _storage.read(keyLockedUntilMs);
      if (lockedUntilStr == null) return null;

      var lockedUntilMs = int.tryParse(lockedUntilStr);
      if (lockedUntilMs == null) return null;

      final lastSeenStr = await _storage.read(keyLastSeenMs);
      final lastSeenMs = lastSeenStr != null ? int.tryParse(lastSeenStr) : null;
      final nowMs = _clock().millisecondsSinceEpoch;

      var effectiveNow = nowMs;

      // Garde d'horloge anti-rembobinage :
      // Si l'heure courante est inférieure à la dernière heure vue, l'horloge a été reculée.
      // On compense lockedUntilMs du même écart afin que reculer l'heure ne raccourcisse pas le verrou.
      if (lastSeenMs != null && nowMs < lastSeenMs) {
        final delta = lastSeenMs - nowMs;
        lockedUntilMs += delta;
        await _storage.write(keyLockedUntilMs, lockedUntilMs.toString());
        effectiveNow = lastSeenMs;
      }

      if (effectiveNow >= lockedUntilMs) {
        // Verrou expiré
        await _storage.delete(keyLockedUntilMs);
        await _storage.write(keyLastSeenMs, effectiveNow.toString());
        return null;
      }

      await _storage.write(keyLastSeenMs, effectiveNow.toString());
      return Duration(milliseconds: lockedUntilMs - effectiveNow);
    } catch (_) {
      return null;
    }
  }

  /// Crée un nouveau PIN et génère son code de récupération associé.
  /// Stocke uniquement les sels et les hashs PBKDF2 (aucun secret en clair).
  Future<String> createPin(
    String pin, {
    String? customRecoveryCode,
  }) async {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError('Le code PIN doit comporter exactement 4 chiffres.');
    }

    final pinSalt = generateSalt();
    final pinHash = await _deriver(
      secret: pin,
      salt: pinSalt,
      iterations: _iterations,
    );

    final rawRecovery = customRecoveryCode ?? generateRecoveryCode();
    final normalizedRec = normalizeRecoveryCode(rawRecovery);
    final recSalt = generateSalt();
    final recHash = await _deriver(
      secret: normalizedRec,
      salt: recSalt,
      iterations: _iterations,
    );

    await _storage.write(keyPinSaltHex, _toHex(pinSalt));
    await _storage.write(keyPinHashHex, _toHex(pinHash));
    await _storage.write(keyPinIter, _iterations.toString());

    await _storage.write(keyRecoverySaltHex, _toHex(recSalt));
    await _storage.write(keyRecoveryHashHex, _toHex(recHash));
    await _storage.write(keyRecoveryIter, _iterations.toString());

    // Réinitialisation des compteurs d'échecs
    await _storage.delete(keyFailedAttempts);
    await _storage.delete(keyLockedUntilMs);
    await _storage.write(
      keyLastSeenMs,
      _clock().millisecondsSinceEpoch.toString(),
    );

    return rawRecovery;
  }

  /// Vérifie le code PIN saisi.
  /// CRITIQUE : Le compteur d'échecs est incrémenté et persisté AVANT la comparaison du hash.
  Future<PinVerifyResult> verifyPin(String pin) async {
    try {
      // 1. Vérifier si le système est verrouillé
      final remaining = await getLockoutRemaining();
      if (remaining != null && remaining > Duration.zero) {
        final currentFailures = await getFailedAttempts();
        return PinVerifyResult(
          status: PinVerifyStatus.locked,
          failedAttempts: currentFailures,
          lockoutRemaining: remaining,
        );
      }

      // 2. Lire les données de référence
      final saltHex = await _storage.read(keyPinSaltHex);
      final hashHex = await _storage.read(keyPinHashHex);
      final iterStr = await _storage.read(keyPinIter);

      if (saltHex == null || hashHex == null) {
        return const PinVerifyResult(status: PinVerifyStatus.mismatch);
      }

      final iterations = int.tryParse(iterStr ?? '') ?? _iterations;

      // 3. Incrémenter et persister l'échec AVANT le hachage
      final currentFailures = await getFailedAttempts();
      final newFailures = currentFailures + 1;
      final lockout = computeLockout(newFailures);
      final nowMs = _clock().millisecondsSinceEpoch;

      await _storage.write(keyFailedAttempts, newFailures.toString());
      await _storage.write(keyLastSeenMs, nowMs.toString());
      if (lockout != null) {
        final lockedUntilMs = nowMs + lockout.inMilliseconds;
        await _storage.write(keyLockedUntilMs, lockedUntilMs.toString());
      }

      // Hook de test pour simuler un crash ou une extinction entre l'incrément et le test
      onBeforeHashComparison?.call();

      // 4. Calculer le hash PBKDF2
      final salt = _fromHex(saltHex);
      final expectedHash = _fromHex(hashHex);
      final derived = await _deriver(
        secret: pin,
        salt: salt,
        iterations: iterations,
      );

      // 5. Comparaison en temps constant
      final isMatch = constantTimeEquals(derived, expectedHash);
      if (isMatch) {
        // Succès : remise à zéro du compteur et des verrous
        await _storage.delete(keyFailedAttempts);
        await _storage.delete(keyLockedUntilMs);
        await _storage.write(
          keyLastSeenMs,
          _clock().millisecondsSinceEpoch.toString(),
        );
        return const PinVerifyResult(status: PinVerifyStatus.success);
      } else {
        return PinVerifyResult(
          status: lockout != null ? PinVerifyStatus.locked : PinVerifyStatus.mismatch,
          failedAttempts: newFailures,
          lockoutRemaining: lockout,
        );
      }
    } catch (e) {
      return PinVerifyResult(status: PinVerifyStatus.storageError, error: e);
    }
  }

  /// Vérifie le code de récupération saisi (pour réinitialiser le PIN).
  /// Mêmes limites d'essais et incrément avant calcul.
  Future<RecoveryVerifyResult> verifyRecoveryCode(String rawCode) async {
    try {
      final remaining = await getLockoutRemaining();
      if (remaining != null && remaining > Duration.zero) {
        final currentFailures = await getFailedAttempts();
        return RecoveryVerifyResult(
          status: RecoveryVerifyStatus.locked,
          failedAttempts: currentFailures,
          lockoutRemaining: remaining,
        );
      }

      final saltHex = await _storage.read(keyRecoverySaltHex);
      final hashHex = await _storage.read(keyRecoveryHashHex);
      final iterStr = await _storage.read(keyRecoveryIter);

      if (saltHex == null || hashHex == null) {
        return const RecoveryVerifyResult(status: RecoveryVerifyStatus.mismatch);
      }

      final iterations = int.tryParse(iterStr ?? '') ?? _iterations;

      // Incrémenter et persister AVANT
      final currentFailures = await getFailedAttempts();
      final newFailures = currentFailures + 1;
      final lockout = computeLockout(newFailures);
      final nowMs = _clock().millisecondsSinceEpoch;

      await _storage.write(keyFailedAttempts, newFailures.toString());
      await _storage.write(keyLastSeenMs, nowMs.toString());
      if (lockout != null) {
        final lockedUntilMs = nowMs + lockout.inMilliseconds;
        await _storage.write(keyLockedUntilMs, lockedUntilMs.toString());
      }

      onBeforeHashComparison?.call();

      final normalized = normalizeRecoveryCode(rawCode);
      final salt = _fromHex(saltHex);
      final expectedHash = _fromHex(hashHex);
      final derived = await _deriver(
        secret: normalized,
        salt: salt,
        iterations: iterations,
      );

      final isMatch = constantTimeEquals(derived, expectedHash);
      if (isMatch) {
        await _storage.delete(keyFailedAttempts);
        await _storage.delete(keyLockedUntilMs);
        await _storage.write(
          keyLastSeenMs,
          _clock().millisecondsSinceEpoch.toString(),
        );
        return const RecoveryVerifyResult(status: RecoveryVerifyStatus.success);
      } else {
        return RecoveryVerifyResult(
          status: lockout != null
              ? RecoveryVerifyStatus.locked
              : RecoveryVerifyStatus.mismatch,
          failedAttempts: newFailures,
          lockoutRemaining: lockout,
        );
      }
    } catch (e) {
      return RecoveryVerifyResult(
        status: RecoveryVerifyStatus.storageError,
        error: e,
      );
    }
  }

  /// Change le code PIN en exigeant l'ancien code.
  Future<ChangePinResult> changePin({
    required String oldPin,
    required String newPin,
    String? customRecoveryCode,
  }) async {
    final verifyResult = await verifyPin(oldPin);
    if (verifyResult.isLocked) {
      return ChangePinResult(
        success: false,
        message: 'Application verrouillée temporairement.',
        lockoutRemaining: verifyResult.lockoutRemaining,
      );
    }
    if (!verifyResult.isSuccess) {
      return const ChangePinResult(
        success: false,
        message: 'Ancien code incorrect.',
      );
    }

    final newRecovery = await createPin(
      newPin,
      customRecoveryCode: customRecoveryCode,
    );
    return ChangePinResult(
      success: true,
      newRecoveryCode: newRecovery,
    );
  }

  String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  List<int> _fromHex(String hex) {
    final result = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      result.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return result;
  }
}
