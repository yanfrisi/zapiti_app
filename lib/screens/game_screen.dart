import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/bot_al_ver_strategy.dart';
import '../domain/bot_bluff_strategy.dart';
import '../domain/bot_table_read.dart';
import '../domain/bot_truco_raise_strategy.dart';
import '../domain/bot_truco_response_strategy.dart';
import '../domain/bot_truco_strategy.dart';
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
import '../services/game_preferences_store.dart';
import '../services/multiplayer_session_store.dart';
import '../services/zapiti_game_socket.dart';
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
  static const _multiplayerPlayerNamePrefsKey = 'multiplayer_player_name';
  static const _multiplayerPlayerIdPrefsKey = 'multiplayer_player_id';
  static const _multiplayerUsernamePrefsKey = 'multiplayer_username';
  static const _multiplayerPasswordPrefsKey = 'multiplayer_password';
  static const _multiplayerPlayerPinPrefsKey = 'multiplayer_player_pin';
  static const _multiplayerSessionTokenPrefsKey = 'multiplayer_session_token';
  static const _multiplayerTeamNamePrefsKey = 'multiplayer_team_name';

  final Map<String, String> _playerMessages = {};
  final Map<String, Timer> _playerMessageTimers = {};
  final Map<int, String> _knownSignalsByTeam = {};
  final Map<int, String> _teamSignalsByTeam = {};
  final Map<int, String> _opponentSignalsSeenByTeam = {};
  final Set<String> _playersSignaledThisHand = {};
  final Set<String> _forceWinRequestedPlayerIds = {};
  final Set<String> _forceHighestRequestedPlayerIds = {};
  final Set<String> _forceLowestRequestedPlayerIds = {};
  final Set<int> _aiTeamsConsideredTrucoThisHand = {};
  String? _companionPrivateSignalStatus;
  Random _random = Random();
  final GamePreferencesStore _preferencesStore = const GamePreferencesStore();
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
    for (final timer in _playerMessageTimers.values) {
      timer.cancel();
    }
    _playerMessageTimers.clear();
    _turnCountdownTimer?.cancel();
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
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, context.tr('voyATi'));
      if (!_controlledHumanPlayerIds.contains(_companionPlayer.id) &&
          !_playedCards.any((card) => card.player.id == _companionPlayer.id)) {
        _forceWinRequestedPlayerIds.add(_companionPlayer.id);
      }
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.signal(
          roomId: roomId,
          playerId: playerId,
          label: context.tr('voyATi'),
          kind: 'voy_a_ti',
        );
      }
    }
  }

  void _humanVenAMi() {
    if (_handFinished || _isGameFinished) return;
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, context.tr('comeToMe'));
      if (!_controlledHumanPlayerIds.contains(_companionPlayer.id) &&
          !_playedCards.any((card) => card.player.id == _companionPlayer.id)) {
        _forceLowestRequestedPlayerIds.add(_companionPlayer.id);
      }
      _status = context.tr(
        'askCompanionComeToMe',
        params: {'name': _companionPlayer.name},
      );
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.signal(
          roomId: roomId,
          playerId: playerId,
          label: context.tr('comeToMe'),
          kind: 'ven_a_mi',
        );
      }
    }
  }

  void _humanMata() {
    if (_handFinished || _isGameFinished) return;
    _updateState(() {
      _showTemporaryPlayerMessage(_humanPlayer.id, context.tr('kill'));
      if (!_controlledHumanPlayerIds.contains(_companionPlayer.id) &&
          !_playedCards.any((card) => card.player.id == _companionPlayer.id)) {
        _forceHighestRequestedPlayerIds.add(_companionPlayer.id);
      }
      _status = context.tr(
        'askCompanionKill',
        params: {'name': _companionPlayer.name},
      );
    });
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
      final playerId =
          MultiplayerSessionStore.instance.localGamePlayerId ?? _humanPlayer.id;
      if (socket != null && socket.isConnected && roomId != null) {
        socket.signal(
          roomId: roomId,
          playerId: playerId,
          label: context.tr('kill'),
          kind: 'mata',
        );
      }
    }
  }

  void _humanPassHand() {
    if (!_canHumanPassHand) return;
    if (_isMultiplayerMatch) {
      final socket = MultiplayerSessionStore.instance.socket;
      final roomId = MultiplayerSessionStore.instance.roomSnapshot?.roomId;
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
                            final canUseGameControls =
                                !_guidedTutorialCompleted;
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
                                      playerName: _humanPlayer.name,
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
                    if (_isGameFinished && _winningTeamId != null)
                      _GameFinishedOverlay(
                        winningTeamId: _winningTeamId!,
                        winningPlayers: _players
                            .where((player) => player.teamId == _winningTeamId)
                            .toList(),
                        scoreTeamOne: _score[TeamRules.teamOne]!,
                        scoreTeamTwo: _score[TeamRules.teamTwo]!,
                        onRestart: _restartGame,
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
