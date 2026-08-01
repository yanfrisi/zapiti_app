import '../domain/spanish_card.dart';
import '../domain/suit.dart';

typedef JsonMap = Map<String, dynamic>;

enum MultiplayerMessageType {
  createRoom('create_room'),
  joinRoom('join_room'),
  leaveRoom('leave_room'),
  roomSnapshot('room_snapshot'),
  playerReady('player_ready'),
  selectCharacter('select_character'),
  updateProfile('update_profile'),
  recoverProfile('recover_profile'),
  profile('profile'),
  listTeams('list_teams'),
  createTeam('create_team'),
  updateTeam('update_team'),
  archiveTeam('archive_team'),
  selectTeam('select_team'),
  teams('teams'),
  getRanking('get_ranking'),
  ranking('ranking'),
  startGame('start_game'),
  newHand('new_hand'),
  restartGame('restart_game'),
  chooseAlVerDecision('choose_al_ver_decision'),
  playCard('play_card'),
  passHand('pass_hand'),
  callTruco('call_truco'),
  acceptTruco('accept_truco'),
  passTruco('pass_truco'),
  raiseTruco('raise_truco'),
  continueRound('continue_round'),
  signal('signal'),
  requestSignal('request_signal'),
  error('error');

  final String wireName;

  const MultiplayerMessageType(this.wireName);

  static MultiplayerMessageType fromWireName(String value) {
    return MultiplayerMessageType.values.firstWhere(
      (type) => type.wireName == value,
      orElse: () =>
          throw FormatException('Tipo de mensaje desconocido: $value'),
    );
  }
}

class MultiplayerMessage {
  final MultiplayerMessageType type;
  final String? roomId;
  final String? playerId;
  final JsonMap payload;

  const MultiplayerMessage({
    required this.type,
    this.roomId,
    this.playerId,
    this.payload = const {},
  });

  factory MultiplayerMessage.fromJson(JsonMap json) {
    return MultiplayerMessage(
      type: MultiplayerMessageType.fromWireName(json['type'] as String),
      roomId: json['roomId'] as String?,
      playerId: json['playerId'] as String?,
      payload: (json['payload'] as JsonMap?) ?? const {},
    );
  }

  JsonMap toJson() => {
        'type': type.wireName,
        if (roomId != null) 'roomId': roomId,
        if (playerId != null) 'playerId': playerId,
        if (payload.isNotEmpty) 'payload': payload,
      };
}

class MultiplayerSeat {
  final String playerId;
  final String name;
  final String? username;
  final String? pairId;
  final String? teamName;
  final int seatIndex;
  final int? teamId;
  final bool ready;
  final bool connected;
  final String? characterId;

  const MultiplayerSeat({
    required this.playerId,
    required this.name,
    this.username,
    this.pairId,
    this.teamName,
    required this.seatIndex,
    this.teamId,
    required this.ready,
    required this.connected,
    this.characterId,
  });

  factory MultiplayerSeat.fromJson(JsonMap json) {
    return MultiplayerSeat(
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      username: json['username'] as String?,
      pairId: json['pairId'] as String?,
      teamName: json['teamName'] as String?,
      seatIndex: json['seatIndex'] as int,
      teamId: json['teamId'] as int?,
      ready: json['ready'] as bool? ?? false,
      connected: json['connected'] as bool? ?? false,
      characterId: json['characterId'] as String?,
    );
  }

  JsonMap toJson() => {
        'playerId': playerId,
        'name': name,
        if (username != null) 'username': username,
        if (pairId != null) 'pairId': pairId,
        if (teamName != null) 'teamName': teamName,
        'seatIndex': seatIndex,
        if (teamId != null) 'teamId': teamId,
        'ready': ready,
        'connected': connected,
        if (characterId != null) 'characterId': characterId,
      };
}

class MultiplayerRoomSnapshot {
  final String roomId;
  final List<MultiplayerSeat> seats;
  final String phase;
  final int createdAt;
  final JsonMap? match;

  const MultiplayerRoomSnapshot({
    required this.roomId,
    required this.seats,
    required this.phase,
    required this.createdAt,
    this.match,
  });

  factory MultiplayerRoomSnapshot.fromJson(JsonMap json) {
    final rawSeats = (json['seats'] as List<dynamic>? ?? const []);
    final rawMatch = json['match'];
    return MultiplayerRoomSnapshot(
      roomId: json['roomId'] as String,
      seats: [
        for (final seat in rawSeats) MultiplayerSeat.fromJson(seat as JsonMap),
      ],
      phase: json['phase'] as String? ?? 'lobby',
      createdAt: json['createdAt'] as int? ?? 0,
      match: rawMatch is JsonMap ? Map<String, dynamic>.from(rawMatch) : null,
    );
  }

  JsonMap toJson() => {
        'roomId': roomId,
        'seats': [for (final seat in seats) seat.toJson()],
        'phase': phase,
        'createdAt': createdAt,
        if (match != null) 'match': match,
      };
}

JsonMap cardToJson(SpanishCard card) => {
      'value': card.value,
      'suit': card.suit.label,
    };

SpanishCard cardFromJson(JsonMap json) {
  final value = json['value'] as int;
  final suitLabel = json['suit'] as String;
  final suit = Suit.values.firstWhere((item) => item.label == suitLabel);
  return SpanishCard(value: value, suit: suit);
}
