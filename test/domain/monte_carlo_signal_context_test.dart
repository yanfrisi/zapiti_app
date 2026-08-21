import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bet_state.dart';
import 'package:zapiti_app/domain/bot_agent_difficulty.dart';
import 'package:zapiti_app/domain/monte_carlo_card_selector.dart';
import 'package:zapiti_app/domain/monte_carlo_difficulty_config.dart';
import 'package:zapiti_app/domain/observable_game_state.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/signal_context.dart';
import 'package:zapiti_app/domain/simulation_evaluator.dart';
import 'package:zapiti_app/domain/simulation_game_state.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/domain/team_rules.dart';

void main() {
  const human = Player(id: 'p1', name: 'Human', teamId: TeamRules.teamOne);
  const rivalOne = Player(id: 'p2', name: 'Rival 1', teamId: TeamRules.teamTwo);
  const companion = Player(id: 'p3', name: 'Companion', teamId: TeamRules.teamOne);
  const rivalTwo = Player(id: 'p4', name: 'Rival 2', teamId: TeamRules.teamTwo);
  const players = [human, rivalOne, companion, rivalTwo];
  final selector = MonteCarloCardSelector();

  ObservableGameState stateFor({
    required String botPlayerId,
    required List<SpanishCard> botHand,
    required List<PlayedCard> playedCards,
    SignalContext signalContext = SignalContext.empty,
  }) {
    return ObservableGameState(
      botPlayerId: botPlayerId,
      players: players,
      botHand: botHand,
      playedCards: playedCards,
      cardsRemainingByPlayerId: const {
        'p1': 3,
        'p2': 2,
        'p3': 3,
        'p4': 3,
      },
      publiclyKnownCardsByPlayerId: const {},
      currentPlayerId: botPlayerId,
      trickLeaderId: playedCards.isEmpty ? botPlayerId : playedCards.first.player.id,
      betState: const BetState(
        acceptedLevel: BetLevel.none,
        proposedLevel: null,
        proposingTeam: null,
        respondingTeam: null,
        lastRaisingTeam: null,
        responsePending: false,
      ),
      score: const {TeamRules.teamOne: 0, TeamRules.teamTwo: 0},
      roundWins: const {TeamRules.teamOne: 0, TeamRules.teamTwo: 0},
      visibleSignals: const [],
      signalContext: signalContext,
      handVersion: 1,
      trickIndex: 0,
    );
  }

  test('Mata prioriza ganar con la carta minima suficiente', () {
    const mediumWinner = SpanishCard(value: 2, suit: Suit.copas);
    const maximum = SpanishCard(value: 4, suit: Suit.bastos);
    final state = stateFor(
      botPlayerId: companion.id,
      botHand: const [
        SpanishCard(value: 5, suit: Suit.oros),
        mediumWinner,
        maximum,
      ],
      playedCards: const [
        PlayedCard(
          player: rivalOne,
          card: SpanishCard(value: 12, suit: Suit.oros),
        ),
      ],
      signalContext: const SignalContext(
        signals: [
          StrategicSignal(
            type: StrategicSignalType.mata,
            issuerPlayerId: 'p1',
            targetPlayerId: 'p3',
            teamId: TeamRules.teamOne,
            handVersion: 1,
            trickIndex: 0,
          ),
        ],
      ),
    );

    final chosen = selector.selectCard(
      botPlayerId: companion.id,
      state: state,
      config: MonteCarloDifficultyConfigs.hard,
    );

    expect(chosen, mediumWinner);
  });

  test('Ven a mi favorece conservar recursos del companero', () {
    const low = SpanishCard(value: 5, suit: Suit.oros);
    const maximum = SpanishCard(value: 4, suit: Suit.bastos);
    final state = stateFor(
      botPlayerId: companion.id,
      botHand: const [
        low,
        SpanishCard(value: 2, suit: Suit.copas),
        maximum,
      ],
      playedCards: const [
        PlayedCard(
          player: human,
          card: SpanishCard(value: 12, suit: Suit.oros),
        ),
      ],
      signalContext: const SignalContext(
        signals: [
          StrategicSignal(
            type: StrategicSignalType.venAMi,
            issuerPlayerId: 'p1',
            targetPlayerId: 'p3',
            teamId: TeamRules.teamOne,
            handVersion: 1,
            trickIndex: 0,
          ),
        ],
      ),
    );

    final chosen = selector.selectCard(
      botPlayerId: companion.id,
      state: state,
      config: MonteCarloDifficultyConfigs.hard,
    );

    expect(chosen, low);
  });

  test('Voy a ti conserva recursos del emisor', () {
    const low = SpanishCard(value: 5, suit: Suit.oros);
    final state = stateFor(
      botPlayerId: human.id,
      botHand: const [
        low,
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.bastos),
      ],
      playedCards: const [
        PlayedCard(
          player: rivalOne,
          card: SpanishCard(value: 12, suit: Suit.oros),
        ),
      ],
      signalContext: const SignalContext(
        signals: [
          StrategicSignal(
            type: StrategicSignalType.voyATi,
            issuerPlayerId: 'p1',
            targetPlayerId: 'p1',
            teamId: TeamRules.teamOne,
            handVersion: 1,
            trickIndex: 0,
          ),
        ],
      ),
    );

    final chosen = selector.selectCard(
      botPlayerId: human.id,
      state: state,
      config: MonteCarloDifficultyConfigs.hard,
    );

    expect(chosen, low);
  });

  test('senal de carta no observada no se infiere desde mano simulada', () {
    const evaluator = TeamSimulationEvaluator();
    final baseState = SimulationGameState(
      players: const [
        SimulationPlayerState(
          player: human,
          hand: [SpanishCard(value: 5, suit: Suit.oros)],
        ),
        SimulationPlayerState(
          player: rivalOne,
          hand: [SpanishCard(value: 4, suit: Suit.bastos)],
        ),
        SimulationPlayerState(
          player: companion,
          hand: [SpanishCard(value: 6, suit: Suit.oros)],
        ),
        SimulationPlayerState(
          player: rivalTwo,
          hand: [SpanishCard(value: 7, suit: Suit.oros)],
        ),
      ],
      currentTrick: const [],
      playedCards: const [],
      completedTricks: const [],
      currentPlayerId: human.id,
      trickLeaderId: human.id,
      betState: const BetState(
        acceptedLevel: BetLevel.none,
        proposedLevel: null,
        proposingTeam: null,
        respondingTeam: null,
        lastRaisingTeam: null,
        responsePending: false,
      ),
      score: const {TeamRules.teamOne: 0, TeamRules.teamTwo: 0},
      roundWins: const {TeamRules.teamOne: 0, TeamRules.teamTwo: 0},
      roundNumber: 1,
      isRoundFinished: false,
      isHandFinished: false,
    );
    final withObservedSignal = SimulationGameState(
      players: baseState.players,
      currentTrick: baseState.currentTrick,
      playedCards: baseState.playedCards,
      completedTricks: baseState.completedTricks,
      currentPlayerId: baseState.currentPlayerId,
      trickLeaderId: baseState.trickLeaderId,
      betState: baseState.betState,
      score: baseState.score,
      roundWins: baseState.roundWins,
      roundNumber: baseState.roundNumber,
      isRoundFinished: baseState.isRoundFinished,
      isHandFinished: baseState.isHandFinished,
      signalContext: const SignalContext(
        signals: [
          StrategicSignal(
            type: StrategicSignalType.cardSignal,
            issuerPlayerId: 'p2',
            teamId: TeamRules.teamTwo,
            handVersion: 1,
            trickIndex: 0,
          ),
        ],
      ),
    );

    final privateOnly = evaluator.evaluate(baseState, human.id);
    final observed = evaluator.evaluate(withObservedSignal, human.id);

    expect(observed, isNot(privateOnly));
  });

  test('dificultad del companero se mantiene normal contra Hard y Expert', () {
    expect(
      BotAgentDifficulty.forOfflineBot(
        bot: companion,
        human: human,
        companion: companion,
        selectedDifficulty: 4,
      ),
      3,
    );
    expect(
      BotAgentDifficulty.forOfflineBot(
        bot: companion,
        human: human,
        companion: companion,
        selectedDifficulty: 5,
      ),
      3,
    );
    expect(
      BotAgentDifficulty.forOfflineBot(
        bot: rivalOne,
        human: human,
        companion: companion,
        selectedDifficulty: 5,
      ),
      5,
    );
  });
}
