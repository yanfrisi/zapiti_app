enum BetLevel {
  none(1),
  truco(3),
  six(6),
  nine(9),
  twelve(12),
  fifteen(15),
  ahorrisi(18);

  final int value;

  const BetLevel(this.value);

  static BetLevel fromAcceptedValue(int value) {
    return switch (value) {
      <= 1 => BetLevel.none,
      3 => BetLevel.truco,
      6 => BetLevel.six,
      9 => BetLevel.nine,
      12 => BetLevel.twelve,
      15 => BetLevel.fifteen,
      _ => BetLevel.ahorrisi,
    };
  }

  static BetLevel fromProposedValue(int value) {
    return switch (value) {
      3 => BetLevel.truco,
      6 => BetLevel.six,
      9 => BetLevel.nine,
      12 => BetLevel.twelve,
      15 => BetLevel.fifteen,
      _ => BetLevel.ahorrisi,
    };
  }
}

class BetState {
  final BetLevel acceptedLevel;
  final BetLevel? proposedLevel;
  final int? proposingTeam;
  final int? respondingTeam;
  final int? lastRaisingTeam;
  final bool responsePending;

  const BetState({
    required this.acceptedLevel,
    required this.proposedLevel,
    required this.proposingTeam,
    required this.respondingTeam,
    required this.lastRaisingTeam,
    required this.responsePending,
  });

  Map<String, dynamic> toJson() => {
    'acceptedLevel': acceptedLevel.name,
    if (proposedLevel != null) 'proposedLevel': proposedLevel!.name,
    if (proposingTeam != null) 'proposingTeam': proposingTeam,
    if (respondingTeam != null) 'respondingTeam': respondingTeam,
    if (lastRaisingTeam != null) 'lastRaisingTeam': lastRaisingTeam,
    'responsePending': responsePending,
  };
}
