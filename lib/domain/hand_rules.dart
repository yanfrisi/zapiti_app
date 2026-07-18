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
        roundWins[1] = (roundWins[1]! + 1).clamp(0, 2);
        roundWins[2] = (roundWins[2]! + 1).clamp(0, 2);
      } else {
        final teamId = round.winningTeamId!;
        roundWins[teamId] = (roundWins[teamId]! + 1).clamp(0, 2);
      }

      if (roundWins[1] == 2 && roundWins[2] == 2) {
        isFinished = true;
        isNoPoints = true;
        break;
      }

      winningTeamId = _winnerFrom(roundWins);
      if (winningTeamId != null) {
        isFinished = true;
        break;
      }
    }

    if (!isFinished && rounds.length == 3 && roundWins[1] == roundWins[2]) {
      isFinished = true;
      isNoPoints = true;
    }

    return HandProgress(
      roundWinsByTeam: Map.unmodifiable(roundWins),
      winningTeamId: winningTeamId,
      isFinished: isFinished,
      isNoPoints: isNoPoints,
    );
  }

  static int? _winnerFrom(Map<int, int> roundWins) {
    if (roundWins[1] == 2) return 1;
    if (roundWins[2] == 2) return 2;
    return null;
  }
}
