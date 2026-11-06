import '../../core/format.dart';
import '../../screens/receipt_screen.dart';

/// Générateur pur de messages pré-remplis en français pour les actions WhatsApp et SMS.
/// Règle stricte : aucune civilité supposée (« Bonjour {nom}, … », pas de « Mme »),
/// montants formatés en FCFA, valeurs issues des réglages et de l'état figé.
class MessageTemplates {
  MessageTemplates._();

  /// Modèle 1 : Commande prête
  static String commandePrete({
    required String client,
    required String orderTitle,
    required int balance,
    required String atelier,
  }) {
    final soldeClause =
        balance > 0 ? ' Reste à payer : ${fcfa(balance)}.' : '';
    return 'Bonjour $client, votre commande « $orderTitle » est prête à l\'atelier $atelier.$soldeClause À bientôt !';
  }

  /// Modèle 2 : Rappel d'essayage
  static String rappelEssayage({
    required String client,
    required String orderTitle,
    required DateTime fittingDate,
    required String atelier,
  }) {
    return 'Bonjour $client, nous vous rappelons votre séance d\'essayage pour la commande « $orderTitle » prévue le ${fmtDate(fittingDate)} à l\'atelier $atelier. À bientôt !';
  }

  /// Modèle 3 : Rappel de livraison
  static String rappelLivraison({
    required String client,
    required String orderTitle,
    required DateTime deliveryDate,
    required String atelier,
  }) {
    return 'Bonjour $client, la livraison de votre commande « $orderTitle » est prévue le ${fmtDate(deliveryDate)} à l\'atelier $atelier. À bientôt !';
  }

  /// Modèle 4 : Rappel de solde dû
  static String rappelSoldeDu({
    required String client,
    required int balance,
    required String atelier,
  }) {
    return 'Bonjour $client, rappel concernant votre solde restant de ${fcfa(balance)} à l\'atelier $atelier. Merci de votre confiance !';
  }

  /// Modèle 5 : Rappel d'échéance d'apprenti
  static String echeanceApprenti({
    required String apprenti,
    required DateTime dueDate,
    required int amount,
    required String atelier,
  }) {
    final soldeClause =
        amount > 0 ? ' Montant restant : ${fcfa(amount)}.' : '';
    return 'Bonjour $apprenti, rappel concernant votre prochaine échéance de formation fixée au ${fmtDate(dueDate)}.$soldeClause Atelier $atelier.';
  }

  /// Modèle 6 : Reçu (récapitulatif texte avec valeurs FIGÉES du reçu)
  static String recu({
    required ReceiptData data,
    required String atelier,
  }) {
    final lines = [
      'Reçu N° ${data.receiptNo} - $atelier',
      'Bénéficiaire : ${data.beneficiaryName}',
      'Date : ${fmtDate(data.date)}',
      'Montant versé : ${fcfa(data.amountPaid)}',
      'Reste à payer : ${fcfa(data.remainingAmount)}',
      'Statut : ${data.stampText}',
      'Merci pour votre confiance !',
    ];
    return lines.join('\n');
  }
}
