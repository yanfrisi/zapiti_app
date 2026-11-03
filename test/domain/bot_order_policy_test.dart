import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_order_policy.dart';
import 'package:zapiti_app/domain/played_card.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';

void main() {
  const bot = Player(id: 'bot', name: 'Bot', teamId: 1);
  const mate = Player(id: 'mate', name: 'Compañero', teamId: 1);
  const rival = Player(id: 'rival', name: 'Rival', teamId: 2);
  const rivalTwo = Player(id: 'rival2', name: 'Rival 2', teamId: 2);
  const hand = [
    SpanishCard(value: 12, suit: Suit.oros),
    SpanishCard(value: 2, suit: Suit.copas),
    SpanishCard(value: 4, suit: Suit.bastos),
  ];
  const players = [mate, rival, bot, rivalTwo];
  const hands = <String, List<SpanishCard>>{'bot': hand};

  test('sin orden delega en la estrategia habitual', () {
    expect(
      BotOrderPolicy.chooseOrderedCard(
        bot: bot,
        hand: hand,
        playedCards: const [],
        players: players,
        hands: hands,
        mataRequested: false,
        voyATiRequested: false,
      ),
      isNull,
    );
  });

  test('Mata obliga a elegir la carta de mayor fuerza', () {
    expect(
      BotOrderPolicy.chooseOrderedCard(
        bot: bot,
        hand: hand,
        playedCards: const [],
        players: players,
        hands: hands,
        mataRequested: true,
        voyATiRequested: false,
      ),
      const SpanishCard(value: 4, suit: Suit.bastos),
    );
  });

  test('Mata prevalece sobre Voy a ti si ambas están pendientes', () {
    expect(
      BotOrderPolicy.chooseOrderedCard(
        bot: bot,
        hand: hand,
        playedCards: const [
          PlayedCard(
            player: rival,
            card: SpanishCard(value: 5, suit: Suit.oros),
          ),
        ],
        players: players,
        hands: hands,
        mataRequested: true,
        voyATiRequested: true,
      ),
      const SpanishCard(value: 4, suit: Suit.bastos),
    );
  });

  test('Voy a ti utiliza su estrategia específica', () {
    expect(
      BotOrderPolicy.chooseOrderedCard(
        bot: bot,
        hand: hand,
        playedCards: const [],
        players: players,
        hands: hands,
        mataRequested: false,
        voyATiRequested: true,
      ),
      const SpanishCard(value: 4, suit: Suit.bastos),
    );
  });

  test('rechaza órdenes si el bot no tiene cartas', () {
    expect(
      () => BotOrderPolicy.chooseOrderedCard(
        bot: bot,
        hand: const [],
        playedCards: const [],
        players: players,
        hands: hands,
        mataRequested: true,
        voyATiRequested: false,
      ),
      throwsArgumentError,
    );
  });
}
