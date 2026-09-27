import 'round_result.dart';

class HandProgress {
  final Map<int, int> roundWinsByTeam;
  final int? winningTeamId;
  final bool isFinished;
  final bool isNoPoints;

  const HandProgress({
    required this.roundWinsByTeam,
    required this.winningTeamId,
    required this.isFinished,
    required this.isNoPoints,
  });

  int roundWinsFor(int teamId) => roundWinsByTeam[teamId] ?? 0;
}

class HandRules {
  const HandRules._();

  static HandProgress resolve(List<RoundResult> rounds) {
    final roundWins = {1: 0, 2: 0};
    int? winningTeamId;
    var isFinished = false;
    var isNoPoints = false;

    for (var i = 0; i < rounds.length; i++) {
      final round = rounds[i];
      if (round.isTie) {
        roundWins[1] = roundWins[1]! + 1;
        roundWins[2] = roundWins[2]! + 1;
      } else {
        final teamId = round.winningTeamId!;
        roundWins[teamId] = roundWins[teamId]! + 1;
      }

      winningTeamId = _resolveWinner(rounds.take(i + 1).toList(growable: false));
      if (winningTeamId != null) {
        isFinished = true;
        break;
      }

      if (i == 2) {
        isFinished = true;
        isNoPoints = true;
        break;
      }
    }

    return HandProgress(
      roundWinsByTeam: Map.unmodifiable(roundWins),
      winningTeamId: winningTeamId,
      isFinished: isFinished,
      isNoPoints: isNoPoints,
    );
  }

  static int? _resolveWinner(List<RoundResult> rounds) {
    if (rounds.isEmpty) return null;

    final first = rounds[0];
    if (rounds.length == 1) {
      return null;
    }

    final second = rounds[1];
    if (first.isTie && !second.isTie) {
      return second.winningTeamId;
    }
    if (!first.isTie && second.isTie) {
      return first.winningTeamId;
    }
    if (!first.isTie &&
        !second.isTie &&
        first.winningTeamId == second.winningTeamId) {
      return first.winningTeamId;
    }
    if (rounds.length < 3) {
      return null;
    }

    final third = rounds[2];
    if (third.isTie && !first.isTie) {
      return first.winningTeamId;
    }

    return third.winningTeamId;
  }
}
