import '../domain/spanish_card.dart';
import '../domain/player.dart';
import 'zapiti_game_socket.dart';
import 'zapiti_multiplayer_protocol.dart';

class MultiplayerSessionStore {
  MultiplayerSessionStore._();

  static final MultiplayerSessionStore instance = MultiplayerSessionStore._();

  GameSocket? socket;
  MultiplayerRoomSnapshot? roomSnapshot;
  String? localGamePlayerId;
  List<Player> players = const [];
  List<String> controlledPlayerIds = const [];
  Map<String, String> characterIdsByPlayer = const {};
  Map<String, List<SpanishCard>>? fixedHands;
  int? seed;
  bool matchStarted = false;

  void clearMatchData() {
    localGamePlayerId = null;
    players = const [];
    controlledPlayerIds = const [];
    characterIdsByPlayer = const {};
    fixedHands = null;
    seed = null;
    matchStarted = false;
  }

  void clearAll() {
    socket?.close();
    socket = null;
    roomSnapshot = null;
    clearMatchData();
  }
}
