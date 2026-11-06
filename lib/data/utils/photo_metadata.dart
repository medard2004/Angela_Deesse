import 'package:path/path.dart' as p;

class ResolvedPhotoMetadata {
  final String? hash;
  final String uploadState;

  const ResolvedPhotoMetadata({this.hash, required this.uploadState});
}

/// Impose la règle de cohérence des colonnes photo selon la Décision 4 :
/// - photo_path null ou vide -> hash null, state 'none'
/// - photo_path 'demo:N' -> hash null, state 'none'
/// - photo_path réel (`photos/<hash>.jpg`) -> hash non null, state 'pending' (ou état existant)
ResolvedPhotoMetadata resolvePhotoMetadata(String? photoPath, {String? existingUploadState}) {
  if (photoPath == null || photoPath.trim().isEmpty) {
    return const ResolvedPhotoMetadata(hash: null, uploadState: 'none');
  }

  final trimmed = photoPath.trim();
  if (trimmed.startsWith('demo:')) {
    return const ResolvedPhotoMetadata(hash: null, uploadState: 'none');
  }

  final String hash;
  if (trimmed.startsWith('photos/') && trimmed.endsWith('.jpg')) {
    hash = trimmed.substring(7, trimmed.length - 4);
  } else {
    hash = p.basenameWithoutExtension(trimmed);
  }

  final String state;
  if (existingUploadState != null && existingUploadState != 'none') {
    state = existingUploadState;
  } else {
    state = 'pending';
  }

  return ResolvedPhotoMetadata(hash: hash, uploadState: state);
}
