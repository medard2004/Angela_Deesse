import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'app.dart';
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
  runApp(
    MultiProvider(
      providers: [
        Provider<PhotoStorage>(create: (_) => DefaultPhotoStorage()),
        ChangeNotifierProvider(create: (_) => AppStore()),
      ],
      child: const AngelaApp(),
    ),
  );
}
