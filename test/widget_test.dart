import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/zapiti_game_controller.dart';
import 'package:zapiti_app/domain/team_rules.dart';
import 'package:zapiti_app/main.dart';
import 'package:zapiti_app/screens/game_screen.dart';

void main() {
  const musicChannel = MethodChannel('zapiti/music');

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
    expect(find.text('Permitir pasar mano'), findsNothing);
  });

  testWidgets('menu principal abre la seccion acerca de desde portada',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ZapitiApp());

    await tester.ensureVisible(find.text('ACERCA DE'));
    await tester.tap(find.text('ACERCA DE'));
    await tester.pumpAndSettle();

    expect(find.text('Zapiti App'), findsOneWidget);
    expect(find.textContaining('Versión'), findsOneWidget);
    expect(find.text('Juan Francisco Gutiérrez Vázquez'), findsWidgets);
    expect(find.text('Miguel Mateos Borrego'), findsOneWidget);
    expect(find.text('Agradecimientos especiales a la Peña el Trompazo.'),
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

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('Multijugador'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contrasena'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('CREAR USUARIO'), findsOneWidget);
  });

  testWidgets('multijugador recuerda el usuario', (tester) async {
    SharedPreferences.setMockInitialValues({
      'multiplayer_username': 'juan',
    });
    await tester.pumpWidget(const ZapitiApp());

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

    await tester.tap(find.text('MULTIJUGADOR'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesion'), findsOneWidget);
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
    await tester.tap(find.text('Rápida'));
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
      find.text('Equilibrado para probar reglas, señas y ritmo.'),
      findsOneWidget,
    );
    expect(
      find.text('Truca con información de mesa o fuerza real.'),
      findsOneWidget,
    );
    expect(find.text('Muy fácil'), findsOneWidget);
    expect(find.text('Experto'), findsOneWidget);
    expect(find.text('Bots distraídos, errores claros y trucos precipitados.'),
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
    expect(find.text('Compañero'), findsOneWidget);
    expect(find.text('Jugador rival 1'), findsOneWidget);
    expect(find.text('Jugador rival 2'), findsOneWidget);
    expect(find.text('Eq1'), findsOneWidget);
    expect(find.text('Eq2'), findsOneWidget);
    expect(find.text('Rondas'), findsOneWidget);
    expect(find.text('0 - 0'), findsOneWidget);
    expect(find.text('Señas'), findsNothing);
    expect(find.text('PEDIR SEÑA'), findsOneWidget);
    expect(find.text('DEV'), findsNothing);
    expect(find.text('Manos prefijadas'), findsNothing);
  });

  testWidgets('ayuda de señas muestra orden de cartas y señales',
      (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('AYUDA SEÑAS'));
    await tester.pumpAndSettle();

    expect(find.text('Orden y señas'), findsOneWidget);
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
    expect(find.text('Orden Númerico de Valor'), findsNothing);

    await tester.tap(find.text('CERRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Orden y señas'), findsNothing);
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

  testWidgets('pedir seña muestra respuesta en landscape', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await startGame(tester);

    await tester.tap(find.text('PEDIR SEÑA'));
    await tester.pump();

    expect(find.text('Compa mira...'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('voy a ti cambia a mata si no es el turno humano',
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

    expect(find.text('MATA'), findsOneWidget);
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

    expect(find.text('Opciones'), findsOneWidget);
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

    expect(find.text('Estás al ver'), findsOneWidget);
    expect(
      find.text(
        'Tu equipo tiene 29 chinos. Puedes jugar la mano o irte a casa. Si te vas a casa, el equipo rival suma 2 chinos.',
      ),
      findsOneWidget,
    );
    expect(find.text('JUGAR'), findsWidgets);
    expect(find.text('IRSE A CASA'), findsOneWidget);
    expect(find.text('PEDIR SEÑA'), findsWidgets);

    await tester.tap(find.text('JUGAR').last);
    await tester.pumpAndSettle();

    expect(find.text('Estás al ver'), findsNothing);
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

    expect(find.text('Estás al ver'), findsNothing);
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

    expect(find.text('Estás al ver'), findsNothing);
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

    expect(find.text('Estás al ver'), findsNothing);
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

    expect(find.text('Ganó el Equipo 1'), findsOneWidget);
    expect(find.textContaining('Yo y'), findsOneWidget);
    expect(find.text('Puntuación final: 30 - 24'), findsOneWidget);
    expect(find.text('OTRA PARTIDA'), findsWidgets);

    await tester.tap(find.text('OTRA PARTIDA').last);
    await tester.pumpAndSettle();

    expect(find.text('Ganó el Equipo 1'), findsNothing);
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
