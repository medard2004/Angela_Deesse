import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Lit l'orientation EXIF depuis un flux d'octets JPEG sans décoder l'image.
/// Retourne null si aucune balise d'orientation n'est présente.
int? readExifOrientation(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  int offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) {
      offset++;
      continue;
    }
    while (offset < bytes.length && bytes[offset] == 0xFF) {
      offset++;
    }
    if (offset >= bytes.length) break;
    final marker = bytes[offset++];
    if (marker == 0xD9 || marker == 0xDA) break; // EOI ou SOS
    if (marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      continue;
    }

    if (offset + 2 > bytes.length) break;
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    if (offset + length > bytes.length) break;

    if (marker == 0xE1) {
      // APP1 segment: vérifier le préfixe 'Exif\0\0'
      final segStart = offset + 2;
      if (segStart + 6 <= bytes.length &&
          bytes[segStart] == 0x45 && // E
          bytes[segStart + 1] == 0x78 && // x
          bytes[segStart + 2] == 0x69 && // i
          bytes[segStart + 3] == 0x66 && // f
          bytes[segStart + 4] == 0x00 &&
          bytes[segStart + 5] == 0x00) {
        final tiffStart = segStart + 6;
        if (tiffStart + 8 > bytes.length) break;
        final isLittleEndian = bytes[tiffStart] == 0x49 && bytes[tiffStart + 1] == 0x49; // 'II'
        final isBigEndian = bytes[tiffStart] == 0x4D && bytes[tiffStart + 1] == 0x4D; // 'MM'
        if (!isLittleEndian && !isBigEndian) break;

        int readUint16(int p) {
          if (p + 2 > bytes.length) return 0;
          return isLittleEndian
              ? bytes[p] | (bytes[p + 1] << 8)
              : (bytes[p] << 8) | bytes[p + 1];
        }

        int readUint32(int p) {
          if (p + 4 > bytes.length) return 0;
          return isLittleEndian
              ? bytes[p] | (bytes[p + 1] << 8) | (bytes[p + 2] << 16) | (bytes[p + 3] << 24)
              : (bytes[p] << 24) | (bytes[p + 2] << 16) | (bytes[p + 1] << 8) | bytes[p + 3];
        }

        final ifd0Offset = readUint32(tiffStart + 4);
        final ifd0Start = tiffStart + ifd0Offset;
        if (ifd0Start + 2 > bytes.length) break;
        final numEntries = readUint16(ifd0Start);
        for (int i = 0; i < numEntries; i++) {
          final entryStart = ifd0Start + 2 + (i * 12);
          if (entryStart + 12 > bytes.length) break;
          final tag = readUint16(entryStart);
          if (tag == 0x0112) {
            // Orientation tag
            return readUint16(entryStart + 8);
          }
        }
      }
    }
    offset += length;
  }
  return null;
}

/// Nettoie les segments de métadonnées JPEG (APP1/Exif/XMP, APP13/IPTC, COM) de manière sans perte.
/// Préserve 100% de la qualité des pixels compressés et tous les segments structurels (SOF, DQT, DHT, APP0).
Uint8List stripJpegMetadata(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    return bytes;
  }
  final out = BytesBuilder(copy: false);
  out.add([0xFF, 0xD8]); // SOI

  int offset = 2;
  bool parsedValidSegments = false;
  while (offset < bytes.length) {
    if (bytes[offset] != 0xFF) {
      offset++;
      continue;
    }
    while (offset < bytes.length && bytes[offset] == 0xFF) {
      offset++;
    }
    if (offset >= bytes.length) break;

    final marker = bytes[offset++];
    if (marker == 0xD9) {
      // EOI
      out.add([0xFF, 0xD9]);
      parsedValidSegments = true;
      break;
    }
    if (marker == 0xDA) {
      // SOS (Start of Scan) : tout le reste jusqu'à la fin correspond aux données de l'image
      out.add([0xFF, 0xDA]);
      out.add(bytes.sublist(offset));
      parsedValidSegments = true;
      break;
    }

    if (marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      out.add([0xFF, marker]);
      continue;
    }

    if (offset + 2 > bytes.length) break;
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    if (offset + length > bytes.length) break;

    // Filtre les segments de métadonnées :
    // - 0xE1 : APP1 (Exif, GPS, XMP)
    // - 0xED : APP13 (IPTC, Photoshop)
    // - 0xFE : COM (Commentaires)
    final isMetadata = marker == 0xE1 || marker == 0xED || marker == 0xFE;
    if (!isMetadata) {
      out.add([0xFF, marker]);
      out.add(bytes.sublist(offset, offset + length));
    }
    parsedValidSegments = true;
    offset += length;
  }

  // Si le flux était tronqué ou non conforme, on retourne les octets d'origine sans les corrompre
  if (!parsedValidSegments) {
    return bytes;
  }

  return out.toBytes();
}

/// Assainit les octets JPEG :
/// 1. Si une orientation EXIF non standard (!= 1) est présente, les pixels sont redressés
///    physiquement pour que l'image soit droite sans balise EXIF résiduelle.
/// 2. Si des métadonnées (APP1/GPS/XMP/IPTC/COM) sont détectées mais avec orientation normale,
///    aucun réencodage n'est effectué : les segments sont expurgés de façon sans perte au niveau binaire.
/// 3. Si l'image est déjà exempte de métadonnées et droite, les octets sont retournés tels quels.
Uint8List sanitizeJpeg(Uint8List bytes, {int quality = 80}) {
  final orientation = readExifOrientation(bytes);
  if (orientation != null && orientation != 1) {
    // Redressement physique des pixels via decodeJpg (applique automatiquement l'orientation)
    final decoded = img.decodeJpg(bytes);
    if (decoded != null) {
      decoded.exif.clear();
      final encoded = Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
      return stripJpegMetadata(encoded);
    }
  }

  if (hasExifOrGpsMetadata(bytes)) {
    return stripJpegMetadata(bytes);
  }

  return bytes;
}

/// Vérifie si des métadonnées EXIF, GPS ou IPTC subsistent dans les octets JPEG.
bool hasExifOrGpsMetadata(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return false;
  int offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) {
      offset++;
      continue;
    }
    while (offset < bytes.length && bytes[offset] == 0xFF) {
      offset++;
    }
    if (offset >= bytes.length) break;
    final marker = bytes[offset++];
    if (marker == 0xD9 || marker == 0xDA) break;
    if (marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;

    if (offset + 2 > bytes.length) break;
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    if (marker == 0xE1 || marker == 0xED || marker == 0xFE) {
      return true;
    }
    offset += length;
  }
  return false;
}

/// Extrait les dimensions physiques (largeur, hauteur) des pixels depuis le segment SOF.
(int width, int height)? extractJpegDimensions(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
  int offset = 2;
  while (offset + 4 <= bytes.length) {
    if (bytes[offset] != 0xFF) {
      offset++;
      continue;
    }
    while (offset < bytes.length && bytes[offset] == 0xFF) {
      offset++;
    }
    if (offset >= bytes.length) break;
    final marker = bytes[offset++];
    if (marker == 0xD9 || marker == 0xDA) break;
    if (marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;

    if (offset + 2 > bytes.length) break;
    final length = (bytes[offset] << 8) | bytes[offset + 1];
    // SOF0 (0xC0), SOF1 (0xC1), SOF2 (0xC2)
    if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
      if (offset + 7 <= bytes.length) {
        final h = (bytes[offset + 3] << 8) | bytes[offset + 4];
        final w = (bytes[offset + 5] << 8) | bytes[offset + 6];
        return (w, h);
      }
    }
    offset += length;
  }
  return null;
}
