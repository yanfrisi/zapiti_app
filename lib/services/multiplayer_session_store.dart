import '../domain/spanish_card.dart';
import '../domain/player.dart';
import 'zapiti_game_socket.dart';
import 'zapiti_multiplayer_protocol.dart';

class MultiplayerSessionStore {
  MultiplayerSessionStore._();

  static final MultiplayerSessionStore instance = MultiplayerSessionStore._();

  GameSocket? socket;
  MultiplayerRoomSnapshot? roomSnapshot;
  String? reconnectRoomId;
  String? reconnectUsername;
  String? reconnectPlayerName;
  String? reconnectTeamName;
  String? reconnectPassword;
  String? reconnectSessionToken;
  String? reconnectPairId;
  String? reconnectCharacterId;
  String? localGamePlayerId;
  List<Player> players = const [];
  List<String> controlledPlayerIds = const [];
  Map<String, String> characterIdsByPlayer = const {};
  Map<String, List<SpanishCard>>? fixedHands;
  int? seed;
  int? botDifficulty;
  bool allowPassHand = false;
  bool matchStarted = false;

  bool get canReconnectMatch {
    return (reconnectRoomId ?? roomSnapshot?.roomId)?.isNotEmpty == true &&
        localGamePlayerId?.isNotEmpty == true &&
        reconnectUsername?.isNotEmpty == true &&
        reconnectPlayerName?.isNotEmpty == true &&
        reconnectTeamName?.isNotEmpty == true &&
        ((reconnectSessionToken?.isNotEmpty == true) ||
            (reconnectPassword?.isNotEmpty == true));
  }

  void rememberReconnectCredentials({
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
    reconnectRoomId = roomId.trim().isEmpty ? null : roomId.trim();
    localGamePlayerId = playerId.trim().isEmpty ? null : playerId.trim();
    reconnectUsername = username.trim().isEmpty ? null : username.trim();
    reconnectPlayerName = playerName.trim().isEmpty ? null : playerName.trim();
    reconnectTeamName = teamName.trim().isEmpty ? null : teamName.trim();
    reconnectPassword = password?.trim().isEmpty == true ? null : password;
    reconnectSessionToken =
        sessionToken?.trim().isEmpty == true ? null : sessionToken;
    reconnectPairId = pairId?.trim().isEmpty == true ? null : pairId;
    reconnectCharacterId =
        characterId?.trim().isEmpty == true ? null : characterId;
  }

  void clearReconnectCredentials() {
    reconnectRoomId = null;
    reconnectUsername = null;
    reconnectPlayerName = null;
    reconnectTeamName = null;
    reconnectPassword = null;
    reconnectSessionToken = null;
    reconnectPairId = null;
    reconnectCharacterId = null;
  }

  void clearMatchData() {
    localGamePlayerId = null;
    players = const [];
    controlledPlayerIds = const [];
    characterIdsByPlayer = const {};
    fixedHands = null;
    seed = null;
    botDifficulty = null;
    allowPassHand = false;
    matchStarted = false;
  }

  void clearAll() {
    socket?.close();
    socket = null;
    roomSnapshot = null;
    clearReconnectCredentials();
    clearMatchData();
  }
}
