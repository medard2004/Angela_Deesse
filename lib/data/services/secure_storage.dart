import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Interface d'abstraction pour le stockage sécurisé (Keychain iOS, Keystore/EncryptedSharedPreferences Android).
abstract class SecureStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Nettoie le Keychain résiduel sur iOS lors du premier lancement après réinstallation.
Future<void> clearKeychainIfFirstRun(SecureStorage storage) async {
  try {
    if (Platform.isIOS) {
      final docDir = await getApplicationDocumentsDirectory();
      final markerFile = File('${docDir.path}/.keychain_initialized');
      if (!await markerFile.exists()) {
        await storage.deleteAll();
        await markerFile.create();
      }
    }
  } catch (_) {}
}

/// Implémentation réelle utilisant `flutter_secure_storage`.
class FlutterSecureStorageWrapper implements SecureStorage {
  final FlutterSecureStorage _storage;

  const FlutterSecureStorageWrapper([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: false),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  ]);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

/// Faux stockage en mémoire pour les tests unitaires et widgets.
class InMemorySecureStorage implements SecureStorage {
  final Map<String, String> _data = {};

  Map<String, String> get dump => Map.unmodifiable(_data);

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> deleteAll() async => _data.clear();
}
