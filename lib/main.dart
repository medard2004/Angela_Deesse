import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'data/services/contact_launcher.dart';
import 'data/services/external_action_tracker.dart';
import 'data/services/photo_storage.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  ));

  final externalActionTracker = ExternalActionTracker();
  final photoStorage = DefaultPhotoStorage(tracker: externalActionTracker);
  final contactLauncher = DefaultContactLauncher(tracker: externalActionTracker);

  runApp(
    MultiProvider(
      providers: [
        Provider<ExternalActionTracker>.value(value: externalActionTracker),
        Provider<PhotoStorage>.value(value: photoStorage),
        Provider<ContactLauncher>.value(value: contactLauncher),
        ChangeNotifierProvider(create: (_) => AppStore()),
      ],
      child: const AngelaApp(),
    ),
  );
}
