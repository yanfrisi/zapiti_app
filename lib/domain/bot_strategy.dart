import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'bot_rollout_evaluator.dart';
import 'card_strength_comparator.dart';
import 'zapiti_rules.dart';

class BotStrategy {
  const BotStrategy._();
  static const CardStrengthComparator _strengthComparator =
      CardStrengthComparator();

  static int compareByStrength(SpanishCard a, SpanishCard b) {
    return _strengthComparator.compare(a, b);
  }

  static int strengthOf(SpanishCard card) {
    return ZapitiRules.strength(card);
  }

  /// Elige una carta para un bot según el estado parcial de la ronda.
  ///
  /// La estrategia intenta jugar como pareja:
  /// - tira bajo si su equipo ya gana la ronda;
  /// - gana con la carta mínima posible cuando debe cerrar o salvar la mano;
  /// - empata si no puede superar al rival;
  /// - conserva cartas fuertes si una seña o el contexto lo aconsejan;
  /// - al salir presiona si la mano va cuesta arriba o el reparto pesa.
  static SpanishCard chooseCard({
    required Player player,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    int teamRoundWins = 0,
    int opponentRoundWins = 0,
    bool preserveStrongCards = false,
    bool teammateHasStrongSignal = false,
    bool opponentHasStrongSignal = false,
    bool forceWinIfPossible = false,
    bool teammateStillToPlay = false,
    bool opponentStillToPlay = false,
  }) {
    if (hand.isEmpty) {
      throw ArgumentError('El bot no puede jugar sin cartas.');
    }

    final sorted = [...hand]..sort(_strengthComparator.compare);
    if (playedCards.isEmpty) {
      return _leadCard(
        sorted,
        preserveStrongCards: preserveStrongCards || teammateHasStrongSignal,
        mustPressure: forceWinIfPossible || opponentRoundWins > teamRoundWins,
      );
    }

    final currentWinningTeam = _currentWinningTeam(playedCards);
    final isLastToPlay = playedCards.length == 3;
    final handCanBeClosed = teamRoundWins > 0;
    final handMustBeSaved = opponentRoundWins > 0;
    final mustWinNow = forceWinIfPossible ||
        handCanBeClosed ||
        handMustBeSaved ||
        isLastToPlay;
    final canLeaveVisionToTeammate =
        teammateStillToPlay && !handCanBeClosed && !handMustBeSaved;
    final bestTableStrength = _bestTableStrength(playedCards);
    final winningCards = sorted.where((card) {
      return ZapitiRules.strength(card) > bestTableStrength;
    }).toList();

    if (currentWinningTeam == player.teamId) {
      final tableLooksFragile = bestTableStrength < 80;
      if (opponentStillToPlay &&
          !teammateStillToPlay &&
          winningCards.isNotEmpty &&
          (mustWinNow || tableLooksFragile)) {
        return winningCards.first;
      }
      return sorted.first;
    }

    if (teammateHasStrongSignal &&
        playedCards.length <= 1 &&
        currentWinningTeam != player.teamId &&
        !handMustBeSaved) {
      return sorted.first;
    }

    if (winningCards.isNotEmpty) {
      if (opponentStillToPlay && !teammateStillToPlay) {
        return _protectedWinningCard(winningCards);
      }

      if (canLeaveVisionToTeammate) {
        final cheapWinningCards = winningCards.where((card) {
          return ZapitiRules.strength(card) < 80;
        }).toList();
        return cheapWinningCards.isEmpty
            ? sorted.first
            : cheapWinningCards.first;
      }

      if (mustWinNow) {
        return winningCards.first;
      }

      if (opponentHasStrongSignal && playedCards.length <= 1) {
        final cheapWinningCards = winningCards.where((card) {
          return ZapitiRules.strength(card) < 80;
        }).toList();
        return cheapWinningCards.isEmpty
            ? sorted.first
            : cheapWinningCards.first;
      }
      return winningCards.first;
    }

    if (currentWinningTeam != null && currentWinningTeam != player.teamId) {
      final tyingCards = sorted.where((card) {
        return ZapitiRules.strength(card) == bestTableStrength;
      }).toList();
      if (tyingCards.isNotEmpty) {
        return tyingCards.first;
      }
    }

    return sorted.first;
  }

  /// Elige una carta con evaluacion de futuro para dificultades altas.
  ///
  /// No mira cartas ocultas: puntua cada candidata por resultado probable de la
  /// ronda, riesgo de rivales pendientes y fuerza que conserva para despues.
  static SpanishCard chooseCardWithLookahead({
    required int difficulty,
    required Player player,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    List<Player>? players,
    Map<String, List<SpanishCard>>? hands,
    int teamRoundWins = 0,
    int opponentRoundWins = 0,
    bool preserveStrongCards = false,
    bool teammateHasStrongSignal = false,
    bool opponentHasStrongSignal = false,
    bool forceWinIfPossible = false,
    bool teammateStillToPlay = false,
    bool opponentStillToPlay = false,
    bool allowPerfectInformation = false,
    int rolloutCount = 12,
  }) {
    final baseline = chooseCard(
      player: player,
      hand: hand,
      playedCards: playedCards,
      teamRoundWins: teamRoundWins,
      opponentRoundWins: opponentRoundWins,
      preserveStrongCards: preserveStrongCards,
      teammateHasStrongSignal: teammateHasStrongSignal,
      opponentHasStrongSignal: opponentHasStrongSignal,
      forceWinIfPossible: forceWinIfPossible,
      teammateStillToPlay: teammateStillToPlay,
      opponentStillToPlay: opponentStillToPlay,
    );
    final currentWinningTeam = _currentWinningTeam(playedCards);
    if (currentWinningTeam == player.teamId &&
        playedCards.length == 3) {
      return baseline;
    }

    if (difficulty < 4 || hand.length == 1) return baseline;

    if (difficulty >= 5 && players != null && hands != null) {
      if (allowPerfectInformation) {
        return _chooseCardWithPerfectRoundSearch(
          player: player,
          hand: hand,
          playedCards: playedCards,
          players: players,
          hands: hands,
          baseline: baseline,
          teamRoundWins: teamRoundWins,
          opponentRoundWins: opponentRoundWins,
          forceWinIfPossible: forceWinIfPossible,
        );
      }
      return _chooseCardWithRollouts(
        player: player,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: hands,
        baseline: baseline,
        teamRoundWins: teamRoundWins,
        opponentRoundWins: opponentRoundWins,
        handValueEstimate: forceWinIfPossible ? 4 : 1,
        rolloutCount: rolloutCount,
      );
    }

    final sorted = [...hand]..sort(_strengthComparator.compare);
    final canCloseHand = teamRoundWins > 0;
    final mustSaveHand = opponentRoundWins > 0;
    final mustWinNow = forceWinIfPossible ||
        canCloseHand ||
        mustSaveHand ||
        playedCards.length == 3;
    final lookaheadWeight = difficulty >= 5 ? 1.0 : 0.72;

    SpanishCard best = baseline;
    var bestScore = double.negativeInfinity;
    for (final candidate in sorted) {
      final score = _lookaheadScore(
        player: player,
        candidate: candidate,
        hand: sorted,
        playedCards: playedCards,
        baseline: baseline,
        canCloseHand: canCloseHand,
        mustSaveHand: mustSaveHand,
        mustWinNow: mustWinNow,
        preserveStrongCards: preserveStrongCards || teammateHasStrongSignal,
        teammateHasStrongSignal: teammateHasStrongSignal,
        opponentHasStrongSignal: opponentHasStrongSignal,
        teammateStillToPlay: teammateStillToPlay,
        opponentStillToPlay: opponentStillToPlay,
      );
      final adjustedScore = score * lookaheadWeight +
          (candidate == baseline ? 5 : 0) +
          _cheapTieBreaker(candidate);
      if (adjustedScore > bestScore) {
        bestScore = adjustedScore;
        best = candidate;
      }
    }

    return best;
  }

  static SpanishCard _chooseCardWithRollouts({
    required Player player,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required SpanishCard baseline,
    required int teamRoundWins,
    required int opponentRoundWins,
    required int handValueEstimate,
    required int rolloutCount,
  }) {
    final sorted = [...hand]..sort(_strengthComparator.compare);
    SpanishCard best = baseline;
    var bestScore = double.negativeInfinity;

    for (final candidate in sorted) {
      final rolloutScore = BotRolloutEvaluator.evaluateCard(
        player: player,
        candidate: candidate,
        hand: hand,
        playedCards: playedCards,
        players: players,
        hands: hands,
        teamRoundWins: teamRoundWins,
        opponentRoundWins: opponentRoundWins,
        handValue: handValueEstimate,
        rollouts: rolloutCount,
      );
      final adjustedScore = rolloutScore +
          (candidate == baseline ? 8 : 0) +
          _cheapTieBreaker(candidate);
      if (adjustedScore > bestScore) {
        bestScore = adjustedScore;
        best = candidate;
      }
    }

    return best;
  }

  static SpanishCard _chooseCardWithPerfectRoundSearch({
    required Player player,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required SpanishCard baseline,
    required int teamRoundWins,
    required int opponentRoundWins,
    required bool forceWinIfPossible,
  }) {
    final sorted = [...hand]..sort(_strengthComparator.compare);
    final canCloseHand = teamRoundWins > 0;
    final mustSaveHand = opponentRoundWins > 0;

    SpanishCard best = baseline;
    var bestScore = double.negativeInfinity;
    for (final candidate in sorted) {
      final simulatedHands = _copyHands(hands);
      _removeCard(simulatedHands[player.id], candidate);
      final simulatedCards = [
        ...playedCards,
        PlayedCard(player: player, card: candidate),
      ];
      final score = _searchRoundScore(
        teamId: player.teamId,
        players: players,
        hands: simulatedHands,
        playedCards: simulatedCards,
        canCloseHand: canCloseHand,
        mustSaveHand: mustSaveHand,
        forceWinIfPossible: forceWinIfPossible,
      );
      final adjustedScore = score +
          _futureHandPowerScore(
            teamId: player.teamId,
            players: players,
            hands: simulatedHands,
          ) +
          _cheapTieBreaker(candidate);
      if (adjustedScore > bestScore) {
        bestScore = adjustedScore;
        best = candidate;
      }
    }
    return best;
  }

  static SpanishCard _protectedWinningCard(List<SpanishCard> winningCards) {
    final strongWinningCards = winningCards.where((card) {
      return ZapitiRules.strength(card) >= 80;
    }).toList();
    return strongWinningCards.isEmpty
        ? winningCards.last
        : strongWinningCards.first;
  }

  static SpanishCard _leadCard(
    List<SpanishCard> sorted, {
    required bool preserveStrongCards,
    required bool mustPressure,
  }) {
    if (mustPressure) {
      final strongCards = sorted.where((card) {
        return ZapitiRules.strength(card) >= 80;
      }).toList();
      return strongCards.isEmpty ? sorted.last : strongCards.first;
    }

    if (!preserveStrongCards || sorted.length == 1) {
      return sorted.first;
    }

    final safeCards = sorted.where((card) {
      return ZapitiRules.strength(card) < 90;
    }).toList();
    return safeCards.isEmpty ? sorted.first : safeCards.first;
  }

  static double _lookaheadScore({
    required Player player,
    required SpanishCard candidate,
    required List<SpanishCard> hand,
    required List<PlayedCard> playedCards,
    required SpanishCard baseline,
    required bool canCloseHand,
    required bool mustSaveHand,
    required bool mustWinNow,
    required bool preserveStrongCards,
    required bool teammateHasStrongSignal,
    required bool opponentHasStrongSignal,
    required bool teammateStillToPlay,
    required bool opponentStillToPlay,
  }) {
    final simulated = [
      ...playedCards,
      PlayedCard(player: player, card: candidate),
    ];
    final candidateStrength = ZapitiRules.strength(candidate);
    final winningTeam = _currentWinningTeam(simulated);
    final remaining = hand.where((card) => card != candidate).toList();
    final remainingStrength =
        remaining.map(ZapitiRules.strength).fold<int>(0, (sum, value) {
      return sum + value;
    });
    final topRemainingStrength = remaining.isEmpty
        ? 0
        : remaining.map(ZapitiRules.strength).reduce(
              (best, current) => current > best ? current : best,
            );

    var score = 0.0;
    if (winningTeam == player.teamId) {
      score += canCloseHand ? 230 : 150;
      if (mustSaveHand) score += 55;
    } else if (winningTeam == null) {
      score += mustWinNow ? 8 : 56;
    } else {
      score -= mustWinNow ? 150 : 72;
    }

    if (playedCards.isEmpty) {
      score += _leadPressureScore(candidateStrength, mustWinNow);
    }

    if (opponentStillToPlay && winningTeam == player.teamId) {
      final margin = candidateStrength - _secondBestStrength(simulated);
      score -= _opponentRiskPenalty(
        margin: margin,
        candidateStrength: candidateStrength,
        opponentHasStrongSignal: opponentHasStrongSignal,
      );
    }

    if (teammateStillToPlay && winningTeam != player.teamId && !mustWinNow) {
      score += 36;
    }

    if (teammateHasStrongSignal && !mustWinNow && candidateStrength >= 80) {
      score -= 42;
    }

    final spentStrongCard = candidateStrength >= 80;
    final spentPremiumCard = candidateStrength >= 97;
    if (!mustWinNow) {
      score -= spentStrongCard ? 34 : 0;
      score -= spentPremiumCard ? 36 : 0;
    }
    if (preserveStrongCards && candidateStrength >= 90 && !mustWinNow) {
      score -= 44;
    }

    score += remainingStrength * 0.16;
    score += topRemainingStrength * 0.22;
    score -= candidateStrength * (mustWinNow ? 0.05 : 0.18);
    if (candidate == baseline) score += 4;

    return score;
  }

  static double _searchRoundScore({
    required int teamId,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
    required bool canCloseHand,
    required bool mustSaveHand,
    required bool forceWinIfPossible,
  }) {
    if (playedCards.length >= players.length) {
      return _terminalRoundScore(
        teamId: teamId,
        players: players,
        hands: hands,
        playedCards: playedCards,
        canCloseHand: canCloseHand,
        mustSaveHand: mustSaveHand,
        forceWinIfPossible: forceWinIfPossible,
      );
    }

    final nextPlayer = _nextPlayerToAct(players, playedCards);
    if (nextPlayer == null) {
      return _terminalRoundScore(
        teamId: teamId,
        players: players,
        hands: hands,
        playedCards: playedCards,
        canCloseHand: canCloseHand,
        mustSaveHand: mustSaveHand,
        forceWinIfPossible: forceWinIfPossible,
      );
    }

    final availableCards = [...?hands[nextPlayer.id]]
      ..sort(_strengthComparator.compare);
    if (availableCards.isEmpty) {
      return _terminalRoundScore(
        teamId: teamId,
        players: players,
        hands: hands,
        playedCards: playedCards,
        canCloseHand: canCloseHand,
        mustSaveHand: mustSaveHand,
        forceWinIfPossible: forceWinIfPossible,
      );
    }

    final nextIsAlly = nextPlayer.teamId == teamId;
    var bestScore = nextIsAlly ? double.negativeInfinity : double.infinity;
    for (final candidate in availableCards) {
      final simulatedHands = _copyHands(hands);
      _removeCard(simulatedHands[nextPlayer.id], candidate);
      final score = _searchRoundScore(
        teamId: teamId,
        players: players,
        hands: simulatedHands,
        playedCards: [
          ...playedCards,
          PlayedCard(player: nextPlayer, card: candidate),
        ],
        canCloseHand: canCloseHand,
        mustSaveHand: mustSaveHand,
        forceWinIfPossible: forceWinIfPossible,
      );
      bestScore = nextIsAlly
          ? (score > bestScore ? score : bestScore)
          : (score < bestScore ? score : bestScore);
    }
    return bestScore;
  }

  static double _terminalRoundScore({
    required int teamId,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
    required List<PlayedCard> playedCards,
    required bool canCloseHand,
    required bool mustSaveHand,
    required bool forceWinIfPossible,
  }) {
    final winningTeam = _currentWinningTeam(playedCards);
    var score = 0.0;
    if (winningTeam == teamId) {
      score += 1000;
      if (canCloseHand) score += 360;
      if (mustSaveHand) score += 260;
    } else if (winningTeam == null) {
      score += mustSaveHand || forceWinIfPossible ? -120 : 180;
    } else {
      score -= 1000;
      if (mustSaveHand || forceWinIfPossible) score -= 320;
      if (canCloseHand) score -= 180;
    }
    return score +
        _futureHandPowerScore(
          teamId: teamId,
          players: players,
          hands: hands,
        );
  }

  static Player? _nextPlayerToAct(
    List<Player> players,
    List<PlayedCard> playedCards,
  ) {
    if (players.isEmpty) return null;
    final playedPlayerIds = {
      for (final playedCard in playedCards) playedCard.player.id,
    };
    final lastPlayerId =
        playedCards.isEmpty ? null : playedCards.last.player.id;
    final lastIndex = players.indexWhere((player) => player.id == lastPlayerId);
    for (var offset = 1; offset <= players.length; offset++) {
      final index = (lastIndex + offset) % players.length;
      final player = players[index];
      if (!playedPlayerIds.contains(player.id)) return player;
    }
    return null;
  }

  static Map<String, List<SpanishCard>> _copyHands(
    Map<String, List<SpanishCard>> hands,
  ) {
    return {
      for (final entry in hands.entries) entry.key: [...entry.value],
    };
  }

  static void _removeCard(List<SpanishCard>? hand, SpanishCard card) {
    if (hand == null) return;
    final index = hand.indexOf(card);
    if (index >= 0) hand.removeAt(index);
  }

  static double _futureHandPowerScore({
    required int teamId,
    required List<Player> players,
    required Map<String, List<SpanishCard>> hands,
  }) {
    var score = 0.0;
    for (final player in players) {
      final multiplier = player.teamId == teamId ? 0.22 : -0.12;
      for (final card in hands[player.id] ?? const <SpanishCard>[]) {
        score += ZapitiRules.strength(card) * multiplier;
      }
    }
    return score;
  }

  static double _leadPressureScore(int candidateStrength, bool mustWinNow) {
    if (mustWinNow) {
      if (candidateStrength >= 90) return 52;
      if (candidateStrength >= 80) return 34;
      return -18;
    }
    if (candidateStrength >= 97) return -42;
    if (candidateStrength >= 80) return -24;
    if (candidateStrength >= 40) return 12;
    return 6;
  }

  static double _opponentRiskPenalty({
    required int margin,
    required int candidateStrength,
    required bool opponentHasStrongSignal,
  }) {
    var penalty = switch (margin) {
      <= 0 => 64.0,
      <= 10 => 52.0,
      <= 20 => 36.0,
      <= 40 => 20.0,
      _ => 8.0,
    };
    if (candidateStrength >= 97) penalty *= 0.55;
    if (opponentHasStrongSignal) penalty *= 1.35;
    return penalty;
  }

  static int _secondBestStrength(List<PlayedCard> playedCards) {
    final strengths = playedCards.map((card) {
      return ZapitiRules.strength(card.card);
    }).toList()
      ..sort();
    if (strengths.length < 2) return 0;
    return strengths[strengths.length - 2];
  }

  static double _cheapTieBreaker(SpanishCard card) {
    return -ZapitiRules.strength(card) / 1000;
  }

  static int? _currentWinningTeam(List<PlayedCard> playedCards) {
    if (playedCards.isEmpty) return null;
    final bestStrength = _bestTableStrength(playedCards);
    final strongestTeams = {
      for (final playedCard in playedCards)
        if (ZapitiRules.strength(playedCard.card) == bestStrength)
          playedCard.player.teamId,
    };

    return strongestTeams.length == 1 ? strongestTeams.first : null;
  }

  static int _bestTableStrength(List<PlayedCard> playedCards) {
    if (playedCards.isEmpty) return 0;
    return playedCards
        .map((playedCard) => ZapitiRules.strength(playedCard.card))
        .reduce((best, current) => current > best ? current : best);
  }

}
