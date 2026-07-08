import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/spanish_card.dart';
import 'zapiti_multiplayer_protocol.dart';

class GameSocket {
  final String url;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  void Function(MultiplayerMessage message)? onMessage;
  void Function(Object error)? onError;
  void Function()? onDone;

  GameSocket(this.url);

  bool get isConnected => _channel != null;

  Future<void> connect({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final channel = WebSocketChannel.connect(Uri.parse(url));
    try {
      await channel.ready.timeout(timeout);
      _channel = channel;
      _subscription = channel.stream.listen(
        (event) {
          final payload =
              jsonDecode(event is String ? event : event.toString());
          if (payload is Map<String, dynamic>) {
            onMessage?.call(MultiplayerMessage.fromJson(payload));
          }
        },
        onError: (error) {
          onError?.call(error);
          _channel = null;
        },
        onDone: () {
          onDone?.call();
          _channel = null;
        },
        cancelOnError: true,
      );
    } catch (_) {
      await channel.sink.close();
      rethrow;
    }
  }

  void send(MultiplayerMessage message) {
    if (_channel == null) {
      throw StateError('WebSocket no esta conectado.');
    }
    _channel!.sink.add(jsonEncode(message.toJson()));
  }

  void createRoom({
    required String playerId,
    required String playerName,
    String? characterId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.createRoom,
      playerId: playerId,
      payload: {
        'name': playerName,
        if (characterId != null) 'characterId': characterId,
      },
    ));
  }

  void joinRoom({
    required String roomId,
    required String playerId,
    required String playerName,
    String? characterId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.joinRoom,
      roomId: roomId,
      playerId: playerId,
      payload: {
        'name': playerName,
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

  void playCard({
    required String roomId,
    required String playerId,
    required SpanishCard card,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.playCard,
      roomId: roomId,
      playerId: playerId,
      payload: {'card': cardToJson(card)},
    ));
  }

  void callTruco({
    required String roomId,
    required String playerId,
    required int value,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.callTruco,
      roomId: roomId,
      playerId: playerId,
      payload: {'value': value},
    ));
  }

  void acceptTruco({required String roomId, required String playerId}) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.acceptTruco,
      roomId: roomId,
      playerId: playerId,
    ));
  }

  void passTruco({required String roomId, required String playerId}) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.passTruco,
      roomId: roomId,
      playerId: playerId,
    ));
  }

  void raiseTruco({
    required String roomId,
    required String playerId,
    required int value,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.raiseTruco,
      roomId: roomId,
      playerId: playerId,
      payload: {'value': value},
    ));
  }

  void continueRound({required String roomId, required String playerId}) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.continueRound,
      roomId: roomId,
      playerId: playerId,
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
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }
}
