import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:angela_dress/core/theme.dart';
import 'package:angela_dress/data/models.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/screens/receipt_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });
  group('Apprentice installments and payment calculations', () {
    test('Calculates payments, remaining balances, and progressive installments', () async {
      final store = AppStore();
      final app = Apprentice(
        id: 'test_app_1',
        name: 'Test Apprentice',
        startDate: DateTime.now(),
        totalFee: 150000,
      );
      await store.saveApprentice(app);

      // Initially no payments
      expect(store.apprenticePaid(app), 0);
      expect(store.apprenticeRemaining(app), 150000);

      // First installment of 80 000 FCFA
      final p1 = await store.addApprenticePayment(app.id, 80000, 'Premier acompte');
      expect(p1.amount, 80000);
      expect(store.apprenticePaid(app), 80000);
      expect(store.apprenticeRemaining(app), 70000);

      // Second installment 1 month later of 50 000 FCFA
      final p2 = await store.addApprenticePayment(app.id, 50000, 'Deuxième versement');
      expect(p2.amount, 50000);
      expect(store.apprenticePaid(app), 130000);
      expect(store.apprenticeRemaining(app), 20000);

      // Final installment of 20 000 FCFA -> Soldé
      await store.addApprenticePayment(app.id, 20000, 'Solde');
      expect(store.apprenticePaid(app), 150000);
      expect(store.apprenticeRemaining(app), 0);
    });
  });

  group('ReceiptScreen animation sequence', () {
    testWidgets('Validates 5250ms animation sequence, guide, stamp, and action buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final data = ReceiptData(
        receiptNo: '0042',
        atelierName: 'Angela Couture',
        title: 'Reçu de versement',
        beneficiaryName: 'Afi Mensah',
        beneficiaryRole: 'Apprenti(e)',
        beneficiaryPhone: '90 12 34 56',
        date: DateTime.now(),
        amountPaid: 80000,
        note: 'Acompte formation',
        totalFee: 150000,
        totalPaidToDate: 80000,
        remainingAmount: 70000,
        stampText: 'VERSÉ',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(),
          home: ReceiptScreen(data: data),
        ),
      );

      // T0: ouverture de l'écran
      expect(find.text('Reçu de versement'), findsOneWidget);
      expect(find.text('Impression du reçu...'), findsOneWidget);

      // T = 500 ms (pendant la pause 300 -> 1050 ms)
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Impression du reçu...'), findsOneWidget);

      // T = 2500 ms (pendant la sortie du papier 1050 -> 3950 ms)
      await tester.pump(const Duration(milliseconds: 2000));
      expect(find.textContaining('80'), findsAtLeastNWidgets(1));

      // T = 4100 ms (papier immobile et sorti)
      await tester.pump(const Duration(milliseconds: 1600));

      // T = 4600 ms (après écrasement du tampon 4250 -> 4550 ms)
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('VERSÉ'), findsOneWidget);

      // T = 5300 ms (après échange des indicateurs 4750 -> 5200 ms)
      await tester.pump(const Duration(milliseconds: 700));

      // Les deux boutons d'action sont affichés
      expect(find.text('Télécharger'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);

      // Tester l'action Télécharger
      await tester.tap(find.text('Télécharger'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tester l'action WhatsApp
      await tester.tap(find.text('WhatsApp'));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
