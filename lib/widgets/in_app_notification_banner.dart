import 'dart:async';
import 'package:flutter/services.dart';
import '../ui.dart';

/// Bannière de notification élégante qui s'affiche en haut de l'écran
/// lorsque l'artisan est déjà dans l'application active.
class InAppNotificationBanner extends StatefulWidget {
  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
    this.duration = const Duration(seconds: 5),
  });

  final String title;
  final String body;
  final VoidCallback? onTap;
  final Duration duration;

  static OverlayEntry? _currentEntry;

  /// Affiche une bannière de notification in-app au sommet de l'écran.
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 5),
    OverlayState? overlayState,
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = overlayState ??
        Navigator.maybeOf(context)?.overlay ??
        Overlay.maybeOf(context);
    if (overlay == null) return;

    try {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: InAppNotificationBanner(
            title: title,
            body: body,
            duration: duration,
            onTap: () {
              entry.remove();
              if (_currentEntry == entry) _currentEntry = null;
              onTap?.call();
            },
          ),
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) {
        if (mounted) {
          InAppNotificationBanner._currentEntry?.remove();
          InAppNotificationBanner._currentEntry = null;
        }
      });
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: const Key('in_app_banner_dismiss'),
            direction: DismissDirection.up,
            onDismissed: (_) {
              InAppNotificationBanner._currentEntry?.remove();
              InAppNotificationBanner._currentEntry = null;
            },
            child: InkWell(
              onTap: () {
                _dismiss();
                widget.onTap?.call();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Pal.ink,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: Pal.cobalt.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Pal.orange.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Pal.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Pal.cobalt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Voir',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

