import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapiti_app/l10n/zapiti_localizations.dart';
import 'package:zapiti_app/main.dart';
import 'package:zapiti_app/screens/game_screen.dart';
import 'package:zapiti_app/services/app_version_check_service.dart';

void main() {
  const screenshotSize = Size(1280, 720);
  final outputDir = Directory('play_store_screenshots');

  setUpAll(() async {
    await ZapitiI18n.load();
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameScreen.versionCheckService = AppVersionCheckService(
      manifestUri: null,
      installedVersionProvider: () async => '0.1.0',
    );
  });

  testWidgets('capturas para Google Play Store', (tester) async {
    tester.view.physicalSize = screenshotSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const RepaintBoundary(
        key: ValueKey('screenshot-root'),
        child: ZapitiApp(),
      ),
    );
    await tester.pumpAndSettle();

    await _capture(tester, '01_menu_principal.png');

    await tester.tap(find.text('TUTORIAL'));
    await tester.pumpAndSettle();
    await _capture(tester, '02_tutorial_lecciones.png');

    await tester.tap(find.text('PRÁCTICA'));
    await tester.pumpAndSettle();
    await _capture(tester, '03_tutorial_practica.png');

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();
    await _capture(tester, '04_multijugador_lobby.png');

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();
    await _capture(tester, '05_seleccion_personaje.png');

    final startButton = find.text('EMPEZAR PARTIDA');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();
    await _capture(tester, '06_seleccion_dificultad.png');

    final playButton = find.text('JUGAR');
    await tester.ensureVisible(playButton);
    await tester.tap(playButton);
    await tester.pumpAndSettle();
    await _capture(tester, '07_mesa_partida.png');

    await tester.tap(find.text('AYUDA SEÑAS'));
    await tester.pumpAndSettle();
    await _capture(tester, '08_ayuda_senas.png');
  });
}

Future<void> _capture(WidgetTester tester, String fileName) async {
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('screenshot-root')),
  );
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  if (data == null) {
    throw StateError('No se pudo generar la captura $fileName.');
  }
  final file = File('play_store_screenshots/$fileName');
  await file.writeAsBytes(data.buffer.asUint8List());
}
