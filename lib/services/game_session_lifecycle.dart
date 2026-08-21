import 'zapiti_game_socket.dart';
import 'zapiti_logger.dart';

enum GameSessionPhase {
  created,
  active,
  ending,
  disposed,
}

class GameSessionLifecycle {
  int _generation = 0;
  GameSessionPhase _phase = GameSessionPhase.disposed;

  int get generation => _generation;
  GameSessionPhase get phase => _phase;
  bool get isActive => _phase == GameSessionPhase.active;

  int create({required String mode}) {
    _generation += 1;
    _phase = GameSessionPhase.created;
    ZapitiLogger.info('session_lifecycle', 'session_created', fields: {
      'sessionId': _generation,
      'mode': mode,
    });
    return _generation;
  }

  void activate({required int sessionId, required String mode}) {
    if (sessionId != _generation || _phase == GameSessionPhase.disposed) {
      return;
    }
    _phase = GameSessionPhase.active;
    ZapitiLogger.info('session_lifecycle', 'session_activated', fields: {
      'sessionId': sessionId,
      'mode': mode,
    });
  }

  bool isCurrent(int sessionId) {
    return sessionId == _generation && _phase == GameSessionPhase.active;
  }

  int end({
    required String reason,
    GameSocket? socket,
  }) {
    final endedGeneration = _generation;
    if (_phase == GameSessionPhase.disposed) {
      ZapitiLogger.info('session_lifecycle', 'session_end_idempotent', fields: {
        'sessionId': endedGeneration,
        'reason': reason,
      });
      return endedGeneration;
    }
    _phase = GameSessionPhase.ending;
    ZapitiLogger.info('session_lifecycle', 'session_end_requested', fields: {
      'sessionId': endedGeneration,
      'reason': reason,
      'hasSocket': socket != null,
      'socketConnected': socket?.isConnected,
    });
    socket?.onMessage = null;
    socket?.onError = null;
    socket?.onDone = null;
    socket?.close();
    _phase = GameSessionPhase.disposed;
    _generation += 1;
    ZapitiLogger.info('session_lifecycle', 'session_disposed', fields: {
      'sessionId': endedGeneration,
      'nextSessionId': _generation,
      'reason': reason,
    });
    return endedGeneration;
  }
}
