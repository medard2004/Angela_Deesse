import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:angela_dress/core/app_brand.dart';
import 'package:angela_dress/core/format.dart';
import 'package:angela_dress/data/utils/message_templates.dart';
import 'package:angela_dress/screens/receipt_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });
  group('Partie 0 - AppBrand & Identité Angela Déesse', () {
    test('AppBrand constants are correct', () {
      expect(AppBrand.appName, equals('Angela Déesse'));
      expect(AppBrand.defaultAtelierName, equals('Angela Déesse'));
      expect(AppBrand.technicalPackageName, equals('angela_dress'));
      expect(AppBrand.technicalApplicationId, equals('com.digitalvision.angela_dress'));
    });

    test('formatReceiptNumber non-divergence and formatting', () {
      expect(formatReceiptNumber('CMD', 1), equals('CMD-0001'));
      expect(formatReceiptNumber('APP', 1), equals('APP-0001'));
      expect(formatReceiptNumber('CMD', 42), equals('CMD-0042'));
      expect(formatReceiptNumber('APP', 9999), equals('APP-9999'));
      expect(formatReceiptNumber('CMD', 10000), equals('CMD-10000'));
    });

    test('lib/ sources do not contain forbidden brand variants', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final forbiddenPhrases = [
        'Angela Dress',
        'Angela Couture',
        'Atelier Angela',
      ];

      final violations = <String>[];

      for (final entity in libDir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          for (final phrase in forbiddenPhrases) {
            if (content.contains(phrase)) {
              violations.add('${entity.path}: contains "$phrase"');
            }
          }
        }
      }

      expect(violations, isEmpty,
          reason: 'Forbidden brand variants found in lib/: \n${violations.join('\n')}');
    });

    test('Message templates read default atelier name and custom name properly with "chez"', () {
      final dummyDate = DateTime(2026, 11, 10, 15, 0);

      // With default atelier name
      final readyDefault = MessageTemplates.commandePrete(
        client: 'Amina',
        orderTitle: 'Robe Wax',
        balance: 5000,
        atelier: AppBrand.defaultAtelierName,
      );
      expect(readyDefault, contains('chez Angela Déesse'));

      final reminderDefault = MessageTemplates.rappelEssayage(
        client: 'Amina',
        orderTitle: 'Robe Wax',
        fittingDate: dummyDate,
        atelier: AppBrand.defaultAtelierName,
      );
      expect(reminderDefault, contains('chez Angela Déesse'));

      final deliveryDefault = MessageTemplates.rappelLivraison(
        client: 'Amina',
        orderTitle: 'Robe Wax',
        deliveryDate: dummyDate,
        atelier: AppBrand.defaultAtelierName,
      );
      expect(deliveryDefault, contains('chez Angela Déesse'));

      final balanceDefault = MessageTemplates.rappelSoldeDu(
        client: 'Amina',
        balance: 15000,
        atelier: AppBrand.defaultAtelierName,
      );
      expect(balanceDefault, contains('chez Angela Déesse'));

      final apprenticeDefault = MessageTemplates.echeanceApprenti(
        apprenti: 'Koffi',
        dueDate: dummyDate,
        amount: 25000,
        atelier: AppBrand.defaultAtelierName,
      );
      expect(apprenticeDefault, contains('chez Angela Déesse'));

      final recuDefault = MessageTemplates.recu(
        data: ReceiptData(
          receiptNo: formatReceiptNumber('CMD', 1),
          atelierName: AppBrand.defaultAtelierName,
          title: 'Reçu Commande',
          beneficiaryName: 'Amina',
          beneficiaryRole: 'Client(e)',
          date: dummyDate,
          amountPaid: 10000,
          totalFee: 25000,
          totalPaidToDate: 10000,
          remainingAmount: 15000,
        ),
        atelier: AppBrand.defaultAtelierName,
      );
      expect(recuDefault, contains('Angela Déesse'));

      // With custom atelier name
      final readyCustom = MessageTemplates.commandePrete(
        client: 'Amina',
        orderTitle: 'Robe Wax',
        balance: 5000,
        atelier: 'Atelier Élégance',
      );
      expect(readyCustom, contains('chez Atelier Élégance'));
    });
  });
}
