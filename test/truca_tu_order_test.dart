import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapiti_app/l10n/zapiti_localizations.dart';
import 'package:zapiti_app/main.dart';
import 'package:zapiti_app/screens/game_screen.dart';
import 'package:zapiti_app/services/app_version_check_service.dart';

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

void main() {
  setUp(() async {
    await ZapitiI18n.load();
    GameScreen.versionCheckService = AppVersionCheckService(
      manifestUri: null,
      installedVersionProvider: () async => '0.1.0',
    );
  });

  testWidgets('muestra Truca tu junto a las otras ordenes del companero',
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

    expect(find.textContaining('TRUCA'), findsOneWidget);
    expect(find.textContaining('VEN A'), findsOneWidget);
    expect(find.text('MATA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('truca tu hace que el companero evalue truco antes de jugar',
      (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.setDifficultyForTesting(4);
    gameState.prepareCompanionBotTrucaTuScenarioForTesting();
    gameState.setBotBetRollForTesting(0.0);
    expect(gameState.shouldOpenCompanionOrderWindowForTesting(), isTrue);
    gameState.sendTrucaTuForTesting();
    await tester.pump();

    expect(
      gameState.offlineRuntimeSnapshotForTesting()['pendingOrders'],
      1,
    );
    final betValue = gameState.evaluateCurrentBotBetForTesting();
    final snapshot =
        gameState.offlineRuntimeSnapshotForTesting() as Map<String, Object?>;
    expect(betValue, 3);
    expect(snapshot['pendingTrucoValue'], isNull);
    expect(snapshot['pendingOrders'], 0);
    expect(snapshot['botCardSelections'], 0);
    expect(gameState.gameController.playedCards, isEmpty);
  });

  testWidgets('truca tu no obliga a apostar con posicion floja', (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.setDifficultyForTesting(4);
    gameState.prepareCompanionBotTrucaTuScenarioForTesting(favorable: false);
    gameState.setBotBetRollForTesting(0.0);
    expect(gameState.shouldOpenCompanionOrderWindowForTesting(), isTrue);
    gameState.sendTrucaTuForTesting();
    await tester.pump();

    final betValue = gameState.evaluateCurrentBotBetForTesting();
    final snapshot =
        gameState.offlineRuntimeSnapshotForTesting() as Map<String, Object?>;
    expect(betValue, isNull);
    expect(snapshot['pendingOrders'], 0);
    expect(gameState.gameController.playedCards, isEmpty);
  });

  testWidgets('truca tu evalua seis y nunca vuelve a truco', (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.setDifficultyForTesting(4);
    gameState.prepareCompanionBotTrucaTuScenarioForTesting(acceptedTruco: true);
    gameState.setBotBetRollForTesting(0.0);
    expect(gameState.shouldOpenCompanionOrderWindowForTesting(), isTrue);
    gameState.sendTrucaTuForTesting();
    await tester.pump();

    final betValue = gameState.evaluateCurrentBotBetForTesting();
    final snapshot =
        gameState.offlineRuntimeSnapshotForTesting() as Map<String, Object?>;
    expect(betValue, 6);
    expect(snapshot['pendingTrucoValue'], isNull);
    expect(snapshot['botCardSelections'], 0);
  });

  testWidgets('truca tu respeta alternancia y no re-sube tras propia subida',
      (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.setDifficultyForTesting(4);
    gameState.prepareCompanionBotTrucaTuScenarioForTesting(
      acceptedTruco: true,
      botLastRaised: true,
    );
    gameState.setBotBetRollForTesting(0.0);
    expect(gameState.shouldOpenCompanionOrderWindowForTesting(), isTrue);
    gameState.sendTrucaTuForTesting();
    await tester.pump();

    final betValue = gameState.evaluateCurrentBotBetForTesting();
    final snapshot =
        gameState.offlineRuntimeSnapshotForTesting() as Map<String, Object?>;
    expect(betValue, isNull);
    expect(snapshot['pendingTrucoValue'], isNull);
    expect(gameState.gameController.playedCards, isEmpty);
  });

  testWidgets('truca tu no produce apuesta ilegal en al ver', (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.setDifficultyForTesting(4);
    gameState.prepareCompanionBotTrucaTuScenarioForTesting(alVer: true);
    expect(gameState.shouldOpenCompanionOrderWindowForTesting(), isFalse);
    gameState.sendTrucaTuForTesting();
    await tester.pump();

    final betValue = gameState.evaluateCurrentBotBetForTesting();
    final snapshot =
        gameState.offlineRuntimeSnapshotForTesting() as Map<String, Object?>;
    expect(betValue, isNull);
    expect(snapshot['pendingOrders'], 0);
    expect(gameState.gameController.playedCards, isEmpty);
  });

  testWidgets('sin truca tu la IA mantiene su politica previa', (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.setDifficultyForTesting(4);
    gameState.prepareCompanionBotTrucaTuScenarioForTesting(favorable: false);
    gameState.setBotBetRollForTesting(0.0);

    final betValue = gameState.evaluateCurrentBotBetForTesting();
    final snapshot =
        gameState.offlineRuntimeSnapshotForTesting() as Map<String, Object?>;
    expect(betValue, isNull);
    expect(snapshot['pendingOrders'], 0);
    expect(gameState.gameController.playedCards, isEmpty);
  });
}
