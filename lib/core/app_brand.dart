/// Référence d'identité unique pour l'application Angela Déesse.
/// Centralise les constantes de marque statiques et la valeur par défaut
/// du nom d'atelier sans jamais figer de texte dynamique dans l'interface.
class AppBrand {
  AppBrand._();

  /// Nom officiel de l'application pour les contextes statiques
  /// (titre MaterialApp, métadonnées, manifestes, documentation).
  static const String appName = 'Angela Déesse';

  /// Nom d'atelier par défaut utilisé lorsque la table settings ne contient
  /// aucune valeur personnalisée (clé 'atelier_name').
  static const String defaultAtelierName = 'Angela Déesse';

  /// Identifiant technique Android / Dart préservé intentionnellement.
  static const String technicalPackageName = 'angela_dress';
  static const String technicalApplicationId = 'com.digitalvision.angela_dress';
}
