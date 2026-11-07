import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../core/app_brand.dart';
import '../data/services/alert_engine.dart';
import '../data/services/system_reminder_service.dart';
import '../ui.dart';

/// Écran d'aide et de diagnostic pour assurer que les rappels système
/// sonnent correctement même en veille prolongée (Décisions 24-26).
class ReminderGuideScreen extends StatefulWidget {
  const ReminderGuideScreen({
    super.key,
    this.deviceInfoPlugin,
    this.overrideManufacturer,
  });

  /// Permet d'injecter un plugin de test pour valider la détection constructeur.
  final DeviceInfoPlugin? deviceInfoPlugin;

  /// Permet de forcer un fabricant pour les tests unitaire / widgets.
  final String? overrideManufacturer;

  @override
  State<ReminderGuideScreen> createState() => _ReminderGuideScreenState();
}

class _ReminderGuideScreenState extends State<ReminderGuideScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _notificationsGranted = false;
  bool _exactAlarmsAllowed = true;
  String _manufacturer = '';
  String _model = '';
  int _pendingCount = 0;
  DateTime? _nextReminderTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshDiagnostic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDiagnostic();
    }
  }

  Future<void> _refreshDiagnostic() async {
    setState(() => _isLoading = true);
    final reminderService = context.read<SystemReminderService?>();
    final store = context.read<AppStore>();

    bool notifs = true;
    bool exact = true;

    if (reminderService != null) {
      notifs = await reminderService.areNotificationsGranted();
      exact = await reminderService.canScheduleExactAlarms();
    }

    String man = widget.overrideManufacturer ?? '';
    String mod = '';
    if (man.isEmpty) {
      try {
        if (!kIsWeb && Platform.isAndroid) {
          final info = widget.deviceInfoPlugin ?? DeviceInfoPlugin();
          final androidInfo = await info.androidInfo;
          man = androidInfo.manufacturer;
          mod = androidInfo.model;
        }
      } catch (_) {
        // Ignorer si indisponible
      }
    }

    int pending = 0;
    if (reminderService != null) {
      final reqs = await reminderService.pendingNotificationRequests();
      pending = reqs.length;
    }

    // Calcul du prochain rappel planifié via AlertEngine
    DateTime? nextTime;
    final engine = reminderService?.alertEngine ?? const AlertEngine();
    final grouped = engine.groupedPlannedReminders(
      now: DateTime.now(),
      orders: store.orders,
      apprentices: store.apprentices,
      clientById: (id) => store.clientById(id),
      remainingOfOrder: (o) => store.remainingOf(o),
      remainingOfApprentice: (a) => store.apprenticeRemaining(a),
      deliveryEnabled: store.notifDelivery,
      fittingEnabled: store.notifFitting,
      paymentsEnabled: store.notifPayments,
      deliveryMode: store.deliveryMode,
      fittingMode: store.fittingMode,
      paymentsMode: store.paymentsMode,
    );

    if (grouped.isNotEmpty) {
      nextTime = grouped.first.scheduledAt;
    }

    if (!mounted) return;
    setState(() {
      _notificationsGranted = notifs;
      _exactAlarmsAllowed = exact;
      _manufacturer = man;
      _model = mod;
      _pendingCount = pending;
      _nextReminderTime = nextTime;
      _isLoading = false;
    });
  }

  Future<void> _requestNotificationPermission() async {
    final reminderService = context.read<SystemReminderService?>();
    if (reminderService != null) {
      final granted = await reminderService.requestNotificationsPermission();
      if (!granted) {
        await _openSettings(AppSettingsType.notification);
      }
      await _refreshDiagnostic();
    }
  }

  Future<void> _openSettings(AppSettingsType type) async {
    try {
      await AppSettings.openAppSettings(type: type);
    } catch (_) {
      // Repli sur paramètres globaux
      try {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
      } catch (_) {}
    }
  }

  Future<void> _scheduleTest(Duration delay, String label, {bool asAlarm = true}) async {
    final reminderService = context.read<SystemReminderService?>();
    if (reminderService == null) return;

    await reminderService.scheduleRingerTest(delay: delay, asAlarm: asAlarm);
    await _refreshDiagnostic();

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(asAlarm ? Icons.alarm_on_rounded : Icons.notifications_active_outlined, color: Pal.cobalt, size: 24),
          const SizedBox(width: 8),
          const Text('Test programmé', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        content: Text(
          asAlarm
              ? 'Une alarme de test retentira dans $label.\n\n'
                '• Si vous restez dans l\'application, l\'écran d\'alarme apparaîtra en direct.\n'
                '• Si vous verrouillez votre écran, votre téléphone se réveillera avec sonnerie et écran d\'alarme.'
              : 'Une notification de test retentira dans $label.\n\n'
                '• Si vous restez dans l\'application, un bandeau in-app s\'affichera en haut.\n'
                '• Si vous quittez l\'application, vous recevrez une notification push standard.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.w700, color: Pal.cobalt)),
          ),
        ],
      ),
    );
  }

  bool _isTranssion(String man) {
    final s = man.toLowerCase();
    return s.contains('tecno') || s.contains('infinix') || s.contains('itel') || s.contains('transsion');
  }

  bool _isXiaomi(String man) {
    final s = man.toLowerCase();
    return s.contains('xiaomi') || s.contains('redmi') || s.contains('poco');
  }

  bool _isSamsung(String man) {
    final s = man.toLowerCase();
    return s.contains('samsung');
  }

  String _formatNextTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final timeStr = DateFormat('HH:mm').format(dt);

    if (target.isAtSameMomentAs(today)) {
      return "Aujourd'hui à $timeStr";
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (target.isAtSameMomentAs(tomorrow)) {
      return 'Demain à $timeStr';
    }
    return '${DateFormat('EEEE d MMMM', 'fr_FR').format(dt)} à $timeStr';
  }

  @override
  Widget build(BuildContext context) {
    final isTrans = _isTranssion(_manufacturer);
    final isXiao = _isXiaomi(_manufacturer);
    final isSam = _isSamsung(_manufacturer);

    final phoneLabel = _model.isNotEmpty ? '$_manufacturer $_model' : _manufacturer;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pour que les rappels sonnent',
          style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Pal.chalk,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshDiagnostic,
            icon: const Icon(Icons.refresh_rounded, color: Pal.cobalt),
            tooltip: 'Actualiser le diagnostic',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Pal.cobalt))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              children: [
                // État récapitulatif des rappels planifiés
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF3FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Pal.cobalt.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Pal.cobalt.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Pal.cobalt, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prochains rappels : $_pendingCount planifié${_pendingCount > 1 ? 's' : ''}',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Pal.ink),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _nextReminderTime != null
                                  ? 'Prochain : ${_formatNextTime(_nextReminderTime!)}'
                                  : 'Aucun rappel prévu dans les 45 prochains jours',
                              style: const TextStyle(color: Pal.slate, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Heading('Autorisations système'),
                const SizedBox(height: 8),

                // 1. Permission Notifications
                Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _notificationsGranted ? Icons.check_circle_rounded : Icons.notifications_off_outlined,
                        color: _notificationsGranted ? Pal.sage : Pal.orange,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications de l\'application',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                            Text(
                              'Nécessaire pour afficher les alertes',
                              style: TextStyle(color: Pal.slate, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      if (_notificationsGranted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Pal.sage.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Autorisées', style: TextStyle(color: Pal.sage, fontWeight: FontWeight.w800, fontSize: 11)),
                        )
                      else
                        FilledButton(
                          onPressed: _requestNotificationPermission,
                          style: FilledButton.styleFrom(
                            backgroundColor: Pal.orange,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('Autoriser', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 2. Alarmes exactes
                Panel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        _exactAlarmsAllowed ? Icons.check_circle_rounded : Icons.alarm_off_outlined,
                        color: _exactAlarmsAllowed ? Pal.sage : Pal.orange,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alarmes précises',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                            Text(
                              'Permet de sonner à la minute exacte',
                              style: TextStyle(color: Pal.slate, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                      if (_exactAlarmsAllowed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Pal.sage.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Exactes', style: TextStyle(color: Pal.sage, fontWeight: FontWeight.w800, fontSize: 11)),
                        )
                      else
                        FilledButton(
                          onPressed: () => _openSettings(AppSettingsType.alarm),
                          style: FilledButton.styleFrom(
                            backgroundColor: Pal.orange,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('Configurer', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 3. Optimisation de la batterie
                Panel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.battery_saver_rounded, color: Pal.cobalt, size: 22),
                          SizedBox(width: 8),
                          Text('Optimisation de la batterie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Pour que votre téléphone sonne même lorsqu\'il est posé en veille prolongée sur votre établi, désactivez l\'optimisation de batterie pour ${AppBrand.appName}.',
                        style: TextStyle(color: Pal.slate, fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _openSettings(AppSettingsType.batteryOptimization),
                        icon: const Icon(Icons.settings_outlined, size: 16, color: Pal.cobalt),
                        label: const Text('Désactiver l\'optimisation batterie', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Pal.cobalt)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Pal.cobalt),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 4. Encadré spécifique constructeur
                if (isTrans) ...[
                  const Heading('Réglage recommandé pour votre téléphone'),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Pal.orange.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smartphone_rounded, color: Pal.orange, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Téléphone ${phoneLabel.toUpperCase()} détecté',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Pal.ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Les téléphones Tecno, Infinix et Itel coupent souvent les applications en veille. Pour que vos rappels fonctionnent à coup sûr :\n\n'
                          '1. Ouvrez l\'application « Phone Master » ou « Gestionnaire ».\n'
                          '2. Allez dans « Démarrage automatique » et activez ${AppBrand.appName}.\n'
                          '3. Dans la liste des applications récentes, glissez ${AppBrand.appName} vers le bas et appuyez sur l\'icône Cadenas pour la verrouiller.',
                          style: TextStyle(fontSize: 12.5, height: 1.4, color: Pal.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (isXiao) ...[
                  const Heading('Réglage recommandé pour votre téléphone'),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Pal.orange.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smartphone_rounded, color: Pal.orange, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Téléphone ${phoneLabel.toUpperCase()} détecté',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Pal.ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Ouvrez les Paramètres > Applications > Gérer les applications > ${AppBrand.appName}.\n'
                          '2. Activez le Démarrage automatique.\n'
                          '3. Dans Économiseur de batterie, choisissez « Pas de restrictions ».',
                          style: TextStyle(fontSize: 12.5, height: 1.4, color: Pal.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else if (isSam) ...[
                  const Heading('Réglage recommandé pour votre téléphone'),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Pal.orange.withValues(alpha: 0.35)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smartphone_rounded, color: Pal.orange, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Téléphone ${phoneLabel.toUpperCase()} détecté',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Pal.ink),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1. Ouvrez les Paramètres > Batterie et maintenance > Batterie.\n'
                          '2. Allez dans « Limites d\'utilisation en arrière-plan ».\n'
                          '3. Ajoutez ${AppBrand.appName} dans « Applications jamais en veille ».',
                          style: const TextStyle(fontSize: 12.5, height: 1.4, color: Pal.ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  const Heading('Démarrage automatique'),
                  const SizedBox(height: 8),
                  Panel(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Si votre téléphone dispose d\'un gestionnaire d\'alimentation ou de démarrage automatique (ex: Honor, Huawei, Oppo, Vivo), veillez à autoriser ${AppBrand.appName} à s\'exécuter en arrière-plan.',
                      style: const TextStyle(color: Pal.slate, fontSize: 12, height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 5. Test de sonnerie
                const Heading('Tester la sonnerie d\'alarme'),
                const SizedBox(height: 8),
                Panel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Testez immédiatement le réveil plein écran et les notifications in-app ou push sur votre téléphone.',
                        style: TextStyle(color: Pal.slate, fontSize: 12, height: 1.35),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '⏰ Alarme réveil plein écran :',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Pal.ink),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _scheduleTest(const Duration(seconds: 10), '10 secondes', asAlarm: true),
                              icon: const Icon(Icons.flash_on_rounded, size: 16),
                              label: const Text('Dans 10s', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB45309),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _scheduleTest(const Duration(minutes: 1), '1 minute', asAlarm: true),
                              icon: const Icon(Icons.timer_outlined, size: 16),
                              label: const Text('Dans 1 min', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                              style: FilledButton.styleFrom(
                                backgroundColor: Pal.cobalt,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _scheduleTest(const Duration(minutes: 30), '30 minutes', asAlarm: true),
                              icon: const Icon(Icons.bedtime_outlined, size: 15, color: Pal.cobalt),
                              label: const Text('Dans 30 min', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Pal.cobalt)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Pal.cobalt),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Pal.line),
                      const SizedBox(height: 12),
                      const Text(
                        '🔔 Notification standard (push / in-app) :',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Pal.ink),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _scheduleTest(const Duration(seconds: 5), '5 secondes', asAlarm: false),
                          icon: const Icon(Icons.notifications_active_outlined, size: 16, color: Pal.cobalt),
                          label: const Text('Tester la notification (dans 5s)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Pal.cobalt)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Pal.cobalt),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
