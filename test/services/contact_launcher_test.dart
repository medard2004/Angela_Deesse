import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:angela_dress/data/services/contact_launcher.dart';
import 'package:angela_dress/data/services/external_action_tracker.dart';
import 'package:angela_dress/data/utils/message_templates.dart';
import 'package:angela_dress/data/utils/phone_normalizer.dart';
import 'package:angela_dress/screens/receipt_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('Partie B - Normalisation téléphonique, ContactLauncher & MessageTemplates', () {
    test('1. Normalisation téléphonique : tableau exhaustif de cas', () {
      // 1.1 Espaces, tirets, points, parenthèses avec indicatif par défaut (228 Togo)
      final r1 = normalizePhoneNumber('90 12 34 56');
      expect(r1.isValid, isTrue);
      expect(r1.e164, equals('+22890123456'));
      expect(r1.digitsOnly, equals('22890123456'));

      final r2 = normalizePhoneNumber('(90)-12.34.56');
      expect(r2.isValid, isTrue);
      expect(r2.e164, equals('+22890123456'));

      // 1.2 Avec "+" initial conservé
      final r3 = normalizePhoneNumber('+33 6 12 34 56 78');
      expect(r3.isValid, isTrue);
      expect(r3.e164, equals('+33612345678'));
      expect(r3.digitsOnly, equals('33612345678'));

      // 1.3 Avec "00" initial -> converti en "+"
      final r4 = normalizePhoneNumber('0033 6 12 34 56 78');
      expect(r4.isValid, isTrue);
      expect(r4.e164, equals('+33612345678'));

      // 1.4 Indicatif par défaut paramétrable (ex: 229 Bénin)
      final r5 = normalizePhoneNumber('97 00 11 22', defaultCountryCode: '229');
      expect(r5.isValid, isTrue);
      expect(r5.e164, equals('+22997001122'));

      // 1.5 Zéro initial conservé (ne jamais supprimer un 0 initial)
      final r6 = normalizePhoneNumber('090 12 34 56');
      expect(r6.isValid, isTrue);
      expect(r6.e164, equals('+228090123456'));
      expect(r6.digitsOnly, equals('228090123456'));

      // 1.6 Trop court (< 7 chiffres au total)
      final r7 = normalizePhoneNumber('123'); // 228123 = 6 chiffres
      expect(r7.isValid, isFalse);
      expect(r7.error, equals('Numéro invalide'));

      // 1.7 Trop long (> 15 chiffres au total)
      final r8 = normalizePhoneNumber('+1234567890123456'); // 16 chiffres
      expect(r8.isValid, isFalse);
      expect(r8.error, equals('Numéro invalide'));

      // 1.8 Contient des lettres ou caractères invalides
      final r9 = normalizePhoneNumber('90abc1234');
      expect(r9.isValid, isFalse);
      expect(r9.error, equals('Numéro invalide'));

      // 1.9 Vide, espaces ou null
      final r10 = normalizePhoneNumber('');
      expect(r10.isValid, isFalse);
      expect(r10.error, equals('Aucun numéro enregistré'));

      final r11 = normalizePhoneNumber('   ');
      expect(r11.isValid, isFalse);
      expect(r11.error, equals('Aucun numéro enregistré'));

      final r12 = normalizePhoneNumber(null);
      expect(r12.isValid, isFalse);
      expect(r12.error, equals('Aucun numéro enregistré'));
    });

    test('2. URLs construites (wa.me, sms, tel) avec encodage complet des accents, apostrophes et retours chariot', () async {
      Uri? launchedUri;
      LaunchMode? launchedMode;

      final launcher = DefaultContactLauncher(
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          launchedUri = uri;
          launchedMode = mode;
          return true;
        },
        getDefaultCountryCode: () => '228',
      );

      // 2.1 Appel téléphonique (tel:)
      final callRes = await launcher.call('90 12 34 56');
      expect(callRes.success, isTrue);
      expect(launchedUri, isNotNull);
      expect(launchedUri!.scheme, equals('tel'));
      expect(launchedUri!.path, equals('+22890123456'));
      expect(launchedMode, equals(LaunchMode.externalApplication));

      // 2.2 WhatsApp (https://wa.me/<digits>?text=...)
      const textComplex = 'Bonjour Jean & Marie,\nVotre modèle « Robe Déesse » est prêt ! Coût : 25 000 FCFA.';
      final waRes = await launcher.whatsapp('90 12 34 56', body: textComplex);
      expect(waRes.success, isTrue);
      expect(launchedUri!.scheme, equals('https'));
      expect(launchedUri!.host, equals('wa.me'));
      expect(launchedUri!.path, equals('/22890123456'));
      expect(launchedUri!.queryParameters['text'], equals(textComplex));

      // 2.3 SMS
      final smsRes = await launcher.sms('90 12 34 56', body: 'Rappel d\'essayage prévu & confirmé.');
      expect(smsRes.success, isTrue);
      expect(launchedUri!.scheme, equals('sms'));
      expect(launchedUri!.path, equals('+22890123456'));
    });

    test('3. Modèles de messages pré-remplis (MessageTemplates) : contenu exact, montants FCFA, aucune civilité', () {
      // 3.1 Commande prête
      final msgPrete = MessageTemplates.commandePrete(
        client: 'Afiwa',
        orderTitle: 'Boubou Bazin',
        balance: 15000,
        atelier: 'Atelier Angela',
      );
      expect(msgPrete, contains('Bonjour Afiwa, votre commande « Boubou Bazin » est prête à l\'atelier Atelier Angela.'));
      expect(msgPrete, contains('Reste à payer : 15 000 FCFA.'));
      expect(msgPrete, isNot(contains('Mme')));

      // Commande prête soldée (solde 0)
      final msgPreteSolde = MessageTemplates.commandePrete(
        client: 'Koffi',
        orderTitle: 'Veste Wax',
        balance: 0,
        atelier: 'Atelier Angela',
      );
      expect(msgPreteSolde, isNot(contains('Reste à payer')));

      // 3.2 Rappel d'essayage
      final msgEssayage = MessageTemplates.rappelEssayage(
        client: 'Akossiwa',
        orderTitle: 'Robe Cérémonie',
        fittingDate: DateTime.utc(2026, 11, 15, 14, 30),
        atelier: 'Atelier Angela',
      );
      expect(msgEssayage, contains('Bonjour Akossiwa, nous vous rappelons votre séance d\'essayage pour la commande « Robe Cérémonie »'));
      expect(msgEssayage, contains('Atelier Angela'));
      expect(msgEssayage, isNot(contains('Mme')));

      // 3.3 Rappel de livraison
      final msgLivraison = MessageTemplates.rappelLivraison(
        client: 'Mawussi',
        orderTitle: 'Ensemble Pagne',
        deliveryDate: DateTime.utc(2026, 11, 20),
        atelier: 'Atelier Angela',
      );
      expect(msgLivraison, contains('Bonjour Mawussi, la livraison de votre commande « Ensemble Pagne » est prévue'));
      expect(msgLivraison, contains('Atelier Angela'));

      // 3.4 Rappel de solde dû
      final msgSolde = MessageTemplates.rappelSoldeDu(
        client: 'Edem',
        balance: 35000,
        atelier: 'Atelier Angela',
      );
      expect(msgSolde, contains('Bonjour Edem, rappel concernant votre solde restant de 35 000 FCFA à l\'atelier Atelier Angela.'));

      // 3.5 Échéance apprenti
      final msgApprenti = MessageTemplates.echeanceApprenti(
        apprenti: 'Yao',
        dueDate: DateTime.utc(2026, 12, 1),
        amount: 20000,
        atelier: 'Atelier Angela',
      );
      expect(msgApprenti, contains('Bonjour Yao, rappel concernant votre prochaine échéance de formation fixée au'));
      expect(msgApprenti, contains('Montant restant : 20 000 FCFA.'));

      // 3.6 Reçu récapitulatif avec valeurs FIGÉES
      final receiptData = ReceiptData(
        receiptNo: 'CMD-0042',
        atelierName: 'Atelier Angela',
        title: 'Reçu de paiement',
        beneficiaryName: 'Dzifa Ayivi',
        beneficiaryRole: 'Client(e)',
        date: DateTime.utc(2026, 11, 6, 10, 0),
        amountPaid: 25000,
        totalFee: 50000,
        totalPaidToDate: 25000,
        remainingAmount: 25000,
        stampText: 'VERSÉ',
      );
      final msgRecu = MessageTemplates.recu(data: receiptData, atelier: 'Atelier Angela');
      expect(msgRecu, contains('Reçu N° CMD-0042 - Atelier Angela'));
      expect(msgRecu, contains('Bénéficiaire : Dzifa Ayivi'));
      expect(msgRecu, contains('Montant versé : 25 000 FCFA'));
      expect(msgRecu, contains('Reste à payer : 25 000 FCFA'));
      expect(msgRecu, contains('Statut : VERSÉ'));
    });

    test('4. Échec du lancement externe (false ou exception) -> message clair, aucun crash', () async {
      // Cas 4.1 : Le launcher renvoie false
      final launcherFalse = DefaultContactLauncher(
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async => false,
      );
      final resFalse = await launcherFalse.whatsapp('90 12 34 56');
      expect(resFalse.success, isFalse);
      expect(resFalse.errorMessage, equals('Impossible d\'ouvrir WhatsApp'));

      // Cas 4.2 : Le launcher lève une exception
      final launcherException = DefaultContactLauncher(
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async =>
            throw Exception('Activité introuvable'),
      );
      final resException = await launcherException.call('90 12 34 56');
      expect(resException.success, isFalse);
      expect(resException.errorMessage, equals('Impossible de passer l\'appel'));
    });

    test('5. ExternalActionTracker : runExternal trace le début et la fin de l\'action externe', () async {
      final tracker = ExternalActionTracker();
      expect(tracker.isActive, isFalse);
      expect(tracker.lastExternalActionCompletedAt, isNull);

      final launcher = DefaultContactLauncher(
        tracker: tracker,
        launcher: (uri, {LaunchMode mode = LaunchMode.platformDefault}) async {
          expect(tracker.isActive, isTrue); // actif pendant l'exécution
          return true;
        },
      );

      final res = await launcher.sms('90 12 34 56');
      expect(res.success, isTrue);
      expect(tracker.isActive, isFalse);
      expect(tracker.lastExternalActionCompletedAt, isNotNull);
    });
  });
}
