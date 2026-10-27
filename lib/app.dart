import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

class AngelaApp extends StatelessWidget {
  const AngelaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Angela Déesse',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('fr'),
        supportedLocales: const [Locale('fr')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      );
}
