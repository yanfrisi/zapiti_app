import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zapiti_app/l10n/zapiti_localizations.dart';
import 'package:zapiti_app/main.dart';
import 'package:zapiti_app/screens/game_screen.dart';
import 'package:zapiti_app/services/app_version_check_service.dart';

void main() {
  const postOrderVisualDelay = Duration(milliseconds: 550);
  const finishAutoBotFlow = Duration(seconds: 4);

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

    final startButton = find.text('EMPEZAR PARTIDA');
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    final playButton = find.text('JUGAR');
    await tester.ensureVisible(playButton);
    await tester.tap(playButton);
    await tester.pumpAndSettle();
  }

  testWidgets('el companero IA siempre juega y cede el turno', (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.prepareCompanionBotOrderWindowScenarioForTesting(
      companionPlaysBeforeHuman: true,
    );
    gameState.setBotBetRollForTesting(0.99);

    final advance = gameState.advanceBotsForTesting();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      gameState.offlineRuntimeSnapshotForTesting()['companionOrderWindowPlayerId'],
      'p3',
    );

    gameState.sendComeToMeForTesting();
    await tester.pump(postOrderVisualDelay);

    expect(gameState.gameController.playedCards, hasLength(1));
    expect(gameState.gameController.playedCards.single.player.id, 'p3');
    expect(gameState.gameController.currentPlayer.id, isNot('p3'));

    await tester.pump(finishAutoBotFlow);
    await advance;
  });

  testWidgets('aceptar truco cierra el overlay y la partida continua',
      (tester) async {
    await startGame(tester);
    final gameState = tester.state(find.byType(GameScreen)) as dynamic;

    gameState.prepareIncomingTrucoResponseForTesting();
    await tester.pump();

    expect(find.text('ACEPTAR'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump(finishAutoBotFlow);
    await tester.pumpAndSettle();

    final snapshot =
        gameState.offlineRuntimeSnapshotForTesting() as Map<String, Object?>;
    expect(snapshot['pendingTrucoValue'], isNull);
    expect(snapshot['trucoState'], isNot('awaitingResponse'));
    expect(gameState.gameController.playedCards, isNotEmpty);
  });
}
