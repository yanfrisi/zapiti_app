import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapiti_app/main.dart';

void main() {
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

    expect(find.text('Tutorial'), findsOneWidget);
    expect(
        find.text('1. Juegas en pareja contra dos rivales.'), findsOneWidget);
    expect(find.text('VOLVER'), findsOneWidget);

    await tester.tap(find.text('VOLVER'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();

    expect(find.text('Opciones'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Mostrar ayuda'), findsNothing);
  });

  testWidgets('menu principal muestra multijugador como proximamente',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('Multijugador'), findsOneWidget);
    expect(find.text('Lobby multijugador'), findsOneWidget);
    expect(find.text('Servidor'), findsOneWidget);
    expect(find.text('Codigo de sala'), findsOneWidget);
    expect(find.text('CREAR'), findsOneWidget);
    expect(find.text('UNIRSE'), findsOneWidget);
  });

  testWidgets('multijugador no desborda en movil horizontal', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('Lobby multijugador'), findsOneWidget);
    expect(find.text('Codigo de sala'), findsOneWidget);
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
    await tester.tap(find.text('Rapida'));
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
      find.text('Equilibrado para probar reglas, senas y ritmo.'),
      findsOneWidget,
    );
    expect(
      find.text('Truca con informacion de mesa o fuerza real.'),
      findsOneWidget,
    );
    expect(find.text('Muy facil'), findsOneWidget);
    expect(find.text('Experto'), findsOneWidget);
    expect(find.text('Bots distraidos, mas errores y trucos flojos.'),
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
    expect(find.text('Yo'), findsNothing);
    expect(find.text('Compañero'), findsNothing);
    expect(find.text('Jugador rival 1'), findsNothing);
    expect(find.text('Jugador rival 2'), findsNothing);
    expect(find.text('Eq1'), findsOneWidget);
    expect(find.text('Eq2'), findsOneWidget);
    expect(find.text('Rondas'), findsOneWidget);
    expect(find.text('0 - 0'), findsOneWidget);
    expect(find.text('Senas'), findsNothing);
    expect(find.text('PEDIR SENA'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(find.text('Manos prefijadas'), findsNothing);
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
    const Size(932, 430),
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

  testWidgets('pedir sena muestra respuesta en landscape', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('PEDIR SENA'));
    await tester.pump();

    expect(find.text('Compa mira...'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('opciones desde la mesa no muestra ayuda', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('OPCIONES'));
    await tester.pumpAndSettle();

    expect(find.text('Opciones'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Mostrar ayuda'), findsNothing);
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

    expect(find.text('TUTORIAL'), findsOneWidget);
    expect(find.text('OPCIONES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
