import 'package:flutter/material.dart';
import 'motion.dart';
import '../data/models.dart';

/// Palette Miva Couture - Identité visuelle & couture africaine moderne.
/// Aucun bleu, aucun orange vif.
/// Palette inspirée du Bogolan, de la terre cuite, de l'ocre et du coton naturel.
class Pal {
  // Couleurs principales
  static const Color terreBogolan = Color(0xFF4A2E1B); // Texte principal, boutons principaux
  static const Color brunNuit = Color(0xFF3A2314);     // Mode sombre & surfaces profondes
  static const Color ocre = Color(0xFFC98A2B);         // Accent, élément actif
  static const Color terreRouge = Color(0xFF9C4A2A);   // Essayage & touches chaudes
  static const Color rougeBrique = Color(0xFFB3362B);  // Cachet officiel & alertes
  static const Color cremeCoton = Color(0xFFEAD9B8);   // Crème doux & surlignages
  static const Color fondClair = Color(0xFFFAF6EC);    // Fond clair de l'application
  static const Color blanc = Color(0xFFFFFFFF);        // Blocs blancs
  static const Color bordure = Color(0xFFE7DCC3);      // Bordures raffinées

  // Statuts normalisés (identiques partout)
  static const Color statutAttenteFg = Color(0xFF6E5D53); // gris-brun
  static const Color statutAttenteBg = Color(0xFFF0EBE7);

  static const Color statutCoursFg = Color(0xFFC98A2B);   // ocre
  static const Color statutCoursBg = Color(0xFFFBF4E8);

  static const Color statutEssayageFg = Color(0xFF9C4A2A);// terre rouge
  static const Color statutEssayageBg = Color(0xFFF9ECE7);

  static const Color statutPreteFg = Color(0xFF0E5A3A);   // vert profond
  static const Color statutPreteBg = Color(0xFFE3F1EA);

  static const Color statutLivreeFg = Color(0xFF8A6D58);  // brun clair
  static const Color statutLivreeBg = Color(0xFFF4EEEA);

  static const Color statutAlerteFg = Color(0xFFB3362B);  // rouge brique (retard ou impayé)
  static const Color statutAlerteBg = Color(0xFFFCEAE8);

  // Mode sombre (Brun Nuit)
  static const Color sombreFond = Color(0xFF26170D);
  static const Color sombreSurface = Color(0xFF351F11);
  static const Color sombreSurfaceElevated = Color(0xFF472C19);
  static const Color sombreBordure = Color(0xFF5D3B24);
  static const Color sombreTexte = Color(0xFFFAF6EC);
  static const Color sombreTexteSecondaire = Color(0xFFD8C5A8);

  // Aliases pour compatibilité totale avec les écrans existants
  static const Color ink = terreBogolan;
  static const Color indigo = terreBogolan;
  static const Color cobalt = terreBogolan;
  static const Color cobaltLight = terreBogolan;
  static const Color cobaltDark = brunNuit;
  static const Color orange = ocre;
  static const Color amber = ocre;
  static const Color tape = ocre;
  static const Color chalk = fondClair;
  static const Color slate = Color(0xFF7E6A5B);
  static const Color eyebrow = ocre;
  static const Color line = bordure;
  static const Color thread = statutAlerteFg;
  static const Color sage = statutPreteFg;

  // Dégradés doux / aplats chaleureux
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [terreBogolan, brunNuit],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ocre, Color(0xFFB47A22)],
  );

  static const LinearGradient cobaltGradient = primaryGradient;
  static const LinearGradient orangeGradient = accentGradient;
}

/// Helper dynamique qui s'adapte automatiquement au Mode Sombre / Mode Clair
class AppColors {
  final BuildContext context;
  const AppColors(this.context);

  static AppColors of(BuildContext context) => AppColors(context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get background => isDark ? Pal.sombreFond : Pal.fondClair;
  Color get surface => isDark ? Pal.sombreSurface : Pal.blanc;
  Color get surfaceElevated => isDark ? Pal.sombreSurfaceElevated : Pal.blanc;
  Color get textPrimary => isDark ? Pal.sombreTexte : Pal.terreBogolan;
  Color get textSecondary => isDark ? Pal.sombreTexteSecondaire : Pal.slate;
  Color get border => isDark ? Pal.sombreBordure : Pal.bordure;
  Color get accent => Pal.ocre;
  Color get primary => Pal.terreBogolan;
  Color get tagBg => isDark ? Pal.sombreSurfaceElevated : Pal.cremeCoton.withAlpha(140);
}

/// Helper pour obtenir les couleurs normalisées d'un statut
class StatusVisuals {
  final Color background;
  final Color foreground;
  final String label;

  const StatusVisuals({
    required this.background,
    required this.foreground,
    required this.label,
  });

  static StatusVisuals of(OrderStatus status, {bool isLate = false}) {
    if (isLate) {
      return const StatusVisuals(
        background: Pal.statutAlerteBg,
        foreground: Pal.statutAlerteFg,
        label: 'En retard',
      );
    }
    return switch (status) {
      OrderStatus.attente => const StatusVisuals(
          background: Pal.statutAttenteBg,
          foreground: Pal.statutAttenteFg,
          label: 'En attente',
        ),
      OrderStatus.cours => const StatusVisuals(
          background: Pal.statutCoursBg,
          foreground: Pal.statutCoursFg,
          label: 'En cours',
        ),
      OrderStatus.essayage => const StatusVisuals(
          background: Pal.statutEssayageBg,
          foreground: Pal.statutEssayageFg,
          label: 'En essayage',
        ),
      OrderStatus.prete => const StatusVisuals(
          background: Pal.statutPreteBg,
          foreground: Pal.statutPreteFg,
          label: 'Prête',
        ),
      OrderStatus.livree => const StatusVisuals(
          background: Pal.statutLivreeBg,
          foreground: Pal.statutLivreeFg,
          label: 'Livrée',
        ),
    };
  }
}

/// Style épuré : coins arrondis de 12 px, peu d'ombres
const double kAppRadius = 12.0;
final BorderRadius kBorderRadius = BorderRadius.circular(kAppRadius);

List<BoxShadow> softShadow([int alpha = 10]) => [
      BoxShadow(
        color: Pal.brunNuit.withAlpha(alpha),
        blurRadius: 8,
        offset: const Offset(0, 2),
      )
    ];

/// Frise géométrique Bogolan africaine discrète
class AfricanPatternDivider extends StatelessWidget {
  const AfricanPatternDivider({super.key, this.height = 12, this.opacity = 0.5});
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(12, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.rotate(
                angle: 0.785398, // 45 deg
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: index.isEven ? Pal.ocre : colors.border,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Typographie & Thèmes Miva Couture
ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;
  final background = isDark ? Pal.sombreFond : Pal.fondClair;
  final surface = isDark ? Pal.sombreSurface : Pal.blanc;
  final textPrimary = isDark ? Pal.sombreTexte : Pal.terreBogolan;
  final textSecondary = isDark ? Pal.sombreTexteSecondaire : Pal.slate;
  final borderColor = isDark ? Pal.sombreBordure : Pal.bordure;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: Pal.terreBogolan,
    onPrimary: Pal.cremeCoton,
    secondary: Pal.ocre,
    onSecondary: Pal.blanc,
    error: Pal.statutAlerteFg,
    onError: Pal.blanc,
    surface: surface,
    onSurface: textPrimary,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Public Sans',
    scaffoldBackgroundColor: background,
  );

  return base.copyWith(
    cardColor: surface,
    dividerColor: borderColor,
    textTheme: base.textTheme.apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
      fontFamily: 'Public Sans',
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Pal.terreBogolan,
        foregroundColor: Pal.cremeCoton,
        minimumSize: const Size(0, 46),
        textStyle: const TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        minimumSize: const Size(0, 46),
        side: BorderSide(color: borderColor),
        textStyle: const TextStyle(
          fontFamily: 'Public Sans',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: kBorderRadius,
        borderSide: const BorderSide(color: Pal.ocre, width: 1.5),
      ),
      labelStyle: TextStyle(color: textSecondary, fontSize: 13.5),
      floatingLabelStyle: const TextStyle(
        color: Pal.ocre,
        fontWeight: FontWeight.w700,
        fontSize: 13,
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: kBorderRadius),
    ),
  );
}
