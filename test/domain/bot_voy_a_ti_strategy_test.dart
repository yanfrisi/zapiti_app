import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_voy_a_ti_strategy.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('BotVoyATiStrategy', () {
    const human = Player(id: 'p1', name: 'Humano', teamId: 1);
    const rivalRight = Player(id: 'p2', name: 'Rival 1', teamId: 2);
    const companion = Player(id: 'p3', name: 'Compa', teamId: 1);
    const rivalLeft = Player(id: 'p4', name: 'Rival 2', teamId: 2);
    const players = [human, rivalRight, companion, rivalLeft];
    const companionBeforeHumanPlayers = [
      rivalRight,
      companion,
      rivalLeft,
      human,
    ];

    test('tira la menor si no puede ganar la mesa', () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 1, suit: Suit.copas),
      ];
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 4, suit: Suit.bastos),
        ),
      ];

      final chosen = BotVoyATiStrategy.chooseCard(
        bot: companion,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: const {'p3': hand},
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('gana con la carta mas baja si puede superar la mesa', () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.bastos),
      ];
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 1, suit: Suit.copas),
        ),
      ];

      final chosen = BotVoyATiStrategy.chooseCard(
        bot: companion,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: const {'p3': hand},
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('pide voy a ti al humano si el companero va antes y conviene', () {
      const botHand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 4, suit: Suit.bastos),
      ];
      const humanHand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 11, suit: Suit.espadas),
      ];
      const rivalLeftHand = [
        SpanishCard(value: 12, suit: Suit.copas),
        SpanishCard(value: 10, suit: Suit.espadas),
      ];
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 1, suit: Suit.copas),
        ),
      ];

      final shouldAsk = BotVoyATiStrategy.shouldAskTeammateToWin(
        bot: companion,
        teammate: human,
        players: companionBeforeHumanPlayers,
        hands: const {
          'p1': humanHand,
          'p2': [],
          'p3': botHand,
          'p4': rivalLeftHand,
        },
        playedCards: playedCards,
        teamRoundWins: 0,
        opponentRoundWins: 1,
        handValue: 3,
        difficulty: 5,
        roll: 0,
      );

      expect(shouldAsk, isTrue);
    });

    test('no pide voy a ti si el humano no puede ganar la mesa', () {
      const botHand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 4, suit: Suit.bastos),
      ];
      const humanHand = [
        SpanishCard(value: 12, suit: Suit.copas),
        SpanishCard(value: 11, suit: Suit.espadas),
      ];
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 1, suit: Suit.copas),
        ),
      ];

      final shouldAsk = BotVoyATiStrategy.shouldAskTeammateToWin(
        bot: companion,
        teammate: human,
        players: companionBeforeHumanPlayers,
        hands: const {
          'p1': humanHand,
          'p3': botHand,
        },
        playedCards: playedCards,
        teamRoundWins: 0,
        opponentRoundWins: 1,
        handValue: 3,
        difficulty: 5,
        roll: 0,
      );

      expect(shouldAsk, isFalse);
    });

    test('no pide voy a ti si el bot puede ganar sin gastar carta fuerte', () {
      const botHand = [
        SpanishCard(value: 6, suit: Suit.oros),
        SpanishCard(value: 12, suit: Suit.bastos),
      ];
      const humanHand = [
        SpanishCard(value: 7, suit: Suit.copas),
        SpanishCard(value: 11, suit: Suit.espadas),
      ];
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 5, suit: Suit.copas),
        ),
      ];

      final shouldAsk = BotVoyATiStrategy.shouldAskTeammateToWin(
        bot: companion,
        teammate: human,
        players: companionBeforeHumanPlayers,
        hands: const {
          'p1': humanHand,
          'p3': botHand,
        },
        playedCards: playedCards,
        teamRoundWins: 0,
        opponentRoundWins: 1,
        handValue: 3,
        difficulty: 5,
        roll: 0,
      );

      expect(shouldAsk, isFalse);
    });

    test('no pide voy a ti si el humano ganaria con mucho riesgo oculto', () {
      const botHand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 4, suit: Suit.bastos),
      ];
      const humanHand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 11, suit: Suit.espadas),
      ];
      const rivalLeftHand = [
        SpanishCard(value: 1, suit: Suit.espadas),
        SpanishCard(value: 5, suit: Suit.espadas),
      ];
      const playedCards = [
        PlayedCard(
          player: rivalRight,
          card: SpanishCard(value: 1, suit: Suit.bastos),
        ),
      ];

      final shouldAsk = BotVoyATiStrategy.shouldAskTeammateToWin(
        bot: companion,
        teammate: human,
        players: companionBeforeHumanPlayers,
        hands: const {
          'p1': humanHand,
          'p2': [],
          'p3': botHand,
          'p4': rivalLeftHand,
        },
        playedCards: playedCards,
        teamRoundWins: 0,
        opponentRoundWins: 1,
        handValue: 3,
        difficulty: 5,
        roll: 0,
      );

      expect(shouldAsk, isFalse);
    });
  });
}
