import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/team_rules.dart';
import 'package:zapiti_app/l10n/zapiti_localizations.dart';
import 'package:zapiti_app/main.dart';
import 'package:zapiti_app/screens/game_screen.dart';
import 'package:zapiti_app/services/app_version_check_service.dart';

void main() {
  const musicChannel = MethodChannel('zapiti/music');

  setUp(() async {
    await ZapitiI18n.load();
    GameScreen.versionCheckService = AppVersionCheckService(
      manifestUri: null,
      installedVersionProvider: () async => '0.1.0',
    );
  });

  Future<void> startGame(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());
    expect(find.text('JUGAR'), findsOneWidget);
    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();

    expect(find.text('Elige tu personaje'), findsOneWidget);
    final startButton = find.text('EMPEZAR PARTIDA');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Elige dificultad'), findsOneWidget);
    final playButton = find.text('JUGAR');
    await tester.ensureVisible(playButton);
    await tester.tap(playButton);
    await tester.pumpAndSettle();
  }

  testWidgets('muestra selector de personajes antes de jugar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    expect(find.text('JUGAR'), findsOneWidget);
    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();

    expect(find.text('Elige tu personaje'), findsOneWidget);
    expect(find.text('Tu personaje'), findsOneWidget);
    expect(find.text('Jugador 1'), findsAtLeastNWidgets(1));
    expect(find.text('Jugador 2'), findsOneWidget);
    expect(find.text('Jugador 3'), findsOneWidget);
    expect(find.text('Jugador 4'), findsOneWidget);
  });

  testWidgets('menu principal abre tutorial y opciones', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    expect(find.text('JUGAR'), findsOneWidget);
    expect(find.text('TUTORIAL'), findsOneWidget);
    expect(find.text('MULTIJUGADOR'), findsOneWidget);
    expect(find.text('OPCIONES'), findsOneWidget);

    await tester.tap(find.text('TUTORIAL'));
    await tester.pumpAndSettle();

    expect(find.text('TUTORIAL'), findsOneWidget);
    expect(
      find.textContaining('Juegas con tu pareja contra dos rivales.'),
      findsOneWidget,
    );
    expect(find.text('VOLVER'), findsOneWidget);

    await tester.tap(find.text('PRÃƒÂCTICA'));
    await tester.pumpAndSettle();

    expect(find.text('Guarda la fuerte'), findsOneWidget);
    expect(find.text('Elige la mejor jugada'), findsOneWidget);
    await tester.tap(find.text('Tirar 4 Copas'));
    await tester.pumpAndSettle();
    expect(find.textContaining('guardas el As de Espadas'), findsOneWidget);

    await tester.tap(find.text('MESA'));
    await tester.pumpAndSettle();

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    expect(find.text('Guarda la fuerte'), findsOneWidget);
    expect(find.textContaining('conserva el As de Espadas'), findsOneWidget);
    expect(gameState.gameController.playedCards.length, 3);
    expect(gameState.gameController.currentPlayer.id, 'p1');

    gameState.setState(() {
      gameState.loadGuidedTutorialScenarioForTesting(3);
    });
    await tester.pumpAndSettle();
    expect(find.text('Pide seÃƒÂ±a'), findsOneWidget);
    expect(find.text('PEDIR SEÃƒâ€˜A'), findsOneWidget);
    await tester.tap(find.text('PEDIR SEÃƒâ€˜A'));
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.text('Da seÃƒÂ±a'), findsOneWidget);

    await tester.tap(find.byTooltip('4 Bastos'));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('Canta truco'), findsOneWidget);

    gameState.setState(() {
      gameState.loadGuidedTutorialScenarioForTesting(5);
    });
    await tester.pumpAndSettle();
    expect(find.text('Canta truco'), findsOneWidget);
    expect(find.text('CANTAR TRUCO'), findsOneWidget);
    await tester.tap(find.text('CANTAR TRUCO'));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(find.text('Farol controlado'), findsOneWidget);

    gameState.setState(() {
      gameState.loadGuidedTutorialScenarioForTesting(7);
    });
    await tester.pumpAndSettle();
    expect(find.text('Pasa truco malo'), findsOneWidget);
    expect(find.text('Te cantan 3'), findsOneWidget);
    await tester.tap(find.text('RECHAZAR'));
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Tutorial completado'),
      findsOneWidget,
    );
    await tester.tap(find.text('OPCIONES').first);
    await tester.pumpAndSettle();
    expect(find.text('Opciones'), findsNothing);
    await tester.tap(find.text('AYUDA SEÃƒâ€˜AS').first);
    await tester.pumpAndSettle();
    expect(find.text('Orden y seÃƒÂ±as'), findsNothing);

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SALIR').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();

    expect(find.text('OPCIONES'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Mostrar ayuda'), findsNothing);
    expect(find.text('Permitir pasar mano'), findsNothing);
  });

  testWidgets('opciones permite cambiar idioma', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();

    expect(find.text('Idioma'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('MULTIPLAYER'), findsOneWidget);
    expect(find.text('OPTIONS'), findsOneWidget);
  });

  testWidgets('menu principal abre la seccion acerca de desde portada',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.ensureVisible(find.text('ACERCA DE'));
    await tester.tap(find.text('ACERCA DE'));
    await tester.pumpAndSettle();

    expect(find.text('Zapiti App'), findsOneWidget);
    expect(find.textContaining('VersiÃƒÂ³n'), findsOneWidget);
    expect(find.text('Juan Francisco GutiÃƒÂ©rrez VÃƒÂ¡zquez'), findsWidgets);
    expect(find.text('Miguel Mateos Borrego'), findsOneWidget);
    expect(find.text('Agradecimientos especiales a la PeÃƒÂ±a el Trompazo.'),
        findsOneWidget);
    expect(find.text('VOLVER'), findsOneWidget);

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();

    expect(find.text('JUGAR'), findsOneWidget);
    expect(find.text('ACERCA DE'), findsOneWidget);
  });

  testWidgets('menu principal muestra login multijugador', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());
    await tester.pump();

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('MULTIJUGADOR'), findsOneWidget);
    expect(find.text('Iniciar sesiÃƒÂ³n'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contrasena'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('CREAR USUARIO'), findsOneWidget);
  });

  testWidgets('multijugador usa textos traducidos al cambiar idioma',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('MULTIPLAYER'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('User'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('menu principal bloquea multijugador si requiere actualizar',
      (tester) async {
    GameScreen.versionCheckService = AppVersionCheckService(
      manifestUri: Uri.parse('https://example.test/version.json'),
      installedVersionProvider: () async => '0.1.0',
      fetchManifest: (_) async => '''
{
  "latestVersion": "0.2.0",
  "minimumMultiplayerVersion": "0.2.0",
  "message": "Actualiza Zapiti para jugar online."
}
''',
    );
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());
    await tester.pump();

    expect(find.text('MULTIJUGADOR'), findsOneWidget);
    expect(find.text('Actualiza Zapiti para jugar online.'), findsNothing);

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('MULTIJUGADOR'), findsOneWidget);
    expect(find.text('Multijugador no disponible'), findsOneWidget);
    expect(find.text('Actualiza Zapiti para jugar online.'), findsOneWidget);
    expect(find.text('Iniciar sesiÃƒÂ³n'), findsNothing);
  });

  testWidgets('multijugador muestra espera mientras comprueba version',
      (tester) async {
    final completer = Completer<String>();
    GameScreen.versionCheckService = AppVersionCheckService(
      manifestUri: Uri.parse('https://example.test/version.json'),
      installedVersionProvider: () async => '0.1.0',
      fetchManifest: (_) => completer.future,
    );
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());
    await tester.pump();

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pump();

    expect(find.text('MULTIJUGADOR'), findsOneWidget);
    expect(find.text('Comprobando multijugador'), findsOneWidget);
    expect(
      find.text(
        'Comprobando versiÃƒÂ³n. El servicio puede tardar unos segundos...',
      ),
      findsOneWidget,
    );

    completer.complete('''
{
  "latestVersion": "0.1.0",
  "minimumMultiplayerVersion": "0.1.0"
}
''');
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesiÃƒÂ³n'), findsOneWidget);
  });

  testWidgets('multijugador recuerda el usuario', (tester) async {
    SharedPreferences.setMockInitialValues({
      'multiplayer_username': 'juan',
    });
    await tester.pumpWidget(const ZapitiApp());
    await tester.pump();

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('juan'), findsOneWidget);
  });

  testWidgets('multijugador no desborda en movil horizontal', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());
    await tester.pump();

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesiÃƒÂ³n'), findsOneWidget);
    expect(find.text('Contrasena'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu principal guarda la opcion de audio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Audio'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('audio_enabled'), isFalse);
  });

  testWidgets('la musica se para al bloquear o minimizar la app',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final musicCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(musicChannel, (call) async {
      musicCalls.add(call.method);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(musicChannel, null);
    });

    await tester.pumpWidget(const ZapitiApp());
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(musicCalls, contains('stop'));
  });

  testWidgets('menu principal guarda el volumen de audio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(-120, 0));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('audio_volume'), isNotNull);
    expect(prefs.getDouble('audio_volume')!, lessThan(0.65));
  });

  testWidgets('menu principal guarda confirmacion y velocidad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();

    expect(find.text('Mostrar ayuda'), findsNothing);
    await tester.tap(find.text('Confirmar jugada'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RÃƒÂ¡pida'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('confirm_card_play'), isTrue);
    expect(prefs.getString('bot_speed'), 'fast');
  });

  testWidgets('muestra selector de dificultad antes de jugar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();

    final startButton = find.text('EMPEZAR PARTIDA');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Elige dificultad'), findsOneWidget);
    expect(find.text('Nivel 3/5'), findsOneWidget);
    expect(
      find.text('IA equilibrada para partidas normales.'),
      findsOneWidget,
    );
    expect(
      find.text('Usa truco y subidas con riesgo razonable.'),
      findsOneWidget,
    );
    expect(find.text('Muy fÃƒÂ¡cil'), findsOneWidget);
    expect(find.text('Experto'), findsOneWidget);
    expect(
        find.text('Bots distraÃƒÂ­dos, errores claros y trucos precipitados.'),
        findsNothing);
    expect(find.text('Juegan aceptable, pero se precipitan.'), findsNothing);
  });

  testWidgets('setup no desborda en movil pequeno vertical', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu personaje'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('EMPEZAR PARTIDA'));
    await tester.pumpAndSettle();
    expect(find.text('Elige dificultad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('setup no desborda en movil horizontal', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();
    expect(find.text('Elige tu personaje'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('EMPEZAR PARTIDA'));
    await tester.pumpAndSettle();
    expect(find.text('Elige dificultad'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recuerda el personaje guardado y entra a la mesa',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'selected_human_character_id': 'p2',
      'selected_difficulty': 4,
    });

    await tester.pumpWidget(const ZapitiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('JUGAR'));
    await tester.pumpAndSettle();

    final startButton = find.text('EMPEZAR PARTIDA');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    expect(find.text('Elige dificultad'), findsOneWidget);
    final playButton = find.text('JUGAR');
    await tester.ensureVisible(playButton);
    await tester.tap(playButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
  });

  testWidgets('muestra la mesa inicial de Zapiti', (tester) async {
    await startGame(tester);

    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
    expect(find.text('Yo'), findsOneWidget);
    expect(find.text('CompaÃƒÂ±ero'), findsOneWidget);
    expect(find.text('Jugador rival 1'), findsOneWidget);
    expect(find.text('Jugador rival 2'), findsOneWidget);
    expect(find.text('Eq1'), findsOneWidget);
    expect(find.text('Eq2'), findsOneWidget);
    expect(find.text('Rondas'), findsOneWidget);
    expect(find.text('0 - 0'), findsOneWidget);
    expect(find.text('SeÃƒÂ±as'), findsNothing);
    expect(find.text('PEDIR SEÃƒâ€˜A'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(find.text('Manos prefijadas'), findsNothing);
  });

  testWidgets('ayuda de seÃƒÂ±as muestra orden de cartas y seÃƒÂ±ales',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('AYUDA SEÃƒâ€˜AS'));
    await tester.pumpAndSettle();

    expect(find.text('Orden y seÃƒÂ±as'), findsOneWidget);
    expect(find.text('4 de Bastos'), findsOneWidget);
    expect(find.text('7 de Copas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('As de Espadas'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('As de Espadas'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mala'),
      80,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Mala'), findsOneWidget);
    expect(find.text('Orden NÃƒÂºmerico de Valor'), findsNothing);

    await tester.tap(find.text('CERRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Orden y seÃƒÂ±as'), findsNothing);
  });

  testWidgets('la mesa no desborda en movil vertical', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
  });

  testWidgets('la mesa no desborda en movil pequeno', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
  });

  testWidgets('la mesa no desborda en movil grande', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
  });
  testWidgets('la mesa no desborda en movil 412x915', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
  });

  testWidgets('la mesa no desborda en tablet pequena vertical', (tester) async {
    tester.view.physicalSize = const Size(600, 960);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
  });

  testWidgets('la mesa no desborda en movil horizontal', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
  });

  for (final size in <Size>[
    const Size(800, 360),
    const Size(854, 393),
    const Size(896, 414),
    const Size(932, 430),
    const Size(960, 432),
    const Size(1080, 480),
    const Size(1280, 600),
  ]) {
    testWidgets('la mesa no desborda en landscape ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await startGame(tester);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Ronda 1/3'), findsOneWidget);
      expect(find.text('Rondas'), findsOneWidget);
      expect(find.text('CANTAR TRUCO'), findsOneWidget);
    });
  }

  testWidgets('pedir seÃƒÂ±a muestra respuesta en landscape', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('PEDIR SEÃƒâ€˜A'));
    await tester.pump();

    expect(find.text('Compa mira...'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('si no es el turno humano aparecen ven a mi y mata',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.setState(() {
      gameState.gameController.turnIndex = 1;
    });
    await tester.pump();

    expect(find.textContaining('VEN A'), findsOneWidget);
    expect(find.text('MATA'), findsOneWidget);
    expect(find.text('VOY A TI'), findsNothing);
  });

  testWidgets('pasar mano no aparece si la regla esta desactivada',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    expect(find.text('PASAR MANO'), findsNothing);
  });

  testWidgets('pasar mano aparece si la regla esta activada y sale el humano',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.setState(() {
      gameState.gameController.allowPassHand = true;
    });
    await tester.pump();

    expect(find.text('PASAR MANO'), findsOneWidget);
    expect(find.text('CANTAR TRUCO'), findsOneWidget);
  });

  testWidgets('pasar mano no aparece si no sale el humano', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.setState(() {
      gameState.gameController.allowPassHand = true;
      gameState.gameController.turnIndex = 1;
    });
    await tester.pump();

    expect(find.text('PASAR MANO'), findsNothing);
  });

  testWidgets('opciones desde la mesa no muestra ayuda', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();

    expect(find.text('OPCIONES'), findsWidgets);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Mostrar ayuda'), findsNothing);
    expect(find.text('Permitir pasar mano'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('volver desde la mesa regresa al menu principal', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();

    expect(find.text('Salir de la partida'), findsOneWidget);
    expect(find.text('CANCELAR'), findsOneWidget);
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ronda 1/3'), findsOneWidget);
    expect(find.text('Salir de la partida'), findsNothing);

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SALIR').last);
    await tester.pumpAndSettle();

    expect(find.text('TUTORIAL'), findsOneWidget);
    expect(find.text('OPCIONES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra la decision al ver para el equipo humano',
      (tester) async {
    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.gameController.score[TeamRules.teamOne] = 29;
    gameState.gameController.startNewHand();
    gameState.gameController.leadIndex = 0;
    gameState.gameController.turnIndex = 0;

    gameState.showAlVerDecisionDialogForTesting();
    await tester.pumpAndSettle();

    expect(find.text('EstÃƒÂ¡s al ver'), findsOneWidget);
    expect(
      find.text(
        'Tu equipo tiene 29 chinos. Puedes jugar la mano o irte a casa. Si te vas a casa, el equipo rival suma 2 chinos.',
      ),
      findsOneWidget,
    );
    expect(find.text('JUGAR'), findsWidgets);
    expect(find.text('IRSE A CASA'), findsOneWidget);
    expect(find.text('PEDIR SEÃƒâ€˜A'), findsWidgets);

    await tester.tap(find.text('JUGAR').last);
    await tester.pumpAndSettle();

    expect(find.text('EstÃƒÂ¡s al ver'), findsNothing);
    expect(gameState.gameController.alVerState, AlVerState.playing);
  });

  testWidgets('irse a casa concede 2 chinos al rival', (tester) async {
    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.gameController.score[TeamRules.teamOne] = 29;
    gameState.gameController.startNewHand();
    gameState.gameController.leadIndex = 0;
    gameState.gameController.turnIndex = 0;

    gameState.showAlVerDecisionDialogForTesting();
    await tester.pumpAndSettle();

    await tester.tap(find.text('IRSE A CASA'));
    await tester.pumpAndSettle();

    expect(find.text('EstÃƒÂ¡s al ver'), findsNothing);
    expect(gameState.gameController.alVerState, AlVerState.conceded);
    expect(gameState.gameController.score[TeamRules.teamTwo], 2);
    expect(gameState.gameController.handFinished, isTrue);
  });

  testWidgets('la IA resuelve al ver sin mostrar dialogo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.gameController.score[TeamRules.teamTwo] = 29;
    gameState.gameController.startNewHand(fixedHands: _aiBadAlVerHands());
    gameState.gameController.leadIndex = 0;
    gameState.gameController.turnIndex = 0;
    expect(gameState.gameController.alVerState, AlVerState.awaitingDecision);
    expect(gameState.gameController.alVerTeamId, TeamRules.teamTwo);
    await gameState.resolveAlVerDecisionForTesting();
    await tester.pumpAndSettle();

    expect(find.text('EstÃƒÂ¡s al ver'), findsNothing);
    expect(gameState.gameController.alVerState, AlVerState.conceded);
    expect(gameState.gameController.score[TeamRules.teamOne], 2);
    expect(gameState.gameController.handFinished, isTrue);

    await tester.pumpAndSettle();

    expect(gameState.gameController.score[TeamRules.teamOne], 2);
  });

  testWidgets('la IA fuerte juega al ver y continua la mano', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.gameController.score[TeamRules.teamTwo] = 29;
    gameState.gameController.startNewHand(fixedHands: _aiStrongAlVerHands());
    gameState.gameController.leadIndex = 0;
    gameState.gameController.turnIndex = 0;
    expect(gameState.gameController.alVerState, AlVerState.awaitingDecision);
    expect(gameState.gameController.alVerTeamId, TeamRules.teamTwo);
    await gameState.resolveAlVerDecisionForTesting();
    await tester.pumpAndSettle();

    expect(find.text('EstÃƒÂ¡s al ver'), findsNothing);
    expect(gameState.gameController.alVerState, AlVerState.playing);
    expect(gameState.gameController.handFinished, isFalse);
  });

  testWidgets('muestra modal de final de partida con resultado',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await startGame(tester);

    final gameState = tester.state(find.byType(GameScreen)) as dynamic;
    gameState.setState(() {
      gameState.gameController.score[TeamRules.teamOne] = 30;
      gameState.gameController.score[TeamRules.teamTwo] = 24;
      gameState.gameController.winningTeamId = TeamRules.teamOne;
      gameState.gameController.handFinished = true;
    });
    await tester.pumpAndSettle();

    expect(find.text('GanÃƒÂ³ el Equipo 1'), findsOneWidget);
    expect(find.textContaining('Yo y'), findsOneWidget);
    expect(find.text('PuntuaciÃƒÂ³n final: 30 - 24'), findsOneWidget);
    expect(find.text('OTRA PARTIDA'), findsWidgets);

    await tester.tap(find.text('OTRA PARTIDA').last);
    await tester.pumpAndSettle();

    expect(find.text('GanÃƒÂ³ el Equipo 1'), findsNothing);
    expect(gameState.gameController.winningTeamId, isNull);
    expect(gameState.gameController.score[TeamRules.teamOne], 0);
    expect(gameState.gameController.score[TeamRules.teamTwo], 0);
  });
}

Map<String, List<SpanishCard>> _aiBadAlVerHands() {
  return {
    'p1': const [
      SpanishCard(value: 3, suit: Suit.oros),
      SpanishCard(value: 5, suit: Suit.copas),
      SpanishCard(value: 6, suit: Suit.espadas),
    ],
    'p2': const [
      SpanishCard(value: 4, suit: Suit.oros),
      SpanishCard(value: 5, suit: Suit.bastos),
      SpanishCard(value: 6, suit: Suit.copas),
    ],
    'p3': const [
      SpanishCard(value: 10, suit: Suit.espadas),
      SpanishCard(value: 11, suit: Suit.oros),
      SpanishCard(value: 12, suit: Suit.copas),
    ],
    'p4': const [
      SpanishCard(value: 4, suit: Suit.copas),
      SpanishCard(value: 5, suit: Suit.oros),
      SpanishCard(value: 6, suit: Suit.bastos),
    ],
  };
}

Map<String, List<SpanishCard>> _aiStrongAlVerHands() {
  return {
    'p1': const [
      SpanishCard(value: 3, suit: Suit.oros),
      SpanishCard(value: 5, suit: Suit.copas),
      SpanishCard(value: 6, suit: Suit.espadas),
    ],
    'p2': const [
      SpanishCard(value: 4, suit: Suit.oros),
      SpanishCard(value: 5, suit: Suit.bastos),
      SpanishCard(value: 6, suit: Suit.copas),
    ],
    'p3': const [
      SpanishCard(value: 4, suit: Suit.bastos),
      SpanishCard(value: 7, suit: Suit.copas),
      SpanishCard(value: 1, suit: Suit.espadas),
    ],
    'p4': const [
      SpanishCard(value: 7, suit: Suit.oros),
      SpanishCard(value: 3, suit: Suit.bastos),
      SpanishCard(value: 12, suit: Suit.copas),
    ],
  };
}
