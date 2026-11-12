import 'package:flutter/material.dart';
import '../core/format.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../data/models.dart';

Future<T?> push<T>(BuildContext c, Widget w) =>
    Navigator.of(c).push<T>(FadePageRoute<T>(builder: (_) => w));

void toast(BuildContext c, String msg) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: Pal.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));

OutlineInputBorder _b(Color c, [double w = 1]) =>
    OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: w));

InputDecoration deco(String label, {String? hint, String? suffix, Widget? suffixIcon, Color? fillColor}) => InputDecoration(
      labelText: label, hintText: hint, suffixText: suffix, suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Pal.slate, fontSize: 13.5),
      floatingLabelStyle: const TextStyle(color: Pal.ocre, fontWeight: FontWeight.w700, fontSize: 13),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: _b(Pal.line), enabledBorder: _b(Pal.line),
      focusedBorder: _b(Pal.ocre, 1.5), errorBorder: _b(Pal.thread), focusedErrorBorder: _b(Pal.thread, 1.5),
    );

/// Permet aux écrans d'ouvrir les notifications ou la liste des commandes depuis le shell.
class ShellScope extends InheritedWidget {
  const ShellScope({super.key, required this.openNotifications, required this.goOrders, required super.child});
  final VoidCallback openNotifications, goOrders;
  static ShellScope? maybeOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<ShellScope>();
  @override
  bool updateShouldNotify(ShellScope old) => false;
}

// ---------------------------------------------------------------------------
// Marque et en-tête
/// Permet au splash de masquer le logo d'en-tête pendant que le logo volant arrive,
/// pour éviter tout effet de dédoublement visuel.
class SplashScope extends InheritedWidget {
  const SplashScope({super.key, required this.showLogo, required super.child});
  final bool showLogo;

  static bool showLogoOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SplashScope>()?.showLogo ?? true;

  @override
  bool updateShouldNotify(SplashScope oldWidget) => oldWidget.showLogo != showLogo;
}

/// Calcule avec précision la position centrale (X, Y) du logo dans l'AppHeader
/// en fonction des dimensions réelles de l'écran et du facteur d'échelle de police.
Offset computeAppBarLogoCenter(BuildContext context, {String label = 'Miva Couture'}) {
  final mediaQuery = MediaQuery.of(context);
  final screenWidth = mediaQuery.size.width;
  final safeTop = mediaQuery.padding.top;

  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        fontFamily: 'Fraunces',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -.3,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: mediaQuery.textScaler,
  )..layout();

  final textWidth = textPainter.width;
  final rowWidth = 22.0 + 8.0 + textWidth;
  final rowLeft = (screenWidth - rowWidth) / 2;
  final logoCenterX = rowLeft + 11.0;
  final logoCenterY = safeTop + 28.0;

  return Offset(logoCenterX, logoCenterY);
}

// ---------------------------------------------------------------------------
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.height = 22,
    this.withName = true,
    this.label = 'Miva Couture',
    this.heroTag,
  });
  final double height;
  final bool withName;
  final String label;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final showLogo = SplashScope.showLogoOf(context);
    Widget img = Visibility(
      visible: showLogo,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Image.asset('assets/brand/png/emblem_512.png', height: height, fit: BoxFit.contain),
    );
    if (heroTag != null && showLogo) {
      img = Hero(
        tag: heroTag!,
        flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
          return Image.asset('assets/brand/png/emblem_512.png', fit: BoxFit.contain);
        },
        child: img,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        img,
        if (withName) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Pal.terreBogolan,
                letterSpacing: -.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Bouton carré épuré aux coins arrondis de 12 px (menu, cloche, actions).
class IconBox extends StatelessWidget {
  const IconBox({super.key, required this.icon, required this.onTap, this.dot = false, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final bool dot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
            boxShadow: softShadow(colors.isDark ? 8 : 12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: colors.textPrimary),
              if (dot)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Pal.ocre, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = Pal.eyebrow});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => IntrinsicWidth(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(height: 1.5, color: color.withAlpha(110)),
          const SizedBox(height: 5),
          Text(text.toUpperCase(), style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: color)),
        ]),
      );
}

/// Titre d'écran : surtitre à filet + grand titre (pour l'accueil).
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.eyebrow, required this.title, this.actions = const []});
  final String eyebrow, title;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 6),
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -.7, height: 1.1)),
            ]),
          ),
          ...actions,
        ]),
      );
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.onMenu,
    this.title,
    this.isHome = false,
    this.actions = const [],
  });
  final VoidCallback onMenu;
  final String? title;
  final bool isHome;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final displayTitle = isHome ? 'Miva Couture' : (title ?? 'Miva Couture');

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Titre centré au milieu de la barre (sans aucun logo comme requis)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Text(
                displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: isHome ? 'Fraunces' : 'Public Sans',
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          // Bouton menu à gauche
          Positioned(
            left: 0,
            child: IconBox(icon: Icons.notes_rounded, onTap: onMenu, tooltip: 'Menu'),
          ),
          // Boutons d'actions à droite
          Positioned(
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...actions,
                if (isHome) ...[
                  const SizedBox(width: 8),
                  IconBox(
                    icon: Icons.notifications_none_rounded,
                    dot: true,
                    tooltip: 'Notifications',
                    onTap: () => ShellScope.maybeOf(context)?.openNotifications(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Page d'une section : en-tête fixe avec logo et titre centrés,
/// et tout le contenu de la page défilant sous l'en-tête.
class SectionPage extends StatelessWidget {
  const SectionPage({
    super.key,
    required this.title,
    required this.onMenu,
    required this.child,
    this.actions = const [],
    this.eyebrow = 'Atelier',
    this.isHome = false,
  });
  final String title, eyebrow;
  final VoidCallback onMenu;
  final Widget child;
  final List<Widget> actions;
  final bool isHome;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeader(
              onMenu: onMenu,
              title: title,
              isHome: isHome,
              actions: actions,
            ),
            Expanded(child: child),
          ],
        ),
      );
}

/// Petit bouton d'action carré placé dans l'en-tête.
Widget titleAction(IconData icon, VoidCallback onTap, String tooltip) => Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconBox(icon: icon, onTap: onTap, tooltip: tooltip),
    );

const kListPadding = EdgeInsets.fromLTRB(16, 10, 16, 120); // laisse la place à la pilule

// ---------------------------------------------------------------------------
// Surfaces
// ---------------------------------------------------------------------------
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.margin = const EdgeInsets.only(bottom: 9),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding, margin;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: kBorderRadius,
          border: Border.all(color: colors.border),
          boxShadow: softShadow(colors.isDark ? 6 : 10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: kBorderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
        ),
      ),
    );
  }
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 2, 8),
      child: Row(children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -.4,
              color: colors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Carte noble Bogolan (en remplacement des anciens dégradés cobalt / orange).
class CobaltCard extends StatelessWidget {
  const CobaltCard({super.key, required this.child, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Pal.terreBogolan,
        borderRadius: kBorderRadius,
        border: Border.all(color: Pal.ocre.withAlpha(120), width: 1.2),
        boxShadow: softShadow(14),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.hint});
  final IconData icon;
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
            boxShadow: softShadow(colors.isDark ? 6 : 10),
          ),
          child: Icon(icon, size: 26, color: Pal.ocre),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.35),
          ),
        ],
      ]),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.late = false});
  final OrderStatus status;
  final bool late;

  @override
  Widget build(BuildContext context) {
    final visual = StatusVisuals.of(status, isLate: late);
    final isPulsing = late || status == OrderStatus.cours || status == OrderStatus.essayage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: visual.foreground.withAlpha(50),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPulsing) ...[
            PulsingIndicator(size: 6, color: visual.foreground, glow: false),
            const SizedBox(width: 5),
          ],
          Text(
            visual.label,
            style: TextStyle(
              color: visual.foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Puce de filtre adaptée aux modes clair et sombre.
class PillChip extends StatelessWidget {
  const PillChip({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Pal.terreBogolan : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Pal.ocre : colors.border,
          ),
          boxShadow: softShadow(colors.isDark ? 4 : 8),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              fontSize: 12.5,
              color: selected ? Pal.cremeCoton : colors.textPrimary,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirm(BuildContext c, String title, String message, {String action = 'Supprimer'}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(action, style: const TextStyle(color: Pal.thread, fontWeight: FontWeight.w800))),
      ],
    ),
  );
  return r ?? false;
}

// ---------------------------------------------------------------------------
// Photos (maquette : tuiles dégradées « demo:N » aux nuances textiles africaines)
// ---------------------------------------------------------------------------
const _demoGradients = [
  [Color(0xFFC98A2B), Color(0xFF7A4E12)], // Bazin Ocre Or
  [Color(0xFF4A2E1B), Color(0xFF2E1B0F)], // Bogolan Terre Sombre
  [Color(0xFF9C4A2A), Color(0xFF5E2611)], // Terre Rouge Cuivrée
  [Color(0xFF0E5A3A), Color(0xFF063320)], // Kente Vert Profond Couture
  [Color(0xFF8A6D58), Color(0xFF5A4130)], // Brun Coton Doux
  [Color(0xFFB3362B), Color(0xFF6B1B14)], // Pagne Rouge Brique
  [Color(0xFFD49B45), Color(0xFF8E5616)], // Soie Ocre Dorée
  [Color(0xFF6E5D53), Color(0xFF3A2E27)], // Lin Écru Naturel
];

int _demoIndex = 0;

/// Simule l'ajout d'une photo (appareil / galerie) : renvoie une tuile de démonstration.
Future<String?> pickPhoto(BuildContext context) async {
  final ok = await showMotionBottomSheet<bool>(
    context: context,
    isScrollControlled: false,
    builder: (c) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        StaggeredFadeIn(
          index: 0,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Pal.cremeCoton, child: Icon(Icons.photo_camera_outlined, color: Pal.terreBogolan)),
            title: const Text('Prendre une photo', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(c, true),
          ),
        ),
        StaggeredFadeIn(
          index: 1,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Pal.cremeCoton, child: Icon(Icons.photo_library_outlined, color: Pal.terreBogolan)),
            title: const Text('Choisir dans la galerie', style: TextStyle(fontWeight: FontWeight.w700)),
            onTap: () => Navigator.pop(c, true),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (ok != true) return null;
  return 'demo:${_demoIndex++ % _demoGradients.length}';
}

class PhotoThumb extends StatelessWidget {
  const PhotoThumb(this.path, {super.key, this.size = 64, this.radius = 16, this.onTap});
  final String? path;
  final double size, radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final idx = path != null && path!.startsWith('demo:') ? int.tryParse(path!.substring(5)) : null;
    final colors = idx == null ? null : _demoGradients[idx % _demoGradients.length];
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size, height: size,
        child: GestureDetector(
          onTap: onTap ?? (colors == null ? null : () => openPhoto(context, path!)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: colors == null ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              color: colors == null ? Pal.line : null,
            ),
            child: Center(child: Icon(Icons.checkroom_rounded, size: 26, color: colors == null ? Pal.slate : Colors.white70)),
          ),
        ),
      ),
    );
  }
}

void openPhoto(BuildContext c, String path) => Navigator.of(c).push(FadePageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(
          child: AspectRatio(
            aspectRatio: .8,
            child: FeaturedHeroImage(
              child: PhotoThumb(path, size: double.infinity, radius: 0, onTap: () {}),
            ),
          ),
        ),
      ),
    ));

/// Bande horizontale de photos avec bouton d'ajout (formulaires).
class PhotoStrip extends StatelessWidget {
  const PhotoStrip({super.key, required this.photos, required this.onAdd, required this.onRemove});
  final List<String> photos;
  final VoidCallback onAdd;
  final void Function(String) onRemove;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 88,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 88, height: 88, margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(14)),
              child: const Icon(Icons.add_a_photo_outlined, color: Pal.terreBogolan),
            ),
          ),
          for (final ph in photos)
            Stack(children: [
              Padding(padding: const EdgeInsets.only(right: 10), child: PhotoThumb(ph, size: 88, radius: 20)),
              Positioned(
                top: 4, right: 14,
                child: GestureDetector(
                  onTap: () => onRemove(ph),
                  child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)),
                ),
              ),
            ]),
        ]),
      );
}

// ---------------------------------------------------------------------------
// Champs
// ---------------------------------------------------------------------------
class PickerField<T> extends StatelessWidget {
  const PickerField({
    super.key, required this.label, required this.items, required this.value,
    required this.onChanged, this.allowClear = false,
  });
  final String label;
  final List<(T, String)> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    final current = items.where((e) => e.$1 == value).map((e) => e.$2).firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final r = await showMotionBottomSheet<(T?,)>(
          context: context,
          isScrollControlled: true,
          builder: (c) => SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * .7),
              child: ListView(shrinkWrap: true, children: [
                Padding(padding: const EdgeInsets.fromLTRB(24, 22, 24, 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                if (allowClear) ListTile(title: const Text('Aucun'), onTap: () => Navigator.pop(c, (null,))),
                for (var i = 0; i < items.length; i++)
                  StaggeredFadeIn(
                    index: i,
                    child: ListTile(
                      title: Text(items[i].$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: items[i].$1 == value ? const Icon(Icons.check_circle, color: Pal.terreBogolan) : null,
                      onTap: () => Navigator.pop(c, (items[i].$1,)),
                    ),
                  ),
              ]),
            ),
          ),
        );
        if (r != null) onChanged(r.$1);
      },
      child: InputDecorator(
        decoration: deco(label, suffixIcon: const Icon(Icons.expand_more)),
        child: Text(current ?? 'Choisir', style: TextStyle(color: current == null ? Pal.slate : Pal.ink, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class DateField extends StatelessWidget {
  const DateField({
    super.key, required this.label, required this.value, required this.onChanged,
    this.allowClear = false, this.firstYear = 2015, this.lastYear = 2035,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowClear;
  final int firstYear, lastYear;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final d = await showDatePicker(
            context: context, initialDate: value ?? DateTime.now(),
            firstDate: DateTime(firstYear), lastDate: DateTime(lastYear),
          );
          if (d != null) onChanged(d);
        },
        child: InputDecorator(
          decoration: deco(
            label,
            suffixIcon: allowClear && value != null
                ? IconButton(icon: const Icon(Icons.close), onPressed: () => onChanged(null))
                : const Icon(Icons.event_outlined),
          ),
          child: Text(value == null ? 'Choisir une date' : fmtDate(value!),
              style: TextStyle(color: value == null ? Pal.slate : Pal.ink, fontWeight: FontWeight.w600)),
        ),
      );
}

Widget moneyField(TextEditingController c, String label, {String? Function(String?)? validator}) => TextFormField(
      controller: c, keyboardType: TextInputType.number, decoration: deco(label, suffix: 'FCFA'), validator: validator,
    );

int parseMoney(String s) => int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Feuille de saisie d'un paiement (clients et apprentis).
Future<void> showPaymentSheet(
  BuildContext context, {
  required String title,
  required int max,
  required Future<void> Function(int amount, String note) onSave,
}) =>
    showMotionBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PaymentSheet(title: title, max: max, onSave: onSave),
    );

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({required this.title, required this.max, required this.onSave});
  final String title;
  final int max;
  final Future<void> Function(int, String) onSave;
  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final v = parseMoney(_amount.text);
    if (v <= 0) return setState(() => _error = 'Saisissez un montant');
    if (v > widget.max) return setState(() => _error = 'Maximum : ${fcfa(widget.max)} (reste à payer)');
    setState(() => _busy = true);
    final note = _note.text.trim();
    Navigator.pop(context);
    await widget.onSave(v, note);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          StaggeredFadeIn(index: 0, child: Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.4))),
          const SizedBox(height: 4),
          StaggeredFadeIn(index: 1, child: Text('Reste à payer : ${fcfa(widget.max)}', style: const TextStyle(color: Pal.slate))),
          const SizedBox(height: 16),
          StaggeredFadeIn(
            index: 2,
            child: TextField(
              controller: _amount, autofocus: true, keyboardType: TextInputType.number,
              decoration: deco('Montant versé', suffix: 'FCFA').copyWith(errorText: _error),
            ),
          ),
          const SizedBox(height: 12),
          StaggeredFadeIn(index: 3, child: TextField(controller: _note, decoration: deco('Note (facultatif)'))),
          const SizedBox(height: 16),
          StaggeredFadeIn(
            index: 4,
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _save, child: const Text('Enregistrer le paiement'))),
          ),
        ]),
      );
}
