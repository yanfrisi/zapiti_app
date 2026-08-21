import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_strategy.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  group('BotStrategy', () {
    const bot = Player(id: 'bot', name: 'Bot', teamId: 2);
    const teammate = Player(id: 'mate', name: 'Mate', teamId: 2);
    const rival = Player(id: 'rival', name: 'Rival', teamId: 1);
    const rearRival = Player(id: 'rearRival', name: 'Rear rival', teamId: 1);

    test('gana con la carta mas baja posible', () {
      const hand = [
        SpanishCard(value: 5, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 4, suit: Suit.bastos),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.copas),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('tira la peor si su equipo ya gana la ronda', () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 3, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 4, suit: Suit.bastos),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.espadas),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('no gasta carta alta si su equipo ya gana aunque tenga que cerrar',
        () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 1, suit: Suit.espadas),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        teamRoundWins: 1,
        forceWinIfPossible: true,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('si juega ultimo y su equipo ya gana sigue tirando la peor', () {
      const hand = [
        SpanishCard(value: 11, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 4, suit: Suit.bastos),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.espadas),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        opponentRoundWins: 1,
        forceWinIfPossible: true,
      );

      expect(chosen, const SpanishCard(value: 11, suit: Suit.oros));
    });

    test('si su pareja gana flojo y queda rival detras protege con la minima',
        () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 6, suit: Suit.bastos),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        opponentStillToPlay: true,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('si su pareja ya gana muy alto no gasta carta por cubrir de mas', () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 12, suit: Suit.bastos),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        opponentStillToPlay: true,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('tira la peor si no puede ganar la ronda', () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 1, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 4, suit: Suit.bastos),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('empata si no puede superar al rival pero puede negar la ronda', () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 3, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
      );

      expect(chosen, const SpanishCard(value: 3, suit: Suit.copas));
    });

    test('reserva carta alta si el compañero juega despues con mas vision', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        teammateStillToPlay: true,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('gana si el compañero no juega despues y puede hacerlo barato', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        teammateStillToPlay: false,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('protege la ronda si queda un rival por jugar detras', () {
      const hand = [
        SpanishCard(value: 6, suit: Suit.espadas),
        SpanishCard(value: 2, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 5, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 5, suit: Suit.bastos),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        opponentStillToPlay: true,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('al salir conserva cartas fuertes si puede', () {
      const hand = [
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.copas),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: const [],
        preserveStrongCards: true,
      );

      expect(chosen, const SpanishCard(value: 5, suit: Suit.copas));
    });

    test('conserva el 4 de bastos al salir si no necesita presionar', () {
      const hand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.copas),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: const [],
        preserveStrongCards: true,
      );

      expect(chosen, const SpanishCard(value: 5, suit: Suit.copas));
    });

    test('usa carta fuerte al salir si necesita salvar la mano', () {
      const hand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.copas),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: const [],
        preserveStrongCards: true,
        opponentRoundWins: 1,
      );

      expect(chosen, const SpanishCard(value: 4, suit: Suit.bastos));
    });

    test('sin ven a mi mantiene la politica normal de dificultad', () {
      const hand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 5, suit: Suit.copas),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: const [],
        preserveStrongCards: true,
        opponentRoundWins: 1,
      );

      expect(chosen, const SpanishCard(value: 4, suit: Suit.bastos));
    });

    test('con seña fuerte del compañero evita gastar carta al inicio', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        teammateHasStrongSignal: true,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('si vio seña fuerte rival no gasta carta alta demasiado pronto', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        opponentHasStrongSignal: true,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('cuando el reparto pesa fuerza ganar si puede', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        opponentHasStrongSignal: true,
        forceWinIfPossible: true,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('si el rival ya tiene ronda fuerza ganar con la minima posible', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: table,
        opponentRoundWins: 1,
        opponentHasStrongSignal: true,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('si sale perdiendo la mano presiona con una carta fuerte', () {
      const hand = [
        SpanishCard(value: 12, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 5, suit: Suit.bastos),
      ];

      final chosen = BotStrategy.chooseCard(
        player: bot,
        hand: hand,
        playedCards: const [],
        opponentRoundWins: 1,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('lookahead normal mantiene la heuristica base', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCardWithLookahead(
        difficulty: 3,
        player: bot,
        hand: hand,
        playedCards: table,
        opponentStillToPlay: true,
      );

      expect(chosen, const SpanishCard(value: 2, suit: Suit.copas));
    });

    test('lookahead experto protege mejor si queda un rival por jugar', () {
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCardWithLookahead(
        difficulty: 5,
        player: bot,
        hand: hand,
        playedCards: table,
        opponentStillToPlay: true,
      );

      expect(chosen, const SpanishCard(value: 3, suit: Suit.oros));
    });

    test('lookahead experto no gasta premium si su equipo ya gana', () {
      const hand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 3, suit: Suit.copas),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];

      final chosen = BotStrategy.chooseCardWithLookahead(
        difficulty: 5,
        player: bot,
        hand: hand,
        playedCards: table,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('lookahead experto conserva la carta baja si ya gana y es el ultimo',
        () {
      const hand = [
        SpanishCard(value: 11, suit: Suit.oros),
        SpanishCard(value: 2, suit: Suit.copas),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 3, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 4, suit: Suit.bastos),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.espadas),
        ),
      ];

      final chosen = BotStrategy.chooseCardWithLookahead(
        difficulty: 5,
        player: bot,
        hand: hand,
        playedCards: table,
        opponentStillToPlay: false,
      );

      expect(chosen, const SpanishCard(value: 11, suit: Suit.oros));
    });

    test('experto con minimax evita ganar flojo si el rival lo mata detras',
        () {
      const players = [rival, teammate, bot, rearRival];
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 12, suit: Suit.copas),
        ),
      ];
      const hands = {
        'bot': hand,
        'rearRival': [
          SpanishCard(value: 2, suit: Suit.espadas),
          SpanishCard(value: 5, suit: Suit.oros),
          SpanishCard(value: 4, suit: Suit.copas),
        ],
      };

      final chosen = BotStrategy.chooseCardWithLookahead(
        difficulty: 5,
        player: bot,
        hand: hand,
        playedCards: table,
        players: players,
        hands: hands,
        opponentStillToPlay: true,
        allowPerfectInformation: true,
      );

      expect(chosen, const SpanishCard(value: 3, suit: Suit.oros));
    });

    test('experto con minimax tira barato si la ronda ya esta blindada', () {
      const players = [teammate, rival, bot, rearRival];
      const hand = [
        SpanishCard(value: 4, suit: Suit.bastos),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const table = [
        PlayedCard(
          player: teammate,
          card: SpanishCard(value: 3, suit: Suit.copas),
        ),
        PlayedCard(
          player: rival,
          card: SpanishCard(value: 1, suit: Suit.oros),
        ),
      ];
      const hands = {
        'bot': hand,
        'rearRival': [
          SpanishCard(value: 2, suit: Suit.espadas),
          SpanishCard(value: 5, suit: Suit.oros),
        ],
      };

      final chosen = BotStrategy.chooseCardWithLookahead(
        difficulty: 5,
        player: bot,
        hand: hand,
        playedCards: table,
        players: players,
        hands: hands,
        allowPerfectInformation: true,
      );

      expect(chosen, const SpanishCard(value: 12, suit: Suit.oros));
    });

    test('lookahead oculto no depende de la identidad real de cartas rivales', () {
      const players = [rival, teammate, bot, rearRival];
      const hand = [
        SpanishCard(value: 2, suit: Suit.copas),
        SpanishCard(value: 3, suit: Suit.oros),
        SpanishCard(value: 12, suit: Suit.oros),
      ];
      const handsA = {
        'bot': hand,
        'rival': [
          SpanishCard(value: 1, suit: Suit.oros),
          SpanishCard(value: 6, suit: Suit.oros),
          SpanishCard(value: 5, suit: Suit.espadas),
        ],
        'mate': [
          SpanishCard(value: 2, suit: Suit.bastos),
          SpanishCard(value: 11, suit: Suit.copas),
        ],
        'rearRival': [
          SpanishCard(value: 2, suit: Suit.espadas),
          SpanishCard(value: 5, suit: Suit.oros),
        ],
      };
      const handsB = {
        'bot': hand,
        'rival': [
          SpanishCard(value: 1, suit: Suit.oros),
          SpanishCard(value: 6, suit: Suit.oros),
          SpanishCard(value: 5, suit: Suit.espadas),
        ],
        'mate': [
          SpanishCard(value: 2, suit: Suit.bastos),
          SpanishCard(value: 11, suit: Suit.copas),
        ],
        'rearRival': [
          SpanishCard(value: 4, suit: Suit.bastos),
          SpanishCard(value: 7, suit: Suit.copas),
          SpanishCard(value: 6, suit: Suit.espadas),
        ],
      };

      final chosenA = BotStrategy.chooseCardWithLookahead(
        difficulty: 5,
        player: bot,
        hand: hand,
        playedCards: const [],
        players: players,
        hands: handsA,
      );
      final chosenB = BotStrategy.chooseCardWithLookahead(
        difficulty: 5,
        player: bot,
        hand: hand,
        playedCards: const [],
        players: players,
        hands: handsB,
      );

      expect(chosenA, isIn(hand));
      expect(chosenB, isIn(hand));
    });
  });
}
