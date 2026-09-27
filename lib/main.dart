import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/zapiti_localizations.dart';
import 'screens/game_screen.dart';
import 'services/zapiti_logger.dart';
import 'theme/zapiti_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    ZapitiLogger.error(
      'app',
      'flutter_error',
      error: details.exception,
      stackTrace: details.stack,
      fields: {
        'library': details.library,
        'context': details.context?.toDescription(),
      },
    );
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    ZapitiLogger.error(
      'app',
      'platform_error',
      error: error,
      stackTrace: stackTrace,
    );
    return false;
  };
  ZapitiLogger.info('app', 'startup_begin');
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  ZapitiLogger.debug('app', 'orientation_locked');
  await ZapitiI18n.load();
  ZapitiLogger.info('app', 'i18n_loaded');
  runApp(const ZapitiApp());
  ZapitiLogger.info('app', 'run_app_called');
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
