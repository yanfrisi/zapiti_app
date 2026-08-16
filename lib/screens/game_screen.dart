import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/bot_al_ver_strategy.dart';
import '../domain/bot_agent_difficulty.dart';
import '../domain/bot_bluff_strategy.dart';
import '../domain/bot_table_read.dart';
import '../domain/bot_truco_raise_strategy.dart';
import '../domain/bot_truco_response_strategy.dart';
import '../domain/bot_truco_strategy.dart';
import '../domain/bot_ven_a_mi_strategy.dart';
import '../domain/bot_voy_a_ti_strategy.dart';
import '../domain/bet_state.dart';
import '../domain/bot_decision_context.dart';
import '../domain/bot_memory_context.dart';
import '../domain/bot_policy.dart';
import '../domain/character_assets.dart';
import '../domain/debug_deals.dart';
import '../domain/difficulty_profile.dart';
import '../domain/difficulty_strategy.dart';
import '../domain/limited_history.dart';
import '../domain/played_card.dart';
import '../domain/player.dart';
import '../domain/round_result.dart';
import '../domain/signal_context.dart';
import '../domain/signal_rules.dart';
import '../domain/spanish_card.dart';
import '../domain/suit.dart';
import '../domain/team_rules.dart';
import '../domain/truco_rules.dart';
import '../domain/zapiti_game_controller.dart';
import '../domain/zapiti_players.dart';
import '../domain/zapiti_rules.dart';
import '../config/server_config.dart';
import '../l10n/zapiti_localizations.dart';
import '../services/app_version_check_service.dart';
import '../services/account_privacy_service.dart';
import '../services/game_preferences_store.dart';
import '../services/game_session_lifecycle.dart';
import '../services/multiplayer_session_store.dart';
import '../services/zapiti_game_socket.dart';
import '../services/zapiti_logger.dart';
import '../services/zapiti_multiplayer_protocol.dart';
import '../services/zapiti_music_player.dart';
import '../theme/zapiti_theme.dart';
import 'about_screen.dart';
import '../widgets/avatar_with_silhouette.dart';
import '../widgets/zapiti_action_button.dart';
import '../widgets/zapiti_card_widget.dart';
import '../widgets/zapiti_game_table.dart';
import '../widgets/zapiti_speech_bubble.dart';

part 'game_screen_menu.dart';
part 'game_screen_play_logic.dart';
part 'game_screen_play_ui.dart';
part 'game_screen_setup.dart';
part 'game_screen_signal_logic.dart';
part 'game_screen_state_flow.dart';
part 'game_screen_truco_logic.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @visibleForTesting
  static AppVersionCheckService versionCheckService =
      AppVersionCheckService.production();

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _MainMenuPanel { home, tutorial, options, multiplayer }

enum _BotSpeed {
  slow(1.35),
  normal(1),
  fast(0.55);

  final double delayFactor;

  const _BotSpeed(this.delayFactor);

  String label(BuildContext context) {
    return switch (this) {
      _BotSpeed.slow => context.tr('slow'),
      _BotSpeed.normal => context.tr('normal'),
      _BotSpeed.fast => context.tr('fast'),
    };
  }
}

enum _ServerConnectionState {
  idle,
  connecting,
  wakingServer,
  connected,
  reconnecting,
  error,
  disconnected,
}

extension on _ServerConnectionState {
  String label(BuildContext context) {
    switch (this) {
      case _ServerConnectionState.idle:
        return context.tr('multiplayerStateIdle');
      case _ServerConnectionState.connecting:
        return context.tr('multiplayerStateConnecting');
      case _ServerConnectionState.wakingServer:
        return context.tr('multiplayerStateWakingServer');
      case _ServerConnectionState.connected:
        return context.tr('multiplayerStateConnected');
      case _ServerConnectionState.reconnecting:
        return context.tr('multiplayerStateReconnecting');
      case _ServerConnectionState.error:
        return context.tr('multiplayerStateError');
      case _ServerConnectionState.disconnected:
        return context.tr('multiplayerStateDisconnected');
    }
  }

  IconData get icon {
    switch (this) {
      case _ServerConnectionState.idle:
        return Icons.info_outline;
      case _ServerConnectionState.connecting:
        return Icons.sync_outlined;
      case _ServerConnectionState.wakingServer:
        return Icons.cloud_outlined;
      case _ServerConnectionState.connected:
        return Icons.wifi_tethering_outlined;
      case _ServerConnectionState.reconnecting:
        return Icons.restart_alt_outlined;
      case _ServerConnectionState.error:
        return Icons.error_outline;
      case _ServerConnectionState.disconnected:
        return Icons.wifi_off_outlined;
    }
  }
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const _targetScore = 30;
  static const _defaultPlayers = ZapitiPlayers.tableOrder;
  static const _selectedCharacterPrefsKey = 'selected_human_character_id';
  static const _selectedDifficultyPrefsKey = 'selected_difficulty';
  static const _audioEnabledPrefsKey = 'audio_enabled';
  static const _audioVolumePrefsKey = 'audio_volume';
  static const _botSpeedPrefsKey = 'bot_speed';
  static const _showGameplayHelpPrefsKey = 'show_gameplay_help';
  static const _confirmCardPlayPrefsKey = 'confirm_card_play';
  static const _languagePrefsKey = 'language';

  final Map<String, String> _playerMessages = {};
  final Map<String, Timer> _playerMessageTimers = {};
  final Map<int, String> _knownSignalsByTeam = {};
  final Map<int, String> _teamSignalsByTeam = {};
  final Map<int, String> _opponentSignalsSeenByTeam = {};
  final List<StrategicSignal> _activeStrategicSignals = [];
  final Set<String> _playersSignaledThisHand = {};
  final Set<String> _forceWinRequestedPlayerIds = {};
  final Set<String> _forceHighestRequestedPlayerIds = {};
  final Set<String> _forceLowestRequestedPlayerIds = {};
  final Set<int> _aiTeamsConsideredTrucoThisHand = {};
  String? _companionPrivateSignalStatus;
  String? _companionPrivateSignalRequestId;
  int _localSignalRequestSequence = 0;
  Timer? _companionPrivateSignalTimer;
  Random _random = Random();
  final GamePreferencesStore _preferencesStore = const GamePreferencesStore();
  final GameSessionLifecycle _sessionLifecycle = GameSessionLifecycle();
  final ZapitiMusicPlayer _musicPlayer = ZapitiMusicPlayer();
  final Map<String, String> _characterIdsByPlayer = {
    for (final player in _defaultPlayers) player.id: player.id,
  };
  late ZapitiGameController _game;
  bool _isMultiplayerMatch = false;
  List<Player> _multiplayerPlayers = const [];

  int _handVersion = 0;
  int? _multiplayerServerHandSequence;
  int? _multiplayerStateVersion;
  int? _turnDeadlineAt;
  int? _turnSecondsRemaining;
  Timer? _turnCountdownTimer;
  bool _isAutoPlaying = false;
  bool _isRecoveringMultiplayerConnection = false;
  bool _isAwaitingMultiplayerResync = false;
  bool _multiplayerConnectionFailed = false;
  bool _multiplayerMatchCanceled = false;
  int _multiplayerConnectionGeneration = 0;
  int _multiplayerSnapshotDelayGeneration = 0;
  bool _isWaitingHumanTrucoResponse = false;
  bool _isRequestingCompanionSignal = false;
  bool _showGameOptions = false;
  bool _showMainMenu = true;
  bool _showCharacterSelection = true;
  bool _showDifficultySelection = false;
  bool _audioEnabled = true;
  double _audioVolume = 0.65;
  bool _confirmCardPlay = false;
  bool _allowPassHand = false;
  ZapitiLanguage _language = ZapitiLanguage.es;
  bool _isGuidedTutorialMatch = false;
  bool _guidedTutorialCompleted = false;
  int _guidedTutorialScenarioIndex = 0;
  AppVersionCheckResult _versionCheck = AppVersionCheckResult.notChecked;
  int _versionCheckRequestId = 0;
  bool _isAlVerDecisionDialogOpen = false;
  String? _alVerDecisionPromptedKey;
  _MainMenuPanel _mainMenuPanel = _MainMenuPanel.home;
  _BotSpeed _botSpeed = _BotSpeed.normal;
  String _selectedHumanCharacterId = 'p1';
  int _selectedDifficulty = 3;
  int _companionVoyATiPromptedHandVersion = -1;
  static const _debugUsePresetHands = false;
  static const _debugPresetIndex = 0;
  Set<String> _controlledHumanPlayerIds = {ZapitiPlayers.human.id};

  List<Player> get _players =>
      _isMultiplayerMatch && _multiplayerPlayers.isNotEmpty
          ? _multiplayerPlayers
          : _defaultPlayers;

  String? get _multiplayerRoomId =>
      MultiplayerSessionStore.instance.activeRoomId;

  Map<int, int> get _score => _game.score;
  Map<int, int> get _roundWins => _game.roundWins;
  LimitedHistory get _handSummaries => _game.handSummaries;
  List<PlayedCard> get _playedCards => _game.playedCards;
  List<RoundResult> get _roundHistory => _game.roundHistory;
  Map<String, List<SpanishCard>> get _hands => _game.hands;
  Player get _currentPlayer => _game.currentPlayer;
  Player get _humanPlayer => _game.humanPlayer;
  List<SpanishCard> get _humanHand => _game.humanHand;
  int get _handValue => _game.handValue;
  set _handValue(int value) => _game.handValue = value;
  int? get _pendingTrucoValue => _game.pendingTrucoValue;
  set _pendingTrucoValue(int? value) => _game.pendingTrucoValue = value;
  int? get _trucoCallerTeamId => _game.trucoCallerTeamId;
  set _trucoCallerTeamId(int? value) => _game.trucoCallerTeamId = value;
  int? get _winningTeamId => _game.winningTeamId;
  set _winningTeamId(int? value) => _game.winningTeamId = value;
  bool get _handFinished => _game.handFinished;
  set _handFinished(bool value) => _game.handFinished = value;
  bool get _isTrucoAccepted => _game.isTrucoAccepted;
  set _isTrucoAccepted(bool value) => _game.isTrucoAccepted = value;
  BetState get _betState => _game.betState;
  bool get _isRoundAwaitingContinue => _game.isRoundAwaitingContinue;
  set _isRoundAwaitingContinue(bool value) =>
      _game.isRoundAwaitingContinue = value;
  String get _status => _game.status;
  set _status(String value) => _game.status = value;
  set _turnIndex(int value) => _game.turnIndex = value;
  set _leadIndex(int value) => _game.leadIndex = value;
  set _nextLeadIndex(int value) => _game.nextLeadIndex = value;
  bool get _isHumanTurn =>
      _currentPlayer.id == _humanPlayer.id &&
      !_handFinished &&
      !_isAutoPlaying &&
      !_isRoundAwaitingContinue &&
      !_isWaitingHumanTrucoResponse &&
      _game.alVerState != AlVerState.awaitingDecision;
  bool get _isGameFinished => _winningTeamId != null;
  @visibleForTesting
  ZapitiGameController get gameController => _game;
  @visibleForTesting
  bool get isMultiplayerMatchForTesting => _isMultiplayerMatch;
  @visibleForTesting
  bool get multiplayerMatchCanceledForTesting => _multiplayerMatchCanceled;
  @visibleForTesting
  void simulateStaleMultiplayerCancellationForTesting() {
    _updateState(() {
      _isMultiplayerMatch = true;
      _multiplayerPlayers = const [
        Player(id: 'remote_1', name: 'Remoto 1', teamId: 1),
        Player(id: 'remote_2', name: 'Remoto 2', teamId: 2),
      ];
      _multiplayerMatchCanceled = true;
      _showMainMenu = true;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
    });
  }

  @visibleForTesting
  void simulateActiveRemoteMultiplayerMatchForTesting() {
    const remotePlayers = [
      Player(id: 'player_remote_a', name: 'Remoto A', teamId: 1),
      Player(id: 'player_remote_b', name: 'Remoto B', teamId: 2),
      Player(id: 'player_remote_c', name: 'Remoto C', teamId: 1),
      Player(id: 'player_remote_d', name: 'Remoto D', teamId: 2),
    ];
    _updateState(() {
      _isMultiplayerMatch = true;
      _multiplayerPlayers = remotePlayers;
      _controlledHumanPlayerIds = {'player_remote_a'};
      _game = ZapitiGameController(
        targetScore: _targetScore,
        players: remotePlayers,
        humanPlayerId: 'player_remote_a',
        authorizedTrucoPlayerIds: remotePlayers.map((player) => player.id),
        autoStart: false,
      );
      _startNewHand();
      _showMainMenu = true;
      _showCharacterSelection = false;
      _showDifficultySelection = false;
      _multiplayerMatchCanceled = false;
    });
  }

  @visibleForTesting
  Map<String, Object?> offlineRuntimeSnapshotForTesting() {
    return {
      'isMultiplayerMatch': _isMultiplayerMatch,
      'players': _players.map((player) => player.id).toList(),
      'controllerPlayers': _game.players.map((player) => player.id).toList(),
      'humanPlayerId': _game.humanPlayer.id,
      'hands': {
        for (final entry in _game.hands.entries) entry.key: entry.value.length,
      },
      'cardsRemaining': {
        for (final player in _players) player.id: _hands[player.id]?.length ?? 0,
      },
      'roomId': MultiplayerSessionStore.instance.activeRoomId,
      'localGamePlayerId': MultiplayerSessionStore.instance.localGamePlayerId,
      'hasSocket': MultiplayerSessionStore.instance.socket != null,
      'controlledPlayerIds': _controlledHumanPlayerIds.toList(),
      'activeSignals': _activeStrategicSignals.length,
      'pendingOrders': _forceWinRequestedPlayerIds.length +
          _forceHighestRequestedPlayerIds.length +
          _forceLowestRequestedPlayerIds.length,
    };
  }

  @visibleForTesting
  void prepareMultiplayerSignalRequestScenarioForTesting({
    required String localPlayerId,
  }) {
    const players = [
      Player(id: 'player_a', name: 'Jugador A', teamId: 1),
      Player(id: 'player_b', name: 'Jugador B', teamId: 1),
      Player(id: 'player_c', name: 'Rival C', teamId: 2),
      Player(id: 'player_d', name: 'Rival D', teamId: 2),
    ];
    MultiplayerSessionStore.instance.localGamePlayerId = localPlayerId;
    MultiplayerSessionStore.instance.reconnectRoomId = 'ROOM_TEST';
    _updateState(() {
      _isMultiplayerMatch = true;
      _multiplayerPlayers = players;
      _controlledHumanPlayerIds = {localPlayerId};
      _game = ZapitiGameController(
        targetScore: _targetScore,
        players: players,
        humanPlayerId: localPlayerId,
        authorizedTrucoPlayerIds: players.map((player) => player.id),
        autoStart: false,
      );
      _beginGameSession('multiplayer');
      _startNewHand();
    });
  }

  @visibleForTesting
  void simulateIncomingSignalRequestForTesting({
    required String senderPlayerId,
    String? receiverPlayerId,
    required String requestId,
  }) {
    _handleIncomingMultiplayerSignalRequest(
      MultiplayerMessage(
        type: MultiplayerMessageType.requestSignal,
        roomId: 'ROOM_TEST',
        playerId: senderPlayerId,
        messageId: requestId,
        payload: {
          'requestId': requestId,
          if (receiverPlayerId != null) 'receiverPlayerId': receiverPlayerId,
        },
      ),
    );
  }

  @visibleForTesting
  String? get companionPrivateSignalStatusForTesting =>
      _companionPrivateSignalStatus;

  @visibleForTesting
  String? get companionPrivateSignalRequestIdForTesting =>
      _companionPrivateSignalRequestId;

  @visibleForTesting
  Future<void> showAlVerDecisionDialogForTesting() async {
    final teamId = _game.alVerTeamId;
    if (teamId == null) return;
    await _presentAlVerDecisionDialog(teamId);
  }

  @visibleForTesting
  Future<void> resolveAlVerDecisionForTesting() async {
    final teamId = _game.alVerTeamId;
    if (teamId == null) return;
    await _processPendingAlVerDecision(
      teamId,
      teamIsHumanControlled: _isTeamControlledByHuman(teamId),
    );
  }

  @visibleForTesting
  void loadGuidedTutorialScenarioForTesting(int index) {
    _isGuidedTutorialMatch = true;
    _guidedTutorialCompleted = false;
    _loadGuidedTutorialScenario(index);
  }

  @visibleForTesting
  void prepareComeToMeScenarioForTesting() {
    _isGuidedTutorialMatch = false;
    _guidedTutorialCompleted = false;
    _updateState(() {
      _game.nextLeadIndex = 0;
      _game.score[TeamRules.teamOne] = 0;
      _game.score[TeamRules.teamTwo] = 0;
      _game.startNewHand(
        fixedHands: {
          'p1': const [
            SpanishCard(value: 3, suit: Suit.oros),
            SpanishCard(value: 5, suit: Suit.copas),
            SpanishCard(value: 6, suit: Suit.espadas),
          ],
          'p2': const [
            SpanishCard(value: 4, suit: Suit.oros),
            SpanishCard(value: 5, suit: Suit.bastos),
            SpanishCard(value: 6, suit: Suit.copas),
          ],
          'p3': const [
            SpanishCard(value: 4, suit: Suit.bastos),
            SpanishCard(value: 12, suit: Suit.oros),
            SpanishCard(value: 5, suit: Suit.espadas),
          ],
          'p4': const [
            SpanishCard(value: 4, suit: Suit.copas),
            SpanishCard(value: 5, suit: Suit.oros),
            SpanishCard(value: 6, suit: Suit.bastos),
          ],
        },
      );
      _game.roundHistory.add(
        RoundResult(
          playedCards: const [],
          winner: PlayedCard(
            player: ZapitiPlayers.human,
            card: SpanishCard(value: 3, suit: Suit.oros),
          ),
        ),
      );
      _game.roundWins[TeamRules.teamOne] = 1;
      _game.roundWins[TeamRules.teamTwo] = 0;
      _game.playedCards.clear();
      _game.turnIndex = 2;
      _game.leadIndex = 0;
      _game.isRoundAwaitingContinue = false;
      _game.handFinished = false;
      _forceLowestRequestedPlayerIds
        ..clear()
        ..add(ZapitiPlayers.companion.id);
      _forceWinRequestedPlayerIds.clear();
      _forceHighestRequestedPlayerIds.clear();
      _isAutoPlaying = false;
      _status = 'Escenario Ven a mí listo.';
    });
  }

  @visibleForTesting
  Future<void> advanceBotsForTesting() async {
    await _advanceBots();
  }

  @visibleForTesting
  SpanishCard chooseCurrentBotCardForTesting() {
    final bot = _currentPlayer;
    final hand = _hands[bot.id];
    if (hand == null) {
      throw StateError('El jugador actual no tiene mano cargada.');
    }
    return _chooseBotCard(bot, hand);
  }

  bool get _canHumanCallTruco {
    if (_isRoundAwaitingContinue ||
        _isWaitingHumanTrucoResponse ||
        _isAutoPlaying) {
      return false;
    }
    final nextValue = _game.nextTrucoValueForPlayer(_humanPlayer);
    if (nextValue == null) return false;
    return _game.canCallTruco(
      _humanPlayer,
      value: nextValue,
      actorPlayerId: _humanPlayer.id,
    );
  }

  List<int> get _humanRaiseOptions {
    if (!_isWaitingHumanTrucoResponse || _pendingTrucoValue == null) {
      return const [];
    }
    return _game.raiseOptions;
  }

  bool get _canHumanPassHand =>
      _game.canPassHand(from: _humanPlayer, to: _companionPlayer);

  int get _displayedRoundNumber => _game.displayedRoundNumber;
  Player get _companionPlayer => _players.firstWhere(
        (player) =>
            player.teamId == _humanPlayer.teamId &&
            player.id != _humanPlayer.id,
      );

  String _localizedPlayerName(Player player) {
    if (_isMultiplayerMatch && _multiplayerPlayers.isNotEmpty) {
      return player.name;
    }
    switch (player.id) {
      case 'p1':
        return context.tr('playerYou');
      case 'p2':
        return context.tr('playerRightRival');
      case 'p3':
        return context.tr('playerCompanion');
      case 'p4':
        return context.tr('playerLeftRival');
      default:
        return player.name;
    }
  }

  Map<String, String> get _localizedPlayerNames => {
        for (final player in _players) player.id: _localizedPlayerName(player),
      };

  String _localizedSignalName(String signal) {
    switch (signal) {
      case '4 Bastos':
        return context.tr('signalCard4Bastos');
      case '7 Copas':
        return context.tr('signalCard7Copas');
      case '7 Oros':
        return context.tr('signalCard7Oros');
      case 'As Espadas':
        return context.tr('signalCardAsEspadas');
      case 'Treses':
        return context.tr('signalCardTreses');
      case 'Doses':
        return context.tr('signalCardDoses');
      case 'Ases':
        return context.tr('signalCardAses');
      case 'Mala':
        return context.tr('badHand');
      default:
        return signal;
    }
  }

  void _setCompanionPrivateSignalStatus(
    String? value, {
    Duration? clearAfter,
    String? requestId,
  }) {
    _companionPrivateSignalTimer?.cancel();
    _companionPrivateSignalTimer = null;
    _companionPrivateSignalStatus = value;
    _companionPrivateSignalRequestId = requestId;
    if (value == null || clearAfter == null) {
      return;
    }
    _companionPrivateSignalTimer = Timer(clearAfter, () {
      if (!mounted) return;
      _updateState(() {
        if (_companionPrivateSignalStatus == value &&
            _companionPrivateSignalRequestId == requestId) {
          _companionPrivateSignalStatus = null;
          _companionPrivateSignalRequestId = null;
        }
        _companionPrivateSignalTimer = null;
      });
    });
  }

  void _sendMultiplayerSignalToCompanion({
    required String label,
    String? kind,
    bool active = true,
  }) {
    if (!_isMultiplayerMatch || !_canSendMultiplayerAction) return;

    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = _multiplayerRoomId;
    final playerId =
        MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
    if (socket == null || !socket.isConnected || roomId == null) return;

    socket.signal(
      roomId: roomId,
      playerId: playerId,
      label: label,
      active: active,
      kind: kind,
    );
  }

  void _requestMultiplayerCompanionSignal() {
    if (!_isMultiplayerMatch || !_canSendMultiplayerAction) return;

    final socket = MultiplayerSessionStore.instance.socket;
    final roomId = _multiplayerRoomId;
    final playerId =
        MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
    if (socket == null || !socket.isConnected || roomId == null) return;

    final requestId =
        '${_sessionLifecycle.generation}-${++_localSignalRequestSequence}';
    ZapitiLogger.info('client_send', 'signal_request_send', fields: {
      'sessionId': _sessionLifecycle.generation,
      'roomId': roomId,
      'senderPlayerId': playerId,
      'receiverPlayerId': _companionPlayer.id,
      'eventType': MultiplayerMessageType.requestSignal.wireName,
      'requestId': requestId,
      'ts': DateTime.now().toIso8601String(),
      'isRequestingBefore': _isRequestingCompanionSignal,
    });
    socket.requestSignal(
      roomId: roomId,
      playerId: playerId,
      requestId: requestId,
      receiverPlayerId: _companionPlayer.id,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game = ZapitiGameController(
      targetScore: _targetScore,
      players: _players,
      authorizedTrucoPlayerIds: _localAuthorizedTrucoPlayerIds(
        _players,
        ZapitiPlayers.human.id,
      ),
      allowPassHand: _allowPassHand,
      autoStart: false,
    );
    _startNewHand();
    _loadSavedCharacterSelection();
    unawaited(_syncMusic());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isHumanTurn && !_handFinished) {
        _advanceBots();
      }
    });
  }

  Future<AppVersionCheckResult> _checkAppVersion() async {
    final requestId = ++_versionCheckRequestId;
    _updateState(() {
      _versionCheck = AppVersionCheckResult.checking;
    });
    final result = await GameScreen.versionCheckService.check();
    if (!mounted || requestId != _versionCheckRequestId) return result;
    _updateState(() {
      _versionCheck = result;
    });
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_syncMusic());
        return;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_musicPlayer.stop());
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endCurrentGameSession(reason: 'game_screen_dispose', notifyLeave: false);
    _musicPlayer.dispose();
    super.dispose();
  }

  void _showTemporaryPlayerMessage(
    String playerId,
    String message, {
    Duration duration = const Duration(seconds: 1),
  }) {
    _playerMessageTimers.remove(playerId)?.cancel();
    _playerMessages[playerId] = message;
    _playerMessageTimers[playerId] = Timer(duration, () {
      if (!mounted) return;
      _updateState(() {
        if (_playerMessages[playerId] == message) {
          _playerMessages.remove(playerId);
        }
        _playerMessageTimers.remove(playerId);
      });
    });
  }

  void _humanVoyATi() {
    if (_handFinished || _isGameFinished) return;
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;
    final label = context.tr('voyATi');
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, label);
      _recordStrategicSignal(
        type: StrategicSignalType.voyATi,
        issuer: _humanPlayer,
        targetPlayerId: _humanPlayer.id,
        label: label,
      );
      if (!_controlledHumanPlayerIds.contains(_companionPlayer.id) &&
          !_playedCards.any((card) => card.player.id == _companionPlayer.id)) {
        _forceWinRequestedPlayerIds.add(_companionPlayer.id);
      }
    });
    _sendMultiplayerSignalToCompanion(label: label, kind: 'voy_a_ti');
  }

  void _humanVenAMi() {
    if (_handFinished || _isGameFinished) return;
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;
    final label = context.tr('comeToMe');
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, label);
      _recordStrategicSignal(
        type: StrategicSignalType.venAMi,
        issuer: _humanPlayer,
        targetPlayerId: _companionPlayer.id,
        label: label,
      );
      if (!_controlledHumanPlayerIds.contains(_companionPlayer.id) &&
          !_playedCards.any((card) => card.player.id == _companionPlayer.id)) {
        _forceLowestRequestedPlayerIds.add(_companionPlayer.id);
      }
      _status = context.tr(
        'askCompanionComeToMe',
        params: {'name': _localizedPlayerName(_companionPlayer)},
      );
    });
    _sendMultiplayerSignalToCompanion(label: label, kind: 'ven_a_mi');
  }

  void _humanMata() {
    if (_handFinished || _isGameFinished) return;
    if (_isMultiplayerMatch && !_ensureMultiplayerActionConnection()) return;
    final label = context.tr('kill');
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, label);
      _recordStrategicSignal(
        type: StrategicSignalType.mata,
        issuer: _humanPlayer,
        targetPlayerId: _companionPlayer.id,
        label: label,
      );
      if (!_controlledHumanPlayerIds.contains(_companionPlayer.id) &&
          !_playedCards.any((card) => card.player.id == _companionPlayer.id)) {
        _forceWinRequestedPlayerIds.add(_companionPlayer.id);
      }
      _status = context.tr(
        'askCompanionKill',
        params: {'name': _localizedPlayerName(_companionPlayer)},
      );
    });
    _sendMultiplayerSignalToCompanion(label: label, kind: 'mata');
  }

  void _humanPassHand() {
    if (!_canHumanPassHand) return;
    if (_isMultiplayerMatch) {
      if (!_ensureMultiplayerActionConnection()) return;
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = _multiplayerRoomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.passHand(
          roomId: roomId,
          playerId: playerId,
          toPlayerId: _companionPlayer.id,
          expectedStateVersion: _multiplayerStateVersion,
        );
      }
      return;
    }

    _updateState(() {
      _game.passHand(from: _humanPlayer, to: _companionPlayer);
    });
    _advanceBots();
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  void _updateState(VoidCallback action) {
    setState(action);
  }

  @override
  Widget build(BuildContext context) {
    return ZapitiLocalizations(
      language: _language,
      child: Builder(
        builder: (context) {
          final cardsRemaining = {
            for (final player in _players)
              player.id: _hands[player.id]?.length ?? 0,
          };
          _maybeHandleAlVerDecision();

          if (_showMainMenu) {
            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: _MainMenuScreen(
                onPlay: _startFromMainMenu,
                onTutorial: _openMainMenuTutorial,
                onOptions: _openMainMenuOptions,
                onMultiplayer: _openMainMenuMultiplayer,
                onAbout: _openAboutScreen,
                onExit: () => unawaited(SystemNavigator.pop()),
                onStartTableTutorial: _startGuidedTutorialMatch,
                onEnterGame: _enterMultiplayerMatch,
                selectedCharacterId: _selectedHumanCharacterId,
                onSelectedCharacterChanged: _selectHumanCharacter,
                onBack: _closeMainMenuPanel,
                panel: _mainMenuPanel,
                audioEnabled: _audioEnabled,
                onAudioChanged: _setAudioEnabled,
                audioVolume: _audioVolume,
                onAudioVolumeChanged: _setAudioVolume,
                botSpeed: _botSpeed,
                onBotSpeedChanged: _setBotSpeed,
                confirmCardPlay: _confirmCardPlay,
                onConfirmCardPlayChanged: _setConfirmCardPlay,
                language: _language,
                onLanguageChanged: _setLanguage,
                versionCheck: _versionCheck,
              ),
            );
          }

          if (_showCharacterSelection) {
            return Scaffold(
              body: SafeArea(
                child: _CharacterSelectionScreen(
                  selectedCharacterId: _selectedHumanCharacterId,
                  onSelected: _selectHumanCharacter,
                  onBack: _backToMainMenuFromCharacterSelection,
                  onStart: _continueToDifficultySelection,
                ),
              ),
            );
          }

          if (_showDifficultySelection) {
            return Scaffold(
              body: SafeArea(
                child: _DifficultySelectionScreen(
                  selectedDifficulty: _selectedDifficulty,
                  onSelected: _selectDifficulty,
                  onBack: _backToCharacterSelection,
                  onStart: _startWithSelectedSettings,
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: ZapitiColors.woodDark,
            body: SafeArea(
              child: _WoodBackground(
                child: Stack(
                  children: [
                    OrientationBuilder(
                      builder: (context, orientation) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final isPortrait =
                                orientation == Orientation.portrait;
                            final shortest = min(
                                constraints.maxWidth, constraints.maxHeight);
                            final gap = shortest * (isPortrait ? 0.018 : 0.008);
                            final padding = EdgeInsets.all(
                                shortest * (isPortrait ? 0.018 : 0.006));
                            final connectionBlocked = _isMultiplayerMatch &&
                                !_canSendMultiplayerAction;
                            final multiplayerBlocked =
                                connectionBlocked || _multiplayerMatchCanceled;
                            final canUseGameControls =
                                !_guidedTutorialCompleted &&
                                    !multiplayerBlocked;
                            final header = _CompactGameHeader(
                              roundNumber: _displayedRoundNumber,
                              handValue: _handValue,
                              betState: _betState,
                              difficultyProfile: DifficultyProfiles.byLevel(
                                  _selectedDifficulty),
                            );
                            final scorePanel = _GameScorePanel(
                              scoreTeamOne: _score[1]!,
                              scoreTeamTwo: _score[2]!,
                              roundWinsTeamOne: _roundWins[1]!,
                              roundWinsTeamTwo: _roundWins[2]!,
                              targetScore: _targetScore,
                            );
                            final controls = _VisibleGameControls(
                              compact: isPortrait,
                              signalsEnabled: canUseGameControls &&
                                  !_handFinished &&
                                  !_isGameFinished,
                              isGameFinished: _isGameFinished,
                              isHandFinished:
                                  canUseGameControls && _handFinished,
                              isRoundAwaitingContinue: canUseGameControls &&
                                  _isRoundAwaitingContinue,
                              isWaitingHumanResponse: canUseGameControls &&
                                  _isWaitingHumanTrucoResponse,
                              isHumanTurn: canUseGameControls && _isHumanTurn,
                              canPassHand:
                                  canUseGameControls && _canHumanPassHand,
                              canCallTruco:
                                  canUseGameControls && _canHumanCallTruco,
                              handValue: _handValue,
                              betState: _betState,
                              raiseOptions: _humanRaiseOptions,
                              onSignalStart: _startSignal,
                              onSignalEnd: _endSignal,
                              onShowSignalHelp: canUseGameControls
                                  ? _showSignalHelpDialog
                                  : null,
                              onAskCompanionSignal: _requestCompanionSignal,
                              onPassHand: _humanPassHand,
                              onVoyATi: _humanVoyATi,
                              onComeToMe: _humanVenAMi,
                              onKill: _humanMata,
                              onCallTruco: _humanCallsTruco,
                              onAcceptTruco: _humanAcceptsTruco,
                              onPassTruco: _humanPassesTruco,
                              onRaiseTruco: _humanRaisesTruco,
                              onContinueRound: _continueAfterRound,
                              onNewHand: _newHand,
                              onRestart: _restartGame,
                              onOptions:
                                  canUseGameControls ? _openGameOptions : null,
                              onBack: _confirmReturnToMainMenu,
                            );
                            Widget table() {
                              return LayoutBuilder(
                                builder: (context, tableConstraints) {
                                  return ZapitiGameTable(
                                    height: tableConstraints.maxHeight,
                                    players: _players,
                                    currentPlayer: _currentPlayer,
                                    humanHand: _humanHand,
                                    playedCards: _playedCards,
                                    playerMessages: _playerMessages,
                                    playerDisplayNames: _localizedPlayerNames,
                                    characterIdsByPlayer: _characterIdsByPlayer,
                                    cardsRemaining: cardsRemaining,
                                    turnSecondsRemaining: _turnSecondsRemaining,
                                    isHumanTurn:
                                        canUseGameControls && _isHumanTurn,
                                    showHumanSeat: isPortrait,
                                    onPlayCard: _playHumanCard,
                                  );
                                },
                              );
                            }

                            Widget tableWithAlVerOverlay() {
                              return Stack(
                                children: [
                                  Positioned.fill(child: table()),
                                  if (canUseGameControls &&
                                      _isAlVerDecisionDialogOpen &&
                                      _game.alVerState ==
                                          AlVerState.awaitingDecision &&
                                      _game.alVerTeamId != null &&
                                      _isTeamControlledByHuman(
                                          _game.alVerTeamId!))
                                    _AlVerDecisionOverlay(
                                      teamId: _game.alVerTeamId!,
                                      onAskCompanionSignal:
                                          _requestCompanionSignal,
                                      onSignalStart: _startSignal,
                                      onSignalEnd: _endSignal,
                                      onPlay: (teamId) =>
                                          _handleHumanAlVerDecision(
                                        teamId,
                                        play: true,
                                      ),
                                      onGoHome: (teamId) =>
                                          _handleHumanAlVerDecision(
                                        teamId,
                                        play: false,
                                      ),
                                    ),
                                ],
                              );
                            }

                            Widget hudTile(Widget child, Alignment alignment) {
                              return LayoutBuilder(
                                builder: (context, tileConstraints) {
                                  final width = min(
                                        tileConstraints.maxWidth,
                                        tileConstraints.maxHeight *
                                            (isPortrait ? 3.2 : 5.6),
                                      ) *
                                      0.72;

                                  return Align(
                                    alignment: alignment,
                                    child: SizedBox(
                                      width: width,
                                      height: tileConstraints.maxHeight,
                                      child: child,
                                    ),
                                  );
                                },
                              );
                            }

                            if (isPortrait) {
                              return Padding(
                                padding: padding,
                                child: Column(
                                  children: [
                                    Flexible(
                                      flex: 18,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 56,
                                            child: hudTile(
                                                header, Alignment.centerLeft),
                                          ),
                                          SizedBox(width: gap),
                                          Expanded(
                                            flex: 44,
                                            child: hudTile(scorePanel,
                                                Alignment.centerRight),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: gap * 0.55),
                                    Expanded(
                                        flex: 67,
                                        child: tableWithAlVerOverlay()),
                                    SizedBox(height: gap * 0.55),
                                    Flexible(flex: 15, child: controls),
                                  ],
                                ),
                              );
                            }

                            final width = constraints.maxWidth;
                            final height = constraints.maxHeight;
                            final scale = min(
                              1.25,
                              min(width / 932, height / 430),
                            );
                            final edge = max(8.0, 12 * scale);
                            final headerWidth =
                                (195 * scale).clamp(150.0, 244.0);
                            final headerHeight = (54 * scale).clamp(44.0, 68.0);
                            final scoreWidth =
                                (195 * scale).clamp(162.0, 244.0);
                            final scoreHeight = (82 * scale).clamp(66.0, 102.0);
                            final bottomHeight =
                                (140 * scale).clamp(120.0, 170.0).toDouble();
                            final tableTop =
                                max(headerHeight * 0.58, 30 * scale);
                            final tableBottom = bottomHeight + 4 * scale;
                            final tableSideInset =
                                (12 * scale).clamp(4.0, 24.0);

                            return Padding(
                              padding: EdgeInsets.all(edge),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    width: headerWidth,
                                    height: headerHeight,
                                    child: _CompactGameHeader(
                                      roundNumber: _displayedRoundNumber,
                                      handValue: _handValue,
                                      betState: _betState,
                                      difficultyProfile:
                                          DifficultyProfiles.byLevel(
                                        _selectedDifficulty,
                                      ),
                                      visualScale: scale,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    width: scoreWidth,
                                    height: scoreHeight,
                                    child: _GameScorePanel(
                                      scoreTeamOne: _score[1]!,
                                      scoreTeamTwo: _score[2]!,
                                      roundWinsTeamOne: _roundWins[1]!,
                                      roundWinsTeamTwo: _roundWins[2]!,
                                      targetScore: _targetScore,
                                      visualScale: scale,
                                    ),
                                  ),
                                  Positioned(
                                    left: tableSideInset,
                                    right: tableSideInset,
                                    top: tableTop,
                                    bottom: tableBottom,
                                    child: tableWithAlVerOverlay(),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    height: bottomHeight,
                                    child: _LandscapeBottomBoard(
                                      scale: scale,
                                      playerName: _localizedPlayerName(
                                        _humanPlayer,
                                      ),
                                      cards: _humanHand,
                                      enabled:
                                          canUseGameControls && _isHumanTurn,
                                      isCurrent:
                                          _humanPlayer.id == _currentPlayer.id,
                                      message: _playerMessages[_humanPlayer.id],
                                      turnSecondsRemaining:
                                          _humanPlayer.id == _currentPlayer.id
                                              ? _turnSecondsRemaining
                                              : null,
                                      companionMessage:
                                          _companionPrivateSignalStatus,
                                      characterId: _characterIdsByPlayer[
                                              _humanPlayer.id] ??
                                          _humanPlayer.id,
                                      signalsEnabled: canUseGameControls &&
                                          !_handFinished &&
                                          !_isGameFinished,
                                      isGameFinished: _isGameFinished,
                                      isHandFinished:
                                          canUseGameControls && _handFinished,
                                      isRoundAwaitingContinue:
                                          canUseGameControls &&
                                              _isRoundAwaitingContinue,
                                      isWaitingHumanResponse:
                                          canUseGameControls &&
                                              _isWaitingHumanTrucoResponse,
                                      isHumanTurn:
                                          canUseGameControls && _isHumanTurn,
                                      canPassHand: canUseGameControls &&
                                          _canHumanPassHand,
                                      canCallTruco: canUseGameControls &&
                                          _canHumanCallTruco,
                                      onPlayCard: _playHumanCard,
                                      onSignalStart: _startSignal,
                                      onSignalEnd: _endSignal,
                                      onShowSignalHelp: canUseGameControls
                                          ? _showSignalHelpDialog
                                          : null,
                                      onAskCompanionSignal:
                                          _requestCompanionSignal,
                                      onPassHand: _humanPassHand,
                                      onVoyATi: _humanVoyATi,
                                      onComeToMe: _humanVenAMi,
                                      onKill: _humanMata,
                                      onCallTruco: _humanCallsTruco,
                                      onContinueRound: _continueAfterRound,
                                      onNewHand: _newHand,
                                      onRestart: _restartGame,
                                      onOptions: canUseGameControls
                                          ? _openGameOptions
                                          : null,
                                      onBack: _confirmReturnToMainMenu,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (!_guidedTutorialCompleted &&
                        _isWaitingHumanTrucoResponse &&
                        _betState.responsePending &&
                        _betState.proposedLevel != null)
                      _TrucoResponseOverlay(
                        pendingTrucoValue: _betState.proposedLevel!.value,
                        raiseOptions: _humanRaiseOptions,
                        onAskCompanionSignal: _requestCompanionSignal,
                        onSignalStart: _startSignal,
                        onSignalEnd: _endSignal,
                        onAccept: _humanAcceptsTruco,
                        onPass: _humanPassesTruco,
                        onRaise: _humanRaisesTruco,
                      ),
                    if (_isGuidedTutorialMatch || _guidedTutorialCompleted)
                      _GuidedTutorialOverlay(
                        scenario: _guidedTutorialScenarios[
                            _guidedTutorialScenarioIndex],
                        index: _guidedTutorialScenarioIndex,
                        total: _guidedTutorialScenarios.length,
                        completed: _guidedTutorialCompleted,
                      ),
                    if (_isMultiplayerMatch && !_canSendMultiplayerAction)
                      _MultiplayerConnectionOverlay(
                        reconnecting: _isRecoveringMultiplayerConnection ||
                            _isAwaitingMultiplayerResync,
                        onReturnToMenu: _multiplayerConnectionFailed
                            ? _returnToMainMenu
                            : null,
                      ),
                    if (_multiplayerMatchCanceled)
                      _MultiplayerMatchCanceledOverlay(
                        onReturnToMenu: _returnToMainMenu,
                      ),
                    if (_isGameFinished && _winningTeamId != null)
                      _GameFinishedOverlay(
                        winningTeamId: _winningTeamId!,
                        winningPlayers: _players
                            .where((player) => player.teamId == _winningTeamId)
                            .toList(),
                        scoreTeamOne: _score[TeamRules.teamOne]!,
                        scoreTeamTwo: _score[TeamRules.teamTwo]!,
                        onRestart: _restartGame,
                        playerNameBuilder: _localizedPlayerName,
                      ),
                    if (_showGameOptions)
                      _GameOptionsOverlay(
                        audioEnabled: _audioEnabled,
                        onAudioChanged: _setAudioEnabled,
                        audioVolume: _audioVolume,
                        onAudioVolumeChanged: _setAudioVolume,
                        botSpeed: _botSpeed,
                        onBotSpeedChanged: _setBotSpeed,
                        confirmCardPlay: _confirmCardPlay,
                        onConfirmCardPlayChanged: _setConfirmCardPlay,
                        language: _language,
                        onLanguageChanged: _setLanguage,
                        onClose: _closeGameOptions,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
