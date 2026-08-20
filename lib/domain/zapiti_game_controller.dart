import 'al_ver_rules.dart';
import 'bet_state.dart';
import 'hand_rules.dart';
import 'legal_actions.dart';
import 'limited_history.dart';
import 'played_card.dart';
import 'player.dart';
import 'round_result.dart';
import 'round_rules.dart';
import 'spanish_card.dart';
import 'team_rules.dart';
import 'truco_rules.dart';
import 'zapiti_deck.dart';
import 'zapiti_players.dart';

enum AlVerState {
  none,
  awaitingDecision,
  playing,
  conceded,
}

enum TrucoNegotiationState {
  notStarted,
  awaitingResponse,
  acceptedClosed,
  rejectedHandFinished,
}

class PassedHandState {
  final String originalLeaderId;
  final String? passedToPlayerId;

  const PassedHandState({
    required this.originalLeaderId,
    this.passedToPlayerId,
  });

  bool get hasPassed => passedToPlayerId != null;

  PassedHandState passTo(String playerId) {
    return PassedHandState(
      originalLeaderId: originalLeaderId,
      passedToPlayerId: playerId,
    );
  }
}

class ZapitiGameController {
  static const defaultTargetScore = 30;

  final int targetScore;
  final List<Player> players;
  final String humanPlayerId;
  final Set<String> authorizedTrucoPlayerIds;
  final Map<int, int> score = {1: 0, 2: 0};
  final Map<int, int> roundWins = {1: 0, 2: 0};
  final LimitedHistory eventLog;
  final LimitedHistory handSummaries;
  bool allowPassHand;

  late Map<String, List<SpanishCard>> hands;
  final List<PlayedCard> playedCards = [];
  final List<RoundResult> roundHistory = [];

  final Set<int> alVerTeamIds = {};

  int turnIndex = 0;
  int leadIndex = 0;
  int nextLeadIndex = 0;
  late PassedHandState passedHandState;
  int handValue = 1;
  int? pendingTrucoValue;
  int? trucoCallerTeamId;
  int? lastTrucoRaiserTeamId;
  int? winningTeamId;
  AlVerState alVerState = AlVerState.none;
  TrucoNegotiationState trucoState = TrucoNegotiationState.notStarted;
  bool handFinished = false;
  bool isRoundAwaitingContinue = false;
  String status = '';
  late final LegalActionProvider legalActions;

  ZapitiGameController({
    this.targetScore = defaultTargetScore,
    this.players = ZapitiPlayers.tableOrder,
    this.humanPlayerId = 'p1',
    Iterable<String>? authorizedTrucoPlayerIds,
    LimitedHistory? eventLog,
    LimitedHistory? handSummaries,
    this.allowPassHand = false,
    bool autoStart = true,
  })  : authorizedTrucoPlayerIds = Set.unmodifiable(
          authorizedTrucoPlayerIds ??
              _defaultAuthorizedTrucoPlayerIds(players, humanPlayerId),
        ),
        eventLog = eventLog ?? LimitedHistory(limit: 6),
        handSummaries = handSummaries ?? LimitedHistory(limit: 8) {
    legalActions = ControllerLegalActionProvider(this);
    passedHandState = PassedHandState(originalLeaderId: players.first.id);
    if (autoStart) {
      startNewHand();
    }
  }

  Player get currentPlayer => players[turnIndex];
  Player get humanPlayer => players.firstWhere(
        (player) => player.id == humanPlayerId,
        orElse: () => players.first,
      );
  List<SpanishCard> get humanHand => hands[humanPlayer.id] ?? const [];
  bool get isGameFinished => winningTeamId != null;
  bool get isTrucoPending => pendingTrucoValue != null;
  BetState get betState => BetState(
        acceptedLevel: BetLevel.fromAcceptedValue(handValue),
        proposedLevel: pendingTrucoValue == null
            ? null
            : BetLevel.fromProposedValue(pendingTrucoValue!),
        proposingTeam: trucoCallerTeamId,
        respondingTeam: respondingTrucoTeamId,
        lastRaisingTeam: lastTrucoRaiserTeamId,
        responsePending: trucoState == TrucoNegotiationState.awaitingResponse,
      );
  int? get alVerTeamId => alVerTeamIds.length == 1 ? alVerTeamIds.first : null;
  bool get isTrucoAccepted =>
      trucoState == TrucoNegotiationState.acceptedClosed;
  set isTrucoAccepted(bool value) {
    trucoState = value
        ? TrucoNegotiationState.acceptedClosed
        : pendingTrucoValue == null
            ? TrucoNegotiationState.notStarted
            : TrucoNegotiationState.awaitingResponse;
  }

  int? get respondingTrucoTeamId => trucoCallerTeamId == null
      ? null
      : TeamRules.opponentOf(trucoCallerTeamId!);
  int? nextTrucoValueForPlayer(Player player) {
    if (handFinished || isGameFinished) return null;
    if (alVerState == AlVerState.awaitingDecision) return null;
    if (alVerState != AlVerState.none && alVerTeamIds.contains(player.teamId)) {
      return null;
    }
    if (trucoState == TrucoNegotiationState.awaitingResponse) {
      if (respondingTrucoTeamId != player.teamId || pendingTrucoValue == null) {
        return null;
      }
      return TrucoRules.nextRaiseValue(
        currentAcceptedValue: pendingTrucoValue!,
        maxAllowedValue: maxAllowedTrucoValueForTeam(player.teamId),
      );
    }
    if (trucoState == TrucoNegotiationState.notStarted) {
      if (currentPlayer.id != player.id) return null;
      return TrucoRules.firstTrucoValue <=
              maxAllowedTrucoValueForTeam(player.teamId)
          ? TrucoRules.firstTrucoValue
          : null;
    }
    if (trucoState == TrucoNegotiationState.acceptedClosed &&
        lastTrucoRaiserTeamId != player.teamId) {
      return TrucoRules.nextRaiseValue(
        currentAcceptedValue: handValue,
        maxAllowedValue: maxAllowedTrucoValueForTeam(player.teamId),
      );
    }
    return null;
  }

  int get displayedRoundNumber {
    final offset = isRoundAwaitingContinue || handFinished ? 0 : 1;
    final number = roundHistory.length + offset;
    return number.clamp(1, 3);
  }

  int get maxAllowedTrucoValue {
    return TrucoRules.maxAllowedValue(
      scoreTeamOne: score[1]!,
      scoreTeamTwo: score[2]!,
      targetScore: targetScore,
      currentAcceptedValue: handValue,
    );
  }

  int maxAllowedTrucoValueForTeam(int teamId) {
    return TrucoRules.maxAllowedValueForTeam(
      teamScore: score[teamId]!,
      targetScore: targetScore,
      currentAcceptedValue: handValue,
    );
  }

  List<int> get raiseOptions {
    if (alVerState == AlVerState.awaitingDecision) {
      return const [];
    }
    final pending = pendingTrucoValue;
    final respondingTeam = respondingTrucoTeamId;
    if (pending == null ||
        respondingTeam == null ||
        trucoState != TrucoNegotiationState.awaitingResponse) {
      return const [];
    }
    return raiseOptionsForTeam(respondingTeam);
  }

  List<int> raiseOptionsForTeam(int teamId) {
    if (alVerState == AlVerState.awaitingDecision) {
      return const [];
    }
    if (alVerState != AlVerState.none && alVerTeamIds.contains(teamId)) {
      return const [];
    }
    final pending = pendingTrucoValue;
    if (pending == null ||
        respondingTrucoTeamId != teamId ||
        trucoState != TrucoNegotiationState.awaitingResponse) {
      return const [];
    }
    return TrucoRules.raiseOptions(
      pendingValue: pending,
      maxAllowedValue: maxAllowedTrucoValueForTeam(teamId),
    );
  }

  /// Reinicia marcador y empieza una partida nueva desde el primer jugador.
  void restartGame({Map<String, List<SpanishCard>>? fixedHands}) {
    score
      ..[1] = 0
      ..[2] = 0;
    handSummaries.clear();
    nextLeadIndex = 0;
    winningTeamId = null;
    startNewHand(fixedHands: fixedHands);
  }

  /// Empieza un reparto nuevo, rota el jugador inicial y limpia estado temporal.
  void startNewHand({Map<String, List<SpanishCard>>? fixedHands}) {
    if (isGameFinished) return;

    hands = fixedHands == null ? _dealRandomHands() : _cloneHands(fixedHands);
    playedCards.clear();
    roundHistory.clear();
    eventLog.clear();
    roundWins
      ..[1] = 0
      ..[2] = 0;
    handValue = 1;
    pendingTrucoValue = null;
    trucoCallerTeamId = null;
    lastTrucoRaiserTeamId = null;
    trucoState = TrucoNegotiationState.notStarted;
    handFinished = false;
    isRoundAwaitingContinue = false;
    leadIndex = nextLeadIndex;
    nextLeadIndex = (nextLeadIndex + 1) % players.length;
    turnIndex = leadIndex;
    _resetPassedHandState();
    _refreshAlVerState();
    status = currentPlayer.id == humanPlayer.id
        ? 'Sales tú. Juega tu primera carta.'
        : 'Sale ${currentPlayer.name}.';
    if (alVerState == AlVerState.awaitingDecision) {
      final summary = alVerTeamIds.length == 1
          ? 'Equipo ${alVerTeamIds.first} está al ver.'
          : 'Ambos equipos están al ver.';
      status = '$status $summary Decide antes de jugar.';
    } else if (alVerTeamIds.length == 2) {
      status = '$status Ambos equipos estÃ¡n al ver. La mano vale '
          '${AlVerRules.playPoints} chinos.';
    }
    _log(status);
  }

  /// Juega una carta y devuelve `true` si la ronda queda lista para resolver.
  bool playCard(Player player, SpanishCard card) {
    final playerHand = hands[player.id];
    if (playerHand == null || !playerHand.contains(card)) {
      throw ArgumentError('La carta no está en la mano de ${player.name}.');
    }
    if (alVerState == AlVerState.awaitingDecision) {
      throw StateError('La mano está al ver y debe decidirse antes de jugar.');
    }
    if (!canPlayCard(player, card)) {
      throw StateError('La carta no es legal en el estado actual.');
    }
    if (handFinished || isRoundAwaitingContinue) {
      throw StateError('No se puede jugar en el estado actual.');
    }

    playerHand.remove(card);
    playedCards.add(PlayedCard(player: player, card: card));
    _log('${player.name} juega ${card.toString()}.');

    if (playedCards.length == players.length) return true;

    turnIndex = (turnIndex + 1) % players.length;
    status = 'Turno de ${currentPlayer.name}.';
    return false;
  }

  bool canPlayCard(Player player, SpanishCard card) {
    return legalActions.legalCardsFor(player).contains(card);
  }

  List<SpanishCard> legalCardsForPlayer(Player player) {
    return legalActions.legalCardsFor(player);
  }

  List<BetAction> legalBetActionsForPlayer(Player player) {
    return legalActions.legalBetActionsFor(player);
  }

  /// Resuelve las cuatro cartas jugadas y congela la ronda hasta continuar.
  void resolveRound() {
    if (handFinished || isGameFinished) return;
    if (playedCards.length != players.length) {
      throw StateError('La ronda necesita cuatro cartas para resolverse.');
    }

    final roundNumber = roundHistory.length + 1;
    final result = RoundRules.resolveRound(playedCards);
    roundHistory.add(result);
    final progress = HandRules.resolve(roundHistory);
    _applyProgress(progress);

    if (result.isTie) {
      _handleTiedRound(result, roundNumber, progress);
    } else {
      _handleWonRound(result, progress);
    }

    isRoundAwaitingContinue = !handFinished && !isGameFinished;
  }

  /// Limpia la mesa tras revisar una ronda resuelta.
  void continueRound() {
    if (!isRoundAwaitingContinue) return;
    playedCards.clear();
    isRoundAwaitingContinue = false;
    _resetPassedHandState();
    status = 'Turno de ${currentPlayer.name}.';
  }

  bool canPassHand({
    required Player from,
    required Player to,
    String? actorPlayerId,
  }) {
    if (!allowPassHand) return false;
    if (actorPlayerId != null && actorPlayerId != from.id) return false;
    if (handFinished || isGameFinished || isRoundAwaitingContinue) {
      return false;
    }
    if (alVerState == AlVerState.awaitingDecision) return false;
    if (trucoState == TrucoNegotiationState.awaitingResponse) return false;
    if (roundHistory.isNotEmpty) return false;
    if (playedCards.isNotEmpty) return false;
    if (passedHandState.hasPassed) return false;
    if (from.id != currentPlayer.id) return false;
    if (from.id != passedHandState.originalLeaderId) return false;
    if (from.id == to.id || from.teamId != to.teamId) return false;
    if ((hands[from.id] ?? const <SpanishCard>[]).isEmpty) return false;
    if ((hands[to.id] ?? const <SpanishCard>[]).isEmpty) return false;
    if (playedCards.any((card) => card.player.id == from.id)) return false;
    if (playedCards.any((card) => card.player.id == to.id)) return false;
    return true;
  }

  void passHand({
    required Player from,
    required Player to,
    String? actorPlayerId,
  }) {
    if (!canPassHand(from: from, to: to, actorPlayerId: actorPlayerId)) {
      throw StateError('No se puede pasar mano en el estado actual.');
    }
    turnIndex = players.indexWhere((player) => player.id == to.id);
    passedHandState = passedHandState.passTo(to.id);
    status = '${from.name} pasa mano a ${to.name}. Sale ${to.name}.';
    _log(status);
  }

  /// Lanza o contra-sube truco para el equipo del jugador.
  void callTruco(
    Player player, {
    required int value,
    String? actorPlayerId,
  }) {
    if (!canCallTruco(player, value: value, actorPlayerId: actorPlayerId)) {
      throw ArgumentError('Subida de truco no permitida.');
    }
    final previouslyPendingValue = pendingTrucoValue;
    if (previouslyPendingValue != null) {
      handValue = previouslyPendingValue;
    }
    pendingTrucoValue = value;
    trucoCallerTeamId = player.teamId;
    lastTrucoRaiserTeamId = player.teamId;
    trucoState = TrucoNegotiationState.awaitingResponse;
    status =
        '${player.name} sube el reparto a $value ${_chinoLabel(value)}. El otro equipo debe responder.';
    _log(status);
  }

  /// Acepta el truco pendiente y actualiza el valor del reparto.
  void acceptTruco({required int teamId, String? actorPlayerId}) {
    final acceptedValue = pendingTrucoValue;
    if (!canAcceptTruco(teamId: teamId, actorPlayerId: actorPlayerId) ||
        acceptedValue == null) {
      throw StateError('No hay truco pendiente que aceptar.');
    }
    handValue = acceptedValue;
    pendingTrucoValue = null;
    trucoCallerTeamId = null;
    trucoState = TrucoNegotiationState.acceptedClosed;
    status =
        'Equipo $teamId acepta. El reparto vale $handValue ${_chinoLabel(handValue)}.';
    _log(status);
  }

  /// Sube una apuesta pendiente, aceptando antes el valor anterior.
  void raiseTruco(
    Player player, {
    required int value,
    String? actorPlayerId,
  }) {
    final pending = pendingTrucoValue;
    if (pending == null) {
      throw StateError('No hay truco pendiente que subir.');
    }
    if (!canCallTruco(player, value: value, actorPlayerId: actorPlayerId)) {
      throw ArgumentError('Subida no permitida.');
    }
    handValue = pending;
    callTruco(player, value: value, actorPlayerId: actorPlayerId);
  }

  /// Pasa el truco y concede al equipo apostador el último valor aceptado.
  void passTruco({required int passingTeamId, String? actorPlayerId}) {
    final callerTeamId = trucoCallerTeamId;
    if (!canPassTruco(
          passingTeamId: passingTeamId,
          actorPlayerId: actorPlayerId,
        ) ||
        callerTeamId == null ||
        pendingTrucoValue == null) {
      throw StateError('No hay truco pendiente que pasar.');
    }
    final nominalPoints = TrucoRules.passPoints(currentAcceptedValue: handValue);
    final points = TrucoRules.awardedPointsForTeam(
      teamScore: score[callerTeamId]!,
      targetScore: targetScore,
      nominalValue: nominalPoints,
    );
    trucoState = TrucoNegotiationState.rejectedHandFinished;
    _finishHandForTeam(
      callerTeamId,
      'Equipo $passingTeamId pasa. Equipo $callerTeamId suma $points ${_chinoLabel(points)}.',
      points: points,
    );
  }

  bool canCallTruco(
    Player player, {
    required int value,
    String? actorPlayerId,
  }) {
    if (!_isAuthorizedTrucoActor(actorPlayerId ?? player.id)) return false;
    if (handFinished || isGameFinished) return false;
    if (alVerState == AlVerState.awaitingDecision) return false;
    if (alVerState != AlVerState.none && alVerTeamIds.contains(player.teamId)) {
      return false;
    }
    if (value > maxAllowedTrucoValueForTeam(player.teamId)) return false;

    if (trucoState == TrucoNegotiationState.awaitingResponse) {
      if (trucoCallerTeamId == null || player.teamId == trucoCallerTeamId) {
        return false;
      }
      return raiseOptionsForTeam(player.teamId).contains(value);
    }

    if (trucoState == TrucoNegotiationState.notStarted) {
      if (currentPlayer.id != player.id) return false;
      return TrucoRules.isOpeningValue(value);
    }
    if (trucoState == TrucoNegotiationState.acceptedClosed) {
      if (lastTrucoRaiserTeamId == player.teamId) return false;
      return TrucoRules.isRaiseValue(
        currentAcceptedValue: handValue,
        value: value,
        maxAllowedValue: maxAllowedTrucoValueForTeam(player.teamId),
      );
    }
    return false;
  }

  bool canAcceptTruco({required int teamId, String? actorPlayerId}) {
    if (!_isAuthorizedTrucoActor(actorPlayerId ?? humanPlayerId)) return false;
    if (handFinished || isGameFinished) return false;
    if (alVerState == AlVerState.awaitingDecision) return false;
    return trucoState == TrucoNegotiationState.awaitingResponse &&
        pendingTrucoValue != null &&
        respondingTrucoTeamId == teamId;
  }

  bool canPassTruco({required int passingTeamId, String? actorPlayerId}) {
    if (!_isAuthorizedTrucoActor(actorPlayerId ?? humanPlayerId)) return false;
    if (handFinished || isGameFinished) return false;
    if (alVerState == AlVerState.awaitingDecision) return false;
    return trucoState == TrucoNegotiationState.awaitingResponse &&
        pendingTrucoValue != null &&
        respondingTrucoTeamId == passingTeamId;
  }

  /// Decide si el equipo al ver se queda a jugar o se va a casa.
  void chooseAlVerDecision({required int teamId, required bool play}) {
    if (alVerState != AlVerState.awaitingDecision) {
      throw StateError('No hay una decisión al ver pendiente.');
    }
    if (!alVerTeamIds.contains(teamId)) {
      throw ArgumentError('El equipo $teamId no está al ver.');
    }
    if (alVerTeamIds.length != 1) {
      throw StateError(
        'El caso con ambos equipos al ver queda pendiente de definición.',
      );
    }

    if (play) {
      alVerState = AlVerState.playing;
      status = 'Equipo $teamId decide jugar al ver. La mano vale '
          '${AlVerRules.playPoints} chinos.';
      status = 'Equipo $teamId decide jugar al ver. La mano continúa.';
      status = 'Equipo $teamId decide jugar al ver. La mano vale '
          '${AlVerRules.playPoints} chinos.';
      _log(status);
      return;
    }

    final rivalTeamId = TeamRules.opponentOf(teamId);
    alVerState = AlVerState.conceded;
    _finishHandForTeam(
      rivalTeamId,
      'Equipo $teamId se va a casa. Equipo $rivalTeamId suma '
      '${AlVerRules.concedePoints} chinos.',
      points: AlVerRules.concedePoints,
    );
  }

  bool _isAuthorizedTrucoActor(String actorPlayerId) {
    return authorizedTrucoPlayerIds.contains(actorPlayerId);
  }

  static Set<String> _defaultAuthorizedTrucoPlayerIds(
    List<Player> players,
    String humanPlayerId,
  ) {
    return {
      for (final player in players) player.id,
    };
  }

  void _handleWonRound(RoundResult result, HandProgress progress) {
    final winner = result.winner!;
    final winningTeam = winner.player.teamId;
    leadIndex = players.indexWhere((player) => player.id == winner.player.id);
    turnIndex = leadIndex;

    if (progress.isFinished && progress.winningTeamId != null) {
      _finishHandForTeam(
        progress.winningTeamId!,
        '${winner.player.name} gana con ${winner.card}. Equipo ${progress.winningTeamId} gana el reparto y suma ${_awardedHandPoints()} chinos.',
      );
      return;
    }

    status =
        '${winner.player.name} gana con ${winner.card}. Ronda para Equipo $winningTeam. Sale ${winner.player.name}.';
    _log('Ronda para Equipo $winningTeam.');
  }

  void _resetPassedHandState() {
    passedHandState = PassedHandState(originalLeaderId: players[leadIndex].id);
  }

  void _handleTiedRound(
    RoundResult result,
    int roundNumber,
    HandProgress progress,
  ) {
    if (progress.isNoPoints) {
      _finishHandWithoutPoints('Ambos equipos alcanzan dos chicos. '
          'El reparto termina empatado y nadie suma chinos.');
      return;
    }

    if (progress.isFinished && progress.winningTeamId != null) {
      _finishHandForTeam(
        progress.winningTeamId!,
        'Gana el reparto el Equipo ${progress.winningTeamId} por la primera ronda. Suma ${_awardedHandPoints()} chinos.',
      );
      return;
    }

    turnIndex = leadIndex;
    status =
        'Ronda $roundNumber empatada: un chico para cada equipo. Repite ${currentPlayer.name}.';
    _log(status);
  }

  void _finishHandForTeam(int teamId, String message, {int? points}) {
    if (handFinished) return;
    final awardedPoints = points ?? _awardedHandPoints();
    score[teamId] = (score[teamId]! + awardedPoints).clamp(0, targetScore);
    handFinished = true;
    isRoundAwaitingContinue = false;
    pendingTrucoValue = null;
    trucoCallerTeamId = null;
    handSummaries
        .add('Equipo $teamId +$awardedPoints (${score[1]}-${score[2]})');

    if (score[teamId]! >= targetScore) {
      winningTeamId = teamId;
      status = 'Equipo $teamId gana la partida con $targetScore chinos.';
    } else {
      status = message;
    }
    _log(status);
  }

  void _finishHandWithoutPoints(String message) {
    if (handFinished) return;
    handFinished = true;
    isRoundAwaitingContinue = false;
    pendingTrucoValue = null;
    trucoCallerTeamId = null;
    handSummaries.add('Sin puntos (${score[1]}-${score[2]})');
    status = message;
    _log(status);
  }

  void _applyProgress(HandProgress progress) {
    roundWins
      ..[TeamRules.teamOne] = progress.roundWinsFor(TeamRules.teamOne)
      ..[TeamRules.teamTwo] = progress.roundWinsFor(TeamRules.teamTwo);
  }

  void _refreshAlVerState() {
    alVerTeamIds.clear();
    final teamOneScore = score[TeamRules.teamOne]!;
    final teamTwoScore = score[TeamRules.teamTwo]!;
    if (teamOneScore == AlVerRules.triggerScore) {
      alVerTeamIds.add(TeamRules.teamOne);
    }
    if (teamTwoScore == AlVerRules.triggerScore) {
      alVerTeamIds.add(TeamRules.teamTwo);
    }
    alVerState = _normalizedAlVerState(
      requestedState: null,
      teamIds: alVerTeamIds,
    );
  }

  void syncAlVerSnapshot({
    required Iterable<int> teamIds,
    AlVerState? requestedState,
  }) {
    alVerTeamIds
      ..clear()
      ..addAll(teamIds);
    alVerState = _normalizedAlVerState(
      requestedState: requestedState,
      teamIds: alVerTeamIds,
    );
  }

  AlVerState _normalizedAlVerState({
    required AlVerState? requestedState,
    required Set<int> teamIds,
  }) {
    if (requestedState == AlVerState.conceded) {
      return AlVerState.conceded;
    }
    if (teamIds.isEmpty) {
      return AlVerState.none;
    }
    if (requestedState == AlVerState.awaitingDecision &&
        !AlVerRules.requiresDecision(teamIds)) {
      return AlVerState.playing;
    }
    if (requestedState == AlVerState.playing) {
      return AlVerState.playing;
    }
    return AlVerRules.requiresDecision(teamIds)
        ? AlVerState.awaitingDecision
        : AlVerState.playing;
  }

  int _awardedHandPoints() {
    if (alVerState == AlVerState.playing && alVerTeamIds.isNotEmpty) {
      return AlVerRules.playPoints;
    }
    final progress = HandRules.resolve(roundHistory);
    if (progress.winningTeamId == null) {
      return handValue;
    }
    return TrucoRules.awardedPointsForTeam(
      teamScore: score[progress.winningTeamId]!,
      targetScore: targetScore,
      nominalValue: handValue,
    );
  }

  Map<String, List<SpanishCard>> _dealRandomHands() {
    final deck = ZapitiDeck.shuffled();
    return {
      for (var i = 0; i < players.length; i++)
        players[i].id: deck.skip(i * 3).take(3).toList(),
    };
  }

  Map<String, List<SpanishCard>> _cloneHands(
    Map<String, List<SpanishCard>> source,
  ) {
    return {
      for (final player in players) player.id: [...source[player.id]!],
    };
  }

  void _log(String event) {
    eventLog.add(event);
  }

  String _chinoLabel(int value) => value == 1 ? 'chino' : 'chinos';
}
