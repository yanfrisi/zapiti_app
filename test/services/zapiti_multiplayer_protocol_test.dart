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
            username: 'host',
            pairId: 'p1+p2',
            teamName: 'Los Bravos',
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
      expect(parsed.seats.single.username, 'host');
      expect(parsed.seats.single.pairId, 'p1+p2');
      expect(parsed.seats.single.teamName, 'Los Bravos');
      expect(parsed.seats.single.ready, isTrue);
      expect(parsed.seats.single.seatIndex, 0);
      expect(parsed.seats.single.teamId, 1);
      expect(parsed.seats.single.connected, isTrue);
      expect(parsed.phase, 'lobby');
      expect(parsed.createdAt, 1710000000000);
    });

    test('serializa ranking multijugador', () {
      const message = MultiplayerMessage(
        type: MultiplayerMessageType.ranking,
        payload: {
          'pairs': [
            {'teamName': 'Juan / Ana', 'played': 2, 'wins': 1},
          ],
          'matches': [
            {
              'winnerTeamId': 1,
              'score': {'1': 30, '2': 18},
            },
          ],
        },
      );

      final parsed = MultiplayerMessage.fromJson(message.toJson());

      expect(parsed.type, MultiplayerMessageType.ranking);
      expect(parsed.payload['pairs'], isA<List<dynamic>>());
      expect(parsed.payload['matches'], isA<List<dynamic>>());
    });

    test('serializa equipos del jugador', () {
      const message = MultiplayerMessage(
        type: MultiplayerMessageType.teams,
        playerId: 'player_1',
        payload: {
          'teams': [
            {
              'pairId': 'player_1+player_2',
              'teamName': 'Los Bravos',
              'teammateNames': ['Ana'],
            },
          ],
        },
      );

      final parsed = MultiplayerMessage.fromJson(message.toJson());

      expect(parsed.type, MultiplayerMessageType.teams);
      expect(parsed.payload['teams'], isA<List<dynamic>>());
    });

    test('serializa perfil multijugador', () {
      const message = MultiplayerMessage(
        type: MultiplayerMessageType.profile,
        playerId: 'player_1',
        payload: {
          'playerId': 'player_1',
          'username': 'juan',
          'name': 'Juan',
          'sessionToken': 'session_123',
          'teamName': 'Los Bravos',
        },
      );

      final parsed = MultiplayerMessage.fromJson(message.toJson());

      expect(parsed.type, MultiplayerMessageType.profile);
      expect(parsed.payload['username'], 'juan');
      expect(parsed.payload['sessionToken'], 'session_123');
      expect(parsed.payload['teamName'], 'Los Bravos');
    });

    test('serializa liberacion de personaje', () {
      const message = MultiplayerMessage(
        type: MultiplayerMessageType.selectCharacter,
        roomId: 'ZP777',
        playerId: 'player_1',
        payload: {'characterId': null},
      );

      final parsed = MultiplayerMessage.fromJson(message.toJson());

      expect(parsed.type, MultiplayerMessageType.selectCharacter);
      expect(parsed.payload.containsKey('characterId'), isTrue);
      expect(parsed.payload['characterId'], isNull);
    });

    test('serializa pasar mano', () {
      const message = MultiplayerMessage(
        type: MultiplayerMessageType.passHand,
        roomId: 'ZP777',
        playerId: 'p1',
        payload: {'toPlayerId': 'p3'},
      );

      final json = message.toJson();
      final parsed = MultiplayerMessage.fromJson(json);

      expect(json['type'], 'pass_hand');
      expect(parsed.type, MultiplayerMessageType.passHand);
      expect(parsed.payload['toPlayerId'], 'p3');
    });
  });
}
