import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:angela_dress/data/db/app_database.dart';
import 'package:angela_dress/data/store.dart';
import 'package:angela_dress/screens/settings_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  testWidgets('Renommer atelier depuis SettingsScreen ne lève aucune assertion', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = AppStore(db: db);
    await store.init(seedDemo: false);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppStore>.value(
        value: store,
        child: MaterialApp(
          home: SettingsScreen(onMenu: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cliquer sur le bouton renommer
    expect(find.byTooltip('Renommer'), findsOneWidget);
    await tester.tap(find.byTooltip('Renommer'));
    await tester.pumpAndSettle();

    // Vérifier que le dialogue est ouvert
    expect(find.text("Nom de l'atelier"), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);

    // Modifier le texte
    await tester.enterText(find.byType(TextField), 'Nouvel Atelier Déesse');
    await tester.pump();

    // Cliquer sur Enregistrer
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    // Vérifier que le nom est bien mis à jour
    expect(store.atelierName, 'Nouvel Atelier Déesse');
  });
}
