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
      throw StateError('No hay conexión con la partida.');
    }
    _channel!.sink.add(jsonEncode(message.toJson()));
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
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.playCard,
      roomId: roomId,
      playerId: playerId,
      payload: {'card': cardToJson(card)},
    ));
  }

  void passHand({
    required String roomId,
    required String playerId,
    required String toPlayerId,
  }) {
    send(MultiplayerMessage(
      type: MultiplayerMessageType.passHand,
      roomId: roomId,
      playerId: playerId,
      payload: {'toPlayerId': toPlayerId},
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
