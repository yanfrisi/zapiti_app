import 'hand_rules.dart';
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

enum TrucoNegotiationState {
  notStarted,
  awaitingResponse,
  acceptedClosed,
  rejectedHandFinished,
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

  late Map<String, List<SpanishCard>> hands;
  final List<PlayedCard> playedCards = [];
  final List<RoundResult> roundHistory = [];

  int turnIndex = 0;
  int leadIndex = 0;
  int nextLeadIndex = 0;
  int handValue = 1;
  int? pendingTrucoValue;
  int? trucoCallerTeamId;
  int? lastTrucoRaiserTeamId;
  int? winningTeamId;
  TrucoNegotiationState trucoState = TrucoNegotiationState.notStarted;
  bool handFinished = false;
  bool isRoundAwaitingContinue = false;
  String status = '';

  ZapitiGameController({
    this.targetScore = defaultTargetScore,
    this.players = ZapitiPlayers.tableOrder,
    this.humanPlayerId = 'p1',
    Iterable<String>? authorizedTrucoPlayerIds,
    LimitedHistory? eventLog,
    LimitedHistory? handSummaries,
    bool autoStart = true,
  })  : authorizedTrucoPlayerIds = Set.unmodifiable(
          authorizedTrucoPlayerIds ??
              _defaultAuthorizedTrucoPlayerIds(players, humanPlayerId),
        ),
        eventLog = eventLog ?? LimitedHistory(limit: 6),
        handSummaries = handSummaries ?? LimitedHistory(limit: 8) {
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
    status = currentPlayer.id == humanPlayer.id
        ? 'Sales tú. Juega tu primera carta.'
        : 'Sale ${currentPlayer.name}.';
    _log(status);
  }

  /// Juega una carta y devuelve `true` si la ronda queda lista para resolver.
  bool playCard(Player player, SpanishCard card) {
    final playerHand = hands[player.id];
    if (playerHand == null || !playerHand.contains(card)) {
      throw ArgumentError('La carta no está en la mano de ${player.name}.');
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
    status = 'Turno de ${currentPlayer.name}.';
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
    final points = TrucoRules.passPoints(currentAcceptedValue: handValue);
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
    if (value > maxAllowedTrucoValueForTeam(player.teamId)) return false;

    if (trucoState == TrucoNegotiationState.awaitingResponse) {
      if (trucoCallerTeamId == null || player.teamId == trucoCallerTeamId) {
        return false;
      }
      return raiseOptionsForTeam(player.teamId).contains(value);
    }

    if (trucoState != TrucoNegotiationState.notStarted) return false;

    return TrucoRules.isOpeningValue(value);
  }

  bool canAcceptTruco({required int teamId, String? actorPlayerId}) {
    if (!_isAuthorizedTrucoActor(actorPlayerId ?? humanPlayerId)) return false;
    if (handFinished || isGameFinished) return false;
    return trucoState == TrucoNegotiationState.awaitingResponse &&
        pendingTrucoValue != null &&
        respondingTrucoTeamId == teamId;
  }

  bool canPassTruco({required int passingTeamId, String? actorPlayerId}) {
    if (!_isAuthorizedTrucoActor(actorPlayerId ?? humanPlayerId)) return false;
    if (handFinished || isGameFinished) return false;
    return trucoState == TrucoNegotiationState.awaitingResponse &&
        pendingTrucoValue != null &&
        respondingTrucoTeamId == passingTeamId;
  }

  bool _isAuthorizedTrucoActor(String actorPlayerId) {
    return authorizedTrucoPlayerIds.contains(actorPlayerId);
  }

  static Set<String> _defaultAuthorizedTrucoPlayerIds(
    List<Player> players,
    String humanPlayerId,
  ) {
    final humanTeamId = players
        .firstWhere(
          (player) => player.id == humanPlayerId,
          orElse: () => players.first,
        )
        .teamId;
    return {
      for (final player in players)
        if (player.id == humanPlayerId || player.teamId != humanTeamId)
          player.id,
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
        '${winner.player.name} gana con ${winner.card}. Equipo ${progress.winningTeamId} gana el reparto y suma $handValue chinos.',
      );
      return;
    }

    status =
        '${winner.player.name} gana con ${winner.card}. Ronda para Equipo $winningTeam. Sale ${winner.player.name}.';
    _log('Ronda para Equipo $winningTeam.');
  }

  void _handleTiedRound(
    RoundResult result,
    int roundNumber,
    HandProgress progress,
  ) {
    if (progress.isNoPoints) {
      _finishHandWithoutPoints(
          'Tercera ronda empatada con 1-1. Nadie suma chino.');
      return;
    }

    if (progress.isFinished && progress.winningTeamId != null) {
      _finishHandForTeam(
        progress.winningTeamId!,
        'Gana el reparto el Equipo ${progress.winningTeamId} por la primera ronda. Suma $handValue chinos.',
      );
      return;
    }

    turnIndex = leadIndex;
    status = roundNumber == 1
        ? 'Primera ronda empatada. Repite ${currentPlayer.name}.'
        : 'Primera y segunda ronda empatadas. Decide la tercera.';
    _log(status);
  }

  void _finishHandForTeam(int teamId, String message, {int? points}) {
    if (handFinished) return;
    final awardedPoints = points ?? handValue;
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
