import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Représentation d'une photo sélectionnée et stockée localement.
class PickedPhoto {
  final String relativePath; // ex: 'photos/<hash>.jpg'
  final String hash; // Empreinte SHA-256 en hexadécimal

  const PickedPhoto({required this.relativePath, required this.hash});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickedPhoto &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath &&
          hash == other.hash;

  @override
  int get hashCode => relativePath.hashCode ^ hash.hashCode;

  @override
  String toString() => 'PickedPhoto(relativePath: $relativePath, hash: $hash)';
}

enum PhotoSource { camera, gallery }

/// Interface de gestion du stockage des photos de l'atelier.
abstract class PhotoStorage {
  static const double maxWidth = 1600;
  static const double maxHeight = 1600;
  static const int imageQuality = 80;

  /// Sélectionne une photo (appareil photo ou galerie), la compresse et la stocke.
  Future<PickedPhoto?> pick(PhotoSource source);

  /// Récupère une photo perdue suite à la destruction de l'activité sur Android.
  Future<PickedPhoto?> retrieveLostData();

  /// Résout le chemin absolu sur le disque à partir d'un chemin relatif (ou 'demo:N').
  Future<String> getAbsolutePath(String relativePath);

  /// Enregistre directement des octets d'image (après compression), avec dédoublonnage et écriture atomique.
  Future<PickedPhoto> saveBytes(Uint8List bytes);
}

/// Implémentation de production utilisant `image_picker` et `path_provider`.
class DefaultPhotoStorage implements PhotoStorage {
  DefaultPhotoStorage({
    ImagePicker? picker,
    Future<Directory> Function()? getBaseDir,
  })  : _picker = picker ?? ImagePicker(),
        _getBaseDir = getBaseDir ?? getApplicationDocumentsDirectory;

  final ImagePicker _picker;
  final Future<Directory> Function() _getBaseDir;

  Future<Directory> _getPhotosDir() async {
    final baseDir = await _getBaseDir();
    final photosDir = Directory(p.join(baseDir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }

  @override
  Future<String> getAbsolutePath(String relativePath) async {
    if (relativePath.startsWith('demo:')) {
      return relativePath;
    }
    final baseDir = await _getBaseDir();
    return p.join(baseDir.path, relativePath);
  }

  @override
  Future<PickedPhoto?> pick(PhotoSource source) async {
    final imageSource = source == PhotoSource.camera ? ImageSource.camera : ImageSource.gallery;
    final xFile = await _picker.pickImage(
      source: imageSource,
      maxWidth: PhotoStorage.maxWidth,
      maxHeight: PhotoStorage.maxHeight,
      imageQuality: PhotoStorage.imageQuality,
    );
    if (xFile == null) return null;
    final bytes = await xFile.readAsBytes();
    return await saveBytes(bytes);
  }

  @override
  Future<PickedPhoto?> retrieveLostData() async {
    final response = await _picker.retrieveLostData();
    if (response.isEmpty || response.file == null) return null;
    final bytes = await response.file!.readAsBytes();
    return await saveBytes(bytes);
  }

  @override
  Future<PickedPhoto> saveBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Impossible d\'enregistrer une photo vide.');
    }

    final hash = sha256.convert(bytes).toString();
    final relativePath = 'photos/$hash.jpg';

    final photosDir = await _getPhotosDir();
    final targetFile = File(p.join(photosDir.path, '$hash.jpg'));

    // Dédoublonnage : si le fichier existe déjà (même hash), on le réutilise
    if (await targetFile.exists()) {
      return PickedPhoto(relativePath: relativePath, hash: hash);
    }

    // Écriture atomique via un fichier temporaire
    final tempFile = File(
      p.join(photosDir.path, '$hash.jpg.tmp.${DateTime.now().microsecondsSinceEpoch}'),
    );
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      await tempFile.rename(targetFile.path);
    } catch (e) {
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }

    return PickedPhoto(relativePath: relativePath, hash: hash);
  }
}
