/// Textes centralisés pour le moteur d'alertes en français.
/// Conçu pour être extrait facilement vers l10n ou un fichier de traduction.
class AlertStrings {
  AlertStrings._();

  // Titres essayages
  static String fittingToday([String? time]) =>
      time != null && time.isNotEmpty ? 'Essayage aujourd\'hui à $time' : 'Essayage aujourd\'hui';

  static String fittingTomorrow([String? time]) =>
      time != null && time.isNotEmpty ? 'Essayage demain à $time' : 'Essayage demain';

  // Titres livraisons
  static const String deliveryOverdue = 'Commande en retard';
  static const String deliveryToday = 'Livraison aujourd\'hui';
  static const String deliveryTomorrow = 'Livraison demain';
  static const String deliveryIn2Days = 'Livraison dans 2 jours';

  // Titres soldes
  static const String pendingBalance = 'Solde en attente';

  // Titres échéances apprentis
  static const String apprenticeOverdue = 'Échéance apprenti dépassée';
  static const String apprenticeToday = 'Échéance apprenti aujourd\'hui';
  static const String apprenticeTomorrow = 'Échéance apprenti demain';
  static String apprenticeInDays(int days) => 'Échéance apprenti dans $days jours';

  // Corps d'alerte (intitulé commande / apprenti + nom, STRICTEMENT AUCUN MONTANT)
  static String orderBody({required String clientName, required String orderTitle}) {
    final name = clientName.trim().isEmpty ? 'Client' : clientName.trim();
    final title = orderTitle.trim().isEmpty ? 'Commande' : orderTitle.trim();
    return '$name · $title';
  }

  static String apprenticeBody({required String apprenticeName}) {
    final name = apprenticeName.trim().isEmpty ? 'Apprenti(e)' : apprenticeName.trim();
    return '$name · Formation';
  }
}
