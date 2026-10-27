import 'package:flutter/material.dart';
import 'motion.dart';

/// Palette de la maquette Angela Dress : bleu cobalt + orange, encre marine pour le texte.
class Pal {
  static const ink = Color(0xFF0F1B3D);
  static const indigo = ink; // alias historique (texte et surfaces sombres)
  static const cobalt = Color(0xFF1747B8);
  static const cobaltLight = Color(0xFF2A66E0);
  static const cobaltDark = Color(0xFF0A2A7A);
  static const orange = Color(0xFFFF8A1F);
  static const amber = Color(0xFFFFB020);
  static const tape = orange; // alias historique (accent)
  static const chalk = Color(0xFFF4F6FC); // fond des écrans
  static const slate = Color(0xFF8790AB); // texte secondaire
  static const eyebrow = Color(0xFF5B6FA6);
  static const line = Color(0xFFE5E9F5);
  static const thread = Color(0xFFD64550); // retard / reste à payer
  static const sage = Color(0xFF2F8F6B);

  static const cobaltGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF2563D9), Color(0xFF0B2F8F)],
  );
  static const orangeGradient = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFFFB020), Color(0xFFFF6A1A)],
  );
}

List<BoxShadow> softShadow([int alpha = 26]) =>
    [BoxShadow(color: Pal.cobalt.withAlpha(alpha), blurRadius: 28, offset: const Offset(0, 10))];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Pal.cobalt).copyWith(
    primary: Pal.cobalt, onPrimary: Colors.white,
    secondary: Pal.orange, onSecondary: Colors.white,
    surface: Colors.white, error: Pal.thread,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Manrope');
  return base.copyWith(
    scaffoldBackgroundColor: Pal.chalk,
    textTheme: base.textTheme.apply(bodyColor: Pal.ink, displayColor: Pal.ink, fontFamily: 'Manrope'),
    appBarTheme: const AppBarTheme(
      backgroundColor: Pal.chalk, foregroundColor: Pal.ink, elevation: 0, scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Manrope', fontSize: 16, fontWeight: FontWeight.w700, color: Pal.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Pal.cobalt, foregroundColor: Colors.white, minimumSize: const Size(0, 46),
        textStyle: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Pal.cobalt, minimumSize: const Size(0, 46), side: const BorderSide(color: Pal.line),
        textStyle: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadePageTransitionsBuilder(),
        TargetPlatform.iOS: FadePageTransitionsBuilder(),
        TargetPlatform.windows: FadePageTransitionsBuilder(),
        TargetPlatform.macOS: FadePageTransitionsBuilder(),
        TargetPlatform.linux: FadePageTransitionsBuilder(),
      },
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
