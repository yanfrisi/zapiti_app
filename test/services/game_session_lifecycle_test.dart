import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/services/game_session_lifecycle.dart';

void main() {
  test('lifecycle invalida una sesion antigua al terminar', () {
    final lifecycle = GameSessionLifecycle();
    final first = lifecycle.create(mode: 'multiplayer');
    lifecycle.activate(sessionId: first, mode: 'multiplayer');

    expect(lifecycle.isCurrent(first), isTrue);

    lifecycle.end(reason: 'leave_room');

    expect(lifecycle.isCurrent(first), isFalse);
    expect(lifecycle.phase, GameSessionPhase.disposed);

    final second = lifecycle.create(mode: 'offline');
    lifecycle.activate(sessionId: second, mode: 'offline');

    expect(second, isNot(first));
    expect(lifecycle.isCurrent(second), isTrue);
    expect(lifecycle.isCurrent(first), isFalse);
  });

  test('cleanup es idempotente', () {
    final lifecycle = GameSessionLifecycle();
    final sessionId = lifecycle.create(mode: 'offline');
    lifecycle.activate(sessionId: sessionId, mode: 'offline');

    lifecycle.end(reason: 'first');
    lifecycle.end(reason: 'second');

    expect(lifecycle.phase, GameSessionPhase.disposed);
    expect(lifecycle.isCurrent(sessionId), isFalse);
  });
}
