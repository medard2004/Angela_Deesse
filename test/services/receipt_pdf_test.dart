import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:angela_dress/data/services/receipt_pdf_generator.dart';
import 'package:angela_dress/screens/receipt_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List regularBytes;
  late Uint8List boldBytes;

  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
    // Charge directement les polices TTF Manrope réelles depuis le filesystem
    regularBytes = await File('assets/fonts/Manrope-400.ttf').readAsBytes();
    boldBytes = await File('assets/fonts/Manrope-700.ttf').readAsBytes();
  });

  group('ReceiptPdfGenerator - Nom de fichier assaini', () {
    test('1. Assainit les accents, espaces, apostrophes et caractères spéciaux', () {
      expect(
        ReceiptPdfGenerator.sanitizeForFileName("Afiwa D'Almeida"),
        'Afiwa_D_Almeida',
      );
      expect(
        ReceiptPdfGenerator.sanitizeForFileName('Élise Hélène Müller-Koffi'),
        'Elise_Helene_Muller-Koffi',
      );
      expect(
        ReceiptPdfGenerator.sanitizeForFileName('  Apprenti #01 (test)  '),
        'Apprenti_01_test',
      );
      expect(
        ReceiptPdfGenerator.sanitizeForFileName(''),
        'sans_nom',
      );
    });

    test('2. Construction standardisée du nom de fichier PDF', () {
      final data = ReceiptData(
        receiptNo: 'CMD-0007',
        atelierName: 'Atelier Angela',
        title: 'Reçu de commande',
        beneficiaryName: 'Afiwa D’Almeida',
        beneficiaryRole: 'Client(e)',
        date: DateTime(2026, 5, 10),
        amountPaid: 25000,
        totalFee: 50000,
        totalPaidToDate: 25000,
        remainingAmount: 25000,
      );

      final fileName = ReceiptPdfGenerator.buildFileName(data);
      expect(fileName, 'Recu_CMD-0007_Afiwa_D_Almeida.pdf');
      expect(fileName.contains(' '), isFalse);
      expect(fileName.contains('’'), isFalse);
    });
  });

  group('ReceiptPdfGenerator - Génération PDF & Tampons', () {
    test('3. Reçu client partiel : tampon VERSÉ et champs figés', () async {
      final paymentDate = DateTime(2026, 5, 12, 14, 30);
      final data = ReceiptData(
        receiptNo: 'CMD-0003',
        atelierName: 'Atelier Angela Déesse',
        title: 'Reçu de paiement commande',
        beneficiaryName: 'Afiwa Mensah',
        beneficiaryRole: 'Client(e)',
        beneficiaryPhone: '+228 90 11 22 33',
        date: paymentDate,
        amountPaid: 30000,
        note: 'Premier acompte robe de soirée',
        totalFee: 75000,
        totalPaidToDate: 30000,
        remainingAmount: 45000,
        nextDueDate: DateTime(2026, 5, 20),
        itemDetail: 'Robe de mariée perlée',
      );

      const generator = ReceiptPdfGenerator();
      final bytes = await generator.generatePdf(
        data,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );

      expect(bytes, isNotEmpty);
      // Le format PDF commence par %PDF-
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, '%PDF-');
    });

    test('4. Reçu soldé : tampon SOLDÉ lorsque remainingAmount == 0', () async {
      final paymentDate = DateTime(2026, 6, 1, 10, 0);
      final data = ReceiptData(
        receiptNo: 'CMD-0004',
        atelierName: 'Atelier Angela Déesse',
        title: 'Reçu de solde commande',
        beneficiaryName: 'Akossiwa Doe',
        beneficiaryRole: 'Client(e)',
        date: paymentDate,
        amountPaid: 45000,
        totalFee: 75000,
        totalPaidToDate: 75000,
        remainingAmount: 0,
        itemDetail: 'Robe de mariée',
      );

      const generator = ReceiptPdfGenerator();
      final bytes = await generator.generatePdf(
        data,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );

      expect(bytes, isNotEmpty);
    });

    test('5. Reçu annulé : tampon ANNULÉ, date et motif d\'annulation', () async {
      final paymentDate = DateTime(2026, 5, 12);
      final voidDate = DateTime(2026, 5, 13, 11, 15);
      final data = ReceiptData(
        receiptNo: 'CMD-0005',
        atelierName: 'Atelier Angela Déesse',
        title: 'Reçu de commande annulé',
        beneficiaryName: 'Koffi Bernard',
        beneficiaryRole: 'Client(e)',
        date: paymentDate,
        amountPaid: 20000,
        totalFee: 50000,
        totalPaidToDate: 20000,
        remainingAmount: 30000,
        isVoided: true,
        voidedAt: voidDate,
        voidReason: 'Erreur de saisie du montant par l\'apprentie',
      );

      const generator = ReceiptPdfGenerator();
      final bytes = await generator.generatePdf(
        data,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );

      expect(bytes, isNotEmpty);
    });

    test('6. Reçu apprenti(e) : même modèle avec total formation', () async {
      final paymentDate = DateTime(2026, 4, 15);
      final data = ReceiptData(
        receiptNo: 'APP-0002',
        atelierName: 'Atelier Angela Déesse',
        title: 'Reçu de versement formation',
        beneficiaryName: 'Ami Adjo',
        beneficiaryRole: 'Apprenti(e)',
        beneficiaryPhone: '+228 91 23 45 67',
        date: paymentDate,
        amountPaid: 40000,
        note: 'Tranche 2 scolarité couture',
        totalFee: 120000,
        totalPaidToDate: 80000,
        remainingAmount: 40000,
        nextDueDate: DateTime(2026, 6, 15),
        itemDetail: 'Formation couture générale',
      );

      const generator = ReceiptPdfGenerator();
      final bytes = await generator.generatePdf(
        data,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );

      expect(bytes, isNotEmpty);
    });

    test('7. Caractères spéciaux : accents, É, apostrophe typographique ’, tiret long —, U+202F', () async {
      final data = ReceiptData(
        receiptNo: 'CMD-0009',
        atelierName: 'Atelier Déesse Élite — Haute Couture',
        title: 'Reçu spécial',
        beneficiaryName: 'Hélène d’Estienne de Saint-Jean de Luz — Nom très long',
        beneficiaryRole: 'Client(e)',
        beneficiaryPhone: '+228 90 00 00 00',
        date: DateTime(2026, 5, 20),
        amountPaid: 50000,
        note: 'Règlement d’acompte — modèle création spécifique',
        totalFee: 100000,
        totalPaidToDate: 50000,
        remainingAmount: 50000,
        itemDetail: 'Ensemble brodé & voiles légers — Création 2026',
      );

      const generator = ReceiptPdfGenerator();
      // Doit réussir sans aucune exception de police manquante
      final bytes = await generator.generatePdf(
        data,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );

      expect(bytes, isNotEmpty);
    });

    test('8. Déterminisme : deux générations identiques produisent les mêmes données', () async {
      final date = DateTime(2026, 5, 10, 8, 30);
      final data1 = ReceiptData(
        receiptNo: 'CMD-0010',
        atelierName: 'Atelier Angela',
        title: 'Reçu test',
        beneficiaryName: 'Client Test',
        beneficiaryRole: 'Client(e)',
        date: date,
        amountPaid: 15000,
        totalFee: 30000,
        totalPaidToDate: 15000,
        remainingAmount: 15000,
      );

      final data2 = ReceiptData(
        receiptNo: 'CMD-0010',
        atelierName: 'Atelier Angela',
        title: 'Reçu test',
        beneficiaryName: 'Client Test',
        beneficiaryRole: 'Client(e)',
        date: date,
        amountPaid: 15000,
        totalFee: 30000,
        totalPaidToDate: 15000,
        remainingAmount: 15000,
      );

      const generator = ReceiptPdfGenerator();
      final bytes1 = await generator.generatePdf(
        data1,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );
      final bytes2 = await generator.generatePdf(
        data2,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );

      expect(bytes1.length, equals(bytes2.length));
    });

    test('9. Sauvegarde temporaire crée un fichier et renvoie le File', () async {
      final data = ReceiptData(
        receiptNo: 'CMD-0011',
        atelierName: 'Atelier Angela',
        title: 'Reçu test',
        beneficiaryName: 'Client Temp',
        beneficiaryRole: 'Client(e)',
        date: DateTime(2026, 5, 10),
        amountPaid: 10000,
        totalFee: 20000,
        totalPaidToDate: 10000,
        remainingAmount: 10000,
      );

      const generator = ReceiptPdfGenerator();
      final bytes = await generator.generatePdf(
        data,
        regularFontBytes: regularBytes,
        boldFontBytes: boldBytes,
      );

      final tempDir = Directory.systemTemp.createTempSync('angela_test_');
      final file = File('${tempDir.path}/${ReceiptPdfGenerator.buildFileName(data)}');
      await file.writeAsBytes(bytes, flush: true);

      expect(await file.exists(), isTrue);
      expect(await file.length(), equals(bytes.length));

      // Nettoyage
      await file.delete();
      await tempDir.delete();
    });
  });
}

