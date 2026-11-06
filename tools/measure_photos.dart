// ignore_for_file: avoid_print, unintended_html_in_doc_comment
import 'dart:io';
import 'dart:typed_data';

import 'package:angela_dress/data/utils/jpeg_sanitizer.dart';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

/// Script de mesure de taille des photos réelles après redimensionnement (1280px max, q75)
/// et assainissement EXIF/GPS.
///
/// Usage :
///   dart run tools/measure_photos.dart photo1.jpg photo2.jpg ...
/// ou sans argument pour chercher les fichiers *.jpg / *.jpeg dans le dossier courant ou test_photos/
Future<void> main(List<String> args) async {
  List<File> files = [];

  if (args.isNotEmpty) {
    for (final path in args) {
      final f = File(path);
      if (f.existsSync()) files.add(f);
    }
  } else {
    final dirs = [Directory('test_photos'), Directory('.')];
    for (final dir in dirs) {
      if (dir.existsSync()) {
        final list = dir
            .listSync()
            .whereType<File>()
            .where((f) =>
                f.path.toLowerCase().endsWith('.jpg') ||
                f.path.toLowerCase().endsWith('.jpeg'))
            .toList();
        if (list.isNotEmpty) {
          files = list.take(5).toList();
          break;
        }
      }
    }
  }

  if (files.isEmpty) {
    print('Aucun fichier photo trouvé.');
    print('Usage : dart run tools/measure_photos.dart photo1.jpg photo2.jpg ...');
    exit(0);
  }

  print('=== Mesure sur ${files.length} photo(s) (1280px max, q75, assainissement EXIF/GPS) ===\n');

  int totalBytes = 0;
  int count = 0;

  for (final file in files) {
    count++;
    final rawBytes = file.readAsBytesSync();
    final originalSizeKb = (rawBytes.length / 1024).toStringAsFixed(1);

    // Décodage et redimensionnement max 1280px à q75
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      print('[$count] ${file.path} : Erreur de décodage image');
      continue;
    }

    img.Image resized = decoded;
    if (decoded.width > 1280 || decoded.height > 1280) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: 1280);
      } else {
        resized = img.copyResize(decoded, height: 1280);
      }
    }

    // Encodage q75
    final encodedJpg = Uint8List.fromList(img.encodeJpg(resized, quality: 75));

    // Assainissement final (stripping EXIF/GPS/XMP)
    final sanitizedBytes = sanitizeJpeg(encodedJpg);
    final hash = sha256.convert(sanitizedBytes).toString();
    final finalSizeKb = (sanitizedBytes.length / 1024).toStringAsFixed(1);
    totalBytes += sanitizedBytes.length;

    print('[$count] ${file.path}');
    print('    Dimensions initiales : ${decoded.width}x${decoded.height} ($originalSizeKb Ko)');
    print('    Dimensions finales   : ${resized.width}x${resized.height}');
    print('    Taille finale        : $finalSizeKb Ko (${sanitizedBytes.length} octets)');
    print('    Hash SHA-256         : ${hash.substring(0, 16)}...');
    print('    Présence EXIF/GPS    : ${hasExifOrGpsMetadata(sanitizedBytes) ? "OUI (ANORMAL)" : "NON (PROPRE)"}\n');
  }

  if (count > 0) {
    final avgKb = (totalBytes / count / 1024).toStringAsFixed(1);
    print('----------------------------------------------------');
    print('Nombre de photos traitées : $count');
    print('Taille moyenne finale     : $avgKb Ko (objectif : 150 - 350 Ko)');
    print('----------------------------------------------------');
  }
}
