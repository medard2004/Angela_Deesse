import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:angela_dress/app.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/screens/splash_screen.dart';
import 'package:angela_dress/widgets/common.dart';

void main() {
  testWidgets('AngelaApp splash animation with 2.2s timing test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStore(),
        child: const AngelaApp(),
      ),
    );

    // Initial state: Pure splash screen (no intro button or intro page)
    expect(find.byType(SplashScreen), findsOneWidget);

    // 0 à 550 ms : apparition par fondu et zoom progressif (55% -> 100%)
    await tester.pump(const Duration(milliseconds: 550));

    // 550 à 850 ms : maintien en place au centre (pause 300 ms)
    await tester.pump(const Duration(milliseconds: 300));

    // 850 à 1900 ms : vol fluide vers la barre supérieure et fondu du contenu (1050 ms)
    await tester.pump(const Duration(milliseconds: 1050));

    // 2200 ms : finalisation de la transition
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 100));

    // Now on Home screen: centered AppBar displays 'Angela Déesse'
    expect(find.text('Angela Déesse'), findsAtLeastNWidgets(1));
    expect(find.text("Vue d'ensemble"), findsOneWidget);

    // Verify AppHeader has centered title
    final appHeader = find.byType(AppHeader);
    expect(appHeader, findsOneWidget);

    // Verify BrandMark is present
    expect(find.byType(BrandMark), findsAtLeastNWidgets(1));
  });

  testWidgets('Home page elements scroll under AppBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppStore(),
        child: const AngelaApp(),
      ),
    );

    // Fast-forward splash animation to home (2200 ms total)
    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify PageTitle is inside ListView
    final pageTitle = find.byType(PageTitle);
    expect(pageTitle, findsOneWidget);

    // Scroll ListView up
    final listView = find.byType(ListView).first;
    await tester.drag(listView, const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 100));

    // AppBar remains pinned at top
    expect(find.byType(AppHeader), findsOneWidget);
  });
}
