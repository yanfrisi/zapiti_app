import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/spanish_card.dart';
import 'package:zapiti_app/domain/suit.dart';
import 'package:zapiti_app/services/zapiti_multiplayer_protocol.dart';

void main() {
  group('Zapiti multiplayer protocol', () {
    test('serializa y parsea mensajes base', () {
      const message = MultiplayerMessage(
        type: MultiplayerMessageType.joinRoom,
        roomId: 'ZP123',
        playerId: 'p1',
        payload: {'name': 'Juan'},
      );

      final json = message.toJson();
      final parsed = MultiplayerMessage.fromJson(json);

      expect(json['type'], 'join_room');
      expect(parsed.type, MultiplayerMessageType.joinRoom);
      expect(parsed.roomId, 'ZP123');
      expect(parsed.playerId, 'p1');
      expect(parsed.payload['name'], 'Juan');
    });

    test('serializa cartas para acciones de partida', () {
      const card = SpanishCard(value: 7, suit: Suit.oros);

      final json = cardToJson(card);
      final parsed = cardFromJson(json);

      expect(json, {'value': 7, 'suit': 'Oros'});
      expect(parsed, card);
    });

    test('serializa snapshot de sala', () {
      const snapshot = MultiplayerRoomSnapshot(
        roomId: 'ZP777',
        phase: 'lobby',
        createdAt: 1710000000000,
        seats: [
          MultiplayerSeat(
            playerId: 'p1',
            name: 'Host',
            seatIndex: 0,
            teamId: 1,
            ready: true,
            connected: true,
          ),
        ],
      );

      final parsed = MultiplayerRoomSnapshot.fromJson(snapshot.toJson());

      expect(parsed.roomId, 'ZP777');
      expect(parsed.seats.single.name, 'Host');
      expect(parsed.seats.single.ready, isTrue);
      expect(parsed.seats.single.seatIndex, 0);
      expect(parsed.seats.single.teamId, 1);
      expect(parsed.seats.single.connected, isTrue);
      expect(parsed.phase, 'lobby');
      expect(parsed.createdAt, 1710000000000);
    });
  });
}
