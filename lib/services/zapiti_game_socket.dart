import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/spanish_card.dart';
import 'zapiti_logger.dart';
import 'zapiti_multiplayer_protocol.dart';

class GameSocket {
  final String url;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  int _messageCounter = 0;

  void Function(MultiplayerMessage message)? onMessage;
  void Function(Object error)? onError;
  void Function()? onDone;

  GameSocket(this.url);

  bool get isConnected => _channel != null;

  Future<void> connect({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    ZapitiLogger.info('socket', 'connect_attempt', fields: {
      'url': url,
      'timeoutMs': timeout.inMilliseconds,
    });
    final channel = WebSocketChannel.connect(Uri.parse(url));
    try {
      await channel.ready.timeout(timeout);
      _channel = channel;
      ZapitiLogger.info('socket', 'connect_success', fields: {'url': url});
      _subscription = channel.stream.listen(
        (event) {
          try {
            final rawEvent = event is String ? event : event.toString();
            ZapitiLogger.debug('socket', 'message_raw_in', fields: {
              'url': url,
              'size': rawEvent.length,
              'preview': rawEvent.length > 400
                  ? '${rawEvent.substring(0, 400)}...'
                  : rawEvent,
            });
            final payload = jsonDecode(rawEvent);
            if (payload is Map<String, dynamic>) {
              final message = MultiplayerMessage.fromJson(payload);
              ZapitiLogger.info('socket', 'message_parsed_in', fields: {
                'url': url,
                'type': message.type.wireName,
                'roomId': message.roomId,
                'playerId': message.playerId,
                'messageId': message.messageId,
                'correlationId': message.correlationId,
                'payload': message.payload,
                'payloadKeys': message.payload.keys.toList(),
              });
              onMessage?.call(message);
            }
          } catch (error, stackTrace) {
            ZapitiLogger.error(
              'socket',
              'message_decode_failed',
              error: error,
              stackTrace: stackTrace,
              fields: {'url': url},
            );
            onError?.call(error);
          }
        },
        onError: (error) {
          ZapitiLogger.error(
            'socket',
            'stream_error',
            error: error,
            fields: {'url': url},
          );
          onError?.call(error);
          _channel = null;
        },
        onDone: () {
          ZapitiLogger.warn('socket', 'stream_done', fields: {'url': url});
          onDone?.call();
          _channel = null;
        },
        cancelOnError: true,
      );
    } catch (error, stackTrace) {
      ZapitiLogger.error(
        'socket',
        'connect_failed',
        error: error,
        stackTrace: stackTrace,
        fields: {'url': url},
      );
      await channel.sink.close();
      rethrow;
    }
  }

  void send(MultiplayerMessage message) {
    final normalizedMessage = _ensureMessageIds(message);
    if (_channel == null) {
      ZapitiLogger.warn('socket', 'send_without_connection', fields: {
        'type': normalizedMessage.type.wireName,
        'roomId': normalizedMessage.roomId,
        'playerId': normalizedMessage.playerId,
        'messageId': normalizedMessage.messageId,
        'correlationId': normalizedMessage.correlationId,
      });
      throw StateError('No hay conexion con la partida.');
    }
    try {
      final encoded = jsonEncode(normalizedMessage.toJson());
      ZapitiLogger.info('socket', 'message_out', fields: {
        'url': url,
        'type': normalizedMessage.type.wireName,
        'roomId': normalizedMessage.roomId,
        'playerId': normalizedMessage.playerId,
        'messageId': normalizedMessage.messageId,
        'correlationId': normalizedMessage.correlationId,
        'payload': normalizedMessage.payload,
        'payloadKeys': normalizedMessage.payload.keys.toList(),
        'size': encoded.length,
      });
      _channel!.sink.add(encoded);
    } catch (error, stackTrace) {
      ZapitiLogger.error(
        'socket',
        'send_failed',
        error: error,
        stackTrace: stackTrace,
        fields: {
          'url': url,
          'type': normalizedMessage.type.wireName,
          'roomId': normalizedMessage.roomId,
          'playerId': normalizedMessage.playerId,
          'messageId': normalizedMessage.messageId,
          'correlationId': normalizedMessage.correlationId,
        },
      );
      _channel = null;
      onError?.call(error);
    }
  }

  MultiplayerMessage _ensureMessageIds(MultiplayerMessage message) {
    final messageId =
        message.messageId ??
        'cli_${DateTime.now().microsecondsSinceEpoch}_${_messageCounter++}';
    final correlationId = message.correlationId ?? messageId;
    return message.copyWith(
      messageId: messageId,
      correlationId: correlationId,
    );
  }

  void createRoom({
    required String playerId,
    required String username,
    required String playerName,
    required String teamName,
    String? password,
    String? sessionToken,
    String? pairId,
    String? characterId,
    bool allowPassHand = false,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.createRoom,
      playerId: playerId,
      payload: {
        'username': username,
        'name': playerName,
        'teamName': teamName,
        if (sessionToken != null) 'sessionToken': sessionToken,
        if (sessionToken == null && password != null) 'password': password,
        if (pairId != null) 'pairId': pairId,
        if (characterId != null) 'characterId': characterId,
        'allowPassHand': allowPassHand,
      },
    ));
  }

  void joinRoom({
    required String roomId,
    required String playerId,
    required String username,
    required String playerName,
    required String teamName,
    String? password,
    String? sessionToken,
    String? pairId,
    String? characterId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.joinRoom,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'username': username,
        'name': playerName,
        'teamName': teamName,
        if (sessionToken != null) 'sessionToken': sessionToken,
        if (sessionToken == null && password != null) 'password': password,
        if (pairId != null) 'pairId': pairId,
        if (characterId != null) 'characterId': characterId,
      },
    ));
  }

  void leaveRoom({
    required String roomId,
    required String playerId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.leaveRoom,
      roomId: roomId,
      playerId: playerId,
    ));
  }

  void setReady({
    required String roomId,
    required String playerId,
    required bool ready,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.playerReady,
      roomId: roomId,
      playerId: playerId,
      payload: {'ready': ready},
    ));
  }

  void selectCharacter({
    required String roomId,
    required String playerId,
    required String characterId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.selectCharacter,
      roomId: roomId,
      playerId: playerId,
      payload: {'characterId': characterId},
    ));
  }

  void releaseCharacter({
    required String roomId,
    required String playerId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.selectCharacter,
      roomId: roomId,
      playerId: playerId,
      payload: {'characterId': null},
    ));
  }

  void requestRanking() {
    send(const MultiplayerMessage(
      type: MultiplayerMessageType.getRanking,
    ));
  }

  void requestTeams({
    required String playerId,
    required String sessionToken,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.listTeams,
      playerId: playerId,
      payload: {'sessionToken': sessionToken},
    ));
  }

  void createTeam({
    required String playerId,
    required String sessionToken,
    required String teammateUsername,
    required String teamName,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.createTeam,
      playerId: playerId,
      payload: {
        'sessionToken': sessionToken,
        'teammateUsername': teammateUsername,
        'teamName': teamName,
      },
    ));
  }

  void selectTeam({
    required String roomId,
    required String playerId,
    required String sessionToken,
    required String pairId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.selectTeam,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'sessionToken': sessionToken,
        'pairId': pairId,
      },
    ));
  }

  void updateTeam({
    required String playerId,
    required String sessionToken,
    required String pairId,
    required String teamName,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.updateTeam,
      playerId: playerId,
      payload: {
        'sessionToken': sessionToken,
        'pairId': pairId,
        'teamName': teamName,
      },
    ));
  }

  void archiveTeam({
    required String playerId,
    required String sessionToken,
    required String pairId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.archiveTeam,
      playerId: playerId,
      payload: {
        'sessionToken': sessionToken,
        'pairId': pairId,
      },
    ));
  }

  void updateProfile({
    required String playerId,
    required String username,
    required String playerName,
    required String teamName,
    String? password,
    String? sessionToken,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.updateProfile,
      playerId: playerId,
      payload: {
        'username': username,
        'name': playerName,
        'teamName': teamName,
        if (password != null) 'password': password,
        if (password == null && sessionToken != null)
          'sessionToken': sessionToken,
      },
    ));
  }

  void recoverProfile({
    required String username,
    required String password,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.recoverProfile,
      payload: {
        'username': username,
        'password': password,
      },
    ));
  }

  void newHand({required String roomId, required String playerId}) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.newHand,
      roomId: roomId,
      playerId: playerId,
    ));
  }

  void restartGame({required String roomId, required String playerId}) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.restartGame,
      roomId: roomId,
      playerId: playerId,
    ));
  }

  void chooseAlVerDecision({
    required String roomId,
    required String playerId,
    required bool play,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.chooseAlVerDecision,
      roomId: roomId,
      playerId: playerId,
      payload: {'play': play},
    ));
  }

  void playCard({
    required String roomId,
    required String playerId,
    required SpanishCard card,
    int? expectedStateVersion,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.playCard,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'card': cardToJson(card),
        if (expectedStateVersion != null)
          'expectedStateVersion': expectedStateVersion,
      },
    ));
  }

  void passHand({
    required String roomId,
    required String playerId,
    required String toPlayerId,
    int? expectedStateVersion,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.passHand,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'toPlayerId': toPlayerId,
        if (expectedStateVersion != null)
          'expectedStateVersion': expectedStateVersion,
      },
    ));
  }

  void callTruco({
    required String roomId,
    required String playerId,
    required int value,
    int? expectedStateVersion,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.callTruco,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'value': value,
        if (expectedStateVersion != null)
          'expectedStateVersion': expectedStateVersion,
      },
    ));
  }

  void acceptTruco({
    required String roomId,
    required String playerId,
    int? expectedStateVersion,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.acceptTruco,
      roomId: roomId,
      playerId: playerId,
      payload: {
        if (expectedStateVersion != null)
          'expectedStateVersion': expectedStateVersion,
      },
    ));
  }

  void passTruco({
    required String roomId,
    required String playerId,
    int? expectedStateVersion,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.passTruco,
      roomId: roomId,
      playerId: playerId,
      payload: {
        if (expectedStateVersion != null)
          'expectedStateVersion': expectedStateVersion,
      },
    ));
  }

  void raiseTruco({
    required String roomId,
    required String playerId,
    required int value,
    int? expectedStateVersion,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.raiseTruco,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'value': value,
        if (expectedStateVersion != null)
          'expectedStateVersion': expectedStateVersion,
      },
    ));
  }

  void continueRound({
    required String roomId,
    required String playerId,
    int? expectedStateVersion,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.continueRound,
      roomId: roomId,
      playerId: playerId,
      payload: {
        if (expectedStateVersion != null)
          'expectedStateVersion': expectedStateVersion,
      },
    ));
  }

  void signal({
    required String roomId,
    required String playerId,
    required String label,
    bool active = true,
    String? kind,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.signal,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'label': label,
        'active': active,
        if (kind != null) 'kind': kind,
      },
    ));
  }

  void requestSignal({
    required String roomId,
    required String playerId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.requestSignal,
      roomId: roomId,
      playerId: playerId,
    ));
  }

  void close() {
    ZapitiLogger.info('socket', 'close', fields: {'url': url});
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}
