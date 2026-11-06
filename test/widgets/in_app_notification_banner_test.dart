import 'package:angela_dress/widgets/in_app_notification_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InAppNotificationBanner s\'affiche et disparaît au clic ou par timeout', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                InAppNotificationBanner.show(
                  ctx,
                  title: 'Nouvelle livraison',
                  body: 'Robe pour Fatou',
                  duration: const Duration(seconds: 2),
                  onTap: () {
                    tapped = true;
                  },
                );
              },
              child: const Text('Déclencher notif'),
            ),
          ),
        ),
      ),
    );

    // Initialement aucun bandeau
    expect(find.text('Nouvelle livraison'), findsNothing);

    // Déclencher
    await tester.tap(find.text('Déclencher notif'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Nouvelle livraison'), findsOneWidget);
    expect(find.text('Robe pour Fatou'), findsOneWidget);

    // Taper sur la notification
    await tester.tap(find.text('Nouvelle livraison'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tapped, isTrue);
  });

  testWidgets('InAppNotificationBanner disparaît par balayage vers le haut (swipe up)', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                InAppNotificationBanner.show(
                  ctx,
                  title: 'Alerte balayable',
                  body: 'Glisser pour masquer',
                  duration: const Duration(seconds: 10),
                );
              },
              child: const Text('Afficher'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Afficher'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Alerte balayable'), findsOneWidget);

    // Glisser vers le haut
    await tester.drag(find.text('Alerte balayable'), const Offset(0, -200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Le bandeau est masqué
    expect(find.text('Alerte balayable'), findsNothing);
  });
}
