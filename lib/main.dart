import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/zapiti_localizations.dart';
import 'screens/game_screen.dart';
import 'theme/zapiti_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await ZapitiI18n.load();
  runApp(const ZapitiApp());
}

class ZapitiApp extends StatelessWidget {
  const ZapitiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zapiti',
      theme: ZapitiTheme.theme,
      home: const GameScreen(),
    );
  }
}
