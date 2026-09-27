import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_bet_value_evaluator.dart';
import 'package:zapiti_app/domain/legal_actions.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  const evaluator = BotBetValueEvaluator();
  const weak = HandEvaluation(
    winProbability: 0.08,
    expectedHandValue: -0.68,
    confidence: 0.7,
  );
  const medium = HandEvaluation(
    winProbability: 0.57,
    expectedHandValue: 1.28,
    confidence: 0.7,
  );
  const strong = HandEvaluation(
    winProbability: 0.95,
    expectedHandValue: 2.8,
    confidence: 0.7,
  );

  test('BET-AI-001 extremely favorable hand values opening Truco', () {
    final actions = [const BetAction.call(3)];
    expect(_opening(evaluator, strong, actions), isNull);
    expect(
      _opening(
        evaluator,
        const HandEvaluation(
          winProbability: 0.99,
          expectedHandValue: 2.96,
          confidence: 0.95,
        ),
        actions,
      ),
      actions.single,
    );
  });

  test('BET-AGGRESSION-001 moderate odds do not open at Hard or Expert', () {
    for (final difficulty in [4, 5]) {
      expect(_openingAtDifficulty(evaluator, medium, difficulty), isNull);
    }
  });

  test('BET-AGGRESSION-002/003 strong and extraordinary odds can open', () {
    for (final difficulty in [4, 5]) {
      expect(_openingAtDifficulty(evaluator, strong, difficulty),
          difficulty >= 5 ? isNull : const BetAction.call(3));
      expect(
        _openingAtDifficulty(
          evaluator,
          const HandEvaluation(
            winProbability: 0.99,
            expectedHandValue: 2.96,
            confidence: 0.95,
          ),
          difficulty,
        ),
        const BetAction.call(3),
      );
    }
  });

  test('BET-AGGRESSION-004 small evaluation changes have continuous utility',
      () {
    const lower = HandEvaluation(
      winProbability: 0.72,
      expectedHandValue: 1.88,
      confidence: 0.7,
    );
    const higher = HandEvaluation(
      winProbability: 0.74,
      expectedHandValue: 1.96,
      confidence: 0.7,
    );
    double value(HandEvaluation hand) => evaluator.actionValue(
          action: const BetAction.call(3),
          hand: hand,
          teamScore: 5,
          opponentScore: 5,
          targetScore: 30,
          acceptedValue: 1,
          pendingValue: 1,
          proposedValue: 3,
          difficulty: 4,
        );
    expect((value(higher) - value(lower)).abs(), lessThan(0.12));
  });

  test('BET-AI-002 very weak hand prefers passing Truco', () {
    expect(
        _response(
            evaluator,
            weak,
            [
              const BetAction.accept(),
              const BetAction.pass(),
            ],
            pending: 3),
        const BetAction.pass());
  });

  test('BET-AI-003 favorable hand accepts Truco', () {
    expect(
        _response(
            evaluator,
            strong,
            [
              const BetAction.accept(),
              const BetAction.pass(),
            ],
            pending: 3),
        const BetAction.accept());
  });

  test('BET-AI-004 extreme advantage can choose legal Seis raise', () {
    expect(
        _response(
            evaluator,
            strong,
            [
              const BetAction.accept(),
              const BetAction.pass(),
              const BetAction.call(6),
            ],
            pending: 3),
        const BetAction.call(6));
  });

  test('BET-FLOW-002 contra-subida se compara directamente con aceptar', () {
    const actions = [
      BetAction.accept(),
      BetAction.pass(),
      BetAction.call(9),
    ];
    expect(_response(evaluator, strong, actions, pending: 6),
        const BetAction.call(9));
  });

  test('BET-AI-005 moderate position does not raise automatically', () {
    expect(
        _response(
            evaluator,
            medium,
            [
              const BetAction.accept(),
              const BetAction.pass(),
              const BetAction.call(6),
            ],
            pending: 3),
        isNot(const BetAction.call(6)));
  });

  test('BET-AI-006 score changes action value near match point', () {
    final base = _acceptValue(evaluator, strong, score: 5, pending: 6);
    final close = _acceptValue(evaluator, strong, score: 28, pending: 6);
    expect(close, isNot(base));
  });

  test('BET-AI-007 high levels carry higher downside', () {
    final six = _acceptValue(evaluator, medium, score: 5, pending: 6);
    final fifteen = _acceptValue(evaluator, medium, score: 5, pending: 15);
    expect(fifteen, lessThan(six));
  });

  test('BET-AI-008 Ahorrisi requires extreme rather than mediocre odds', () {
    final actions = [
      const BetAction.accept(),
      const BetAction.pass(),
      const BetAction.call(30),
    ];
    expect(_response(evaluator, strong, actions, pending: 15),
        const BetAction.call(30));
    expect(_response(evaluator, medium, actions, pending: 15),
        isNot(const BetAction.call(30)));
  });

  test('BET-AI-009 opening requires clear odds even when invited', () {
    final legal = [const BetAction.call(3)];
    expect(_opening(evaluator, strong, legal), isNull);
    expect(_opening(evaluator, weak, legal), isNull);
  });

  test('BET-AI-010 no legal actions means no bet is evaluated', () {
    expect(_opening(evaluator, strong, const []), isNull);
  });

  test('BET-AI-011 betting evaluation leaves cards available for later play',
      () {
    const hand = [
      SpanishCard(value: 12, suit: Suit.bastos),
      SpanishCard(value: 11, suit: Suit.oros),
      SpanishCard(value: 10, suit: Suit.copas),
    ];
    final evaluation = evaluator.evaluateHand(
      ownHand: hand,
      cardsOnTable: 2,
      teamRoundWins: 1,
      opponentRoundWins: 0,
    );
    expect(evaluation.winProbability, greaterThan(0.5));
    expect(hand, hasLength(3));
  });

  test('win probability calibration is monotonic and corrects overestimation',
      () {
    const raw = [0.25, 0.35, 0.45, 0.55, 0.65, 0.74, 0.825];
    final calibrated =
        raw.map(BotBetValueEvaluator.calibrateWinProbability).toList();
    for (var i = 1; i < calibrated.length; i++) {
      expect(calibrated[i], greaterThanOrEqualTo(calibrated[i - 1]));
    }
    expect(BotBetValueEvaluator.calibrateWinProbability(0.65),
        closeTo(0.473, 0.001));
    expect(BotBetValueEvaluator.calibrateWinProbability(0.74),
        closeTo(0.584, 0.001));
  });
}

BetAction? _opening(
  BotBetValueEvaluator evaluator,
  HandEvaluation hand,
  List<BetAction> legal,
) =>
    evaluator.chooseAction(
      legalActions: legal,
      hand: hand,
      teamScore: 5,
      opponentScore: 5,
      targetScore: 30,
      acceptedValue: 1,
      pendingValue: 1,
      difficulty: 5,
    );

BetAction? _openingAtDifficulty(
  BotBetValueEvaluator evaluator,
  HandEvaluation hand,
  int difficulty,
) =>
    evaluator.chooseAction(
      legalActions: const [BetAction.call(3)],
      hand: hand,
      teamScore: 5,
      opponentScore: 5,
      targetScore: 30,
      acceptedValue: 1,
      pendingValue: 1,
      difficulty: difficulty,
    );

BetAction? _response(
  BotBetValueEvaluator evaluator,
  HandEvaluation hand,
  List<BetAction> legal, {
  required int pending,
}) =>
    evaluator.chooseAction(
      legalActions: legal,
      hand: hand,
      teamScore: 5,
      opponentScore: 5,
      targetScore: 30,
      acceptedValue: 1,
      pendingValue: pending,
      difficulty: 5,
    );

double _acceptValue(
  BotBetValueEvaluator evaluator,
  HandEvaluation hand, {
  required int score,
  required int pending,
}) =>
    evaluator.actionValue(
      action: const BetAction.accept(),
      hand: hand,
      teamScore: score,
      opponentScore: 10,
      targetScore: 30,
      acceptedValue: 1,
      pendingValue: pending,
      proposedValue: pending,
      difficulty: 5,
    );
