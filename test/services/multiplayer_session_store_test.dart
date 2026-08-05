import 'package:flutter_test/flutter_test.dart';
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
}
