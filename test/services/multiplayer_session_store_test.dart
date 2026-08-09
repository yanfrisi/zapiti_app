import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/player.dart';
import 'package:zapiti_app/services/multiplayer_session_store.dart';

void main() {
  tearDown(() {
    MultiplayerSessionStore.instance.clearAll();
  });

  test('guarda credenciales efimeras para reconectar y las limpia', () {
    final session = MultiplayerSessionStore.instance;

    session.rememberReconnectCredentials(
      roomId: 'ABC123',
      playerId: 'player_1',
      username: 'zapitero',
      playerName: 'Juan',
      teamName: 'Pareja',
      password: '1234',
      characterId: 'p1',
    );

    expect(session.canReconnectMatch, isTrue);
    expect(session.reconnectRoomId, 'ABC123');
    expect(session.localGamePlayerId, 'player_1');
    expect(session.reconnectPassword, '1234');

    session.clearAll();

    expect(session.canReconnectMatch, isFalse);
    expect(session.reconnectRoomId, isNull);
    expect(session.localGamePlayerId, isNull);
    expect(session.reconnectPassword, isNull);
  });

  test('clearAll es idempotente y elimina estado temporal de partida', () {
    final session = MultiplayerSessionStore.instance;
    session.rememberReconnectCredentials(
      roomId: 'ROOM_A',
      playerId: 'player_a',
      username: 'user',
      playerName: 'Player',
      teamName: 'Team',
      sessionToken: 'token',
    );
    session.players = const [
      Player(id: 'player_a', name: 'A', teamId: 1),
      Player(id: 'player_b', name: 'B', teamId: 2),
    ];
    session.controlledPlayerIds = const ['player_a'];
    session.characterIdsByPlayer = const {'player_a': 'p1'};
    session.seed = 42;
    session.botDifficulty = 5;
    session.allowPassHand = true;
    session.matchStarted = true;

    session.clearAll();
    session.clearAll();

    expect(session.activeRoomId, isNull);
    expect(session.localGamePlayerId, isNull);
    expect(session.players, isEmpty);
    expect(session.controlledPlayerIds, isEmpty);
    expect(session.characterIdsByPlayer, isEmpty);
    expect(session.fixedHands, isNull);
    expect(session.seed, isNull);
    expect(session.botDifficulty, isNull);
    expect(session.allowPassHand, isFalse);
    expect(session.matchStarted, isFalse);
    expect(session.socket, isNull);
  });
}
