class TrucoRules {
  const TrucoRules._();

  static const int firstTrucoValue = 3;
  static const int raiseStep = 3;
  static const int maxTrucoValue = 18;

  /// Devuelve el valor máximo que puede proponer un equipo concreto.
  ///
  /// Cerca de 30, la escalera sigue existiendo pero el equipo que ya está en
  /// 27 o 28 solo puede abrir o participar en Truco base. A 29 ya no puede
  /// iniciar ni continuar apuestas de Truco.
  static int maxAllowedValueForTeam({
    required int teamScore,
    required int targetScore,
    required int currentAcceptedValue,
  }) {
    final pointsToAlVer = maxPointsBeforeTarget(
      teamScore: teamScore,
      targetScore: targetScore,
    );
    if (pointsToAlVer <= 0) {
      return 0;
    }
    if (pointsToAlVer < firstTrucoValue) {
      return firstTrucoValue;
    }
    return maxTrucoValue;
  }

  /// Devuelve el valor máximo al que puede quedar apostado el reparto.
  ///
  /// Ahorrisi es el último nivel oficial de la escalera.
  static int maxAllowedValue({
    required int scoreTeamOne,
    required int scoreTeamTwo,
    required int targetScore,
    required int currentAcceptedValue,
  }) {
    final teamOneMax = maxAllowedValueForTeam(
      teamScore: scoreTeamOne,
      targetScore: targetScore,
      currentAcceptedValue: currentAcceptedValue,
    );
    final teamTwoMax = maxAllowedValueForTeam(
      teamScore: scoreTeamTwo,
      targetScore: targetScore,
      currentAcceptedValue: currentAcceptedValue,
    );
    return teamOneMax > teamTwoMax ? teamOneMax : teamTwoMax;
  }

  /// Lista de subidas disponibles para quien debe responder al truco.
  ///
  /// Si te suben a 3, la primera contra-subida posible es 6. Solo se devuelve
  /// el siguiente escalón inmediato para impedir saltos de nivel.
  static List<int> raiseOptions({
    required int pendingValue,
    required int maxAllowedValue,
  }) {
    final nextValue = pendingValue + raiseStep;
    if (nextValue > maxAllowedValue || nextValue > maxTrucoValue) {
      return const [];
    }
    return [nextValue];
  }

  static int? nextRaiseValue({
    required int currentAcceptedValue,
    required int maxAllowedValue,
  }) {
    final options = raiseOptions(
      pendingValue: currentAcceptedValue,
      maxAllowedValue: maxAllowedValue,
    );
    return options.isEmpty ? null : options.first;
  }

  static bool isOpeningValue(int value) => value == firstTrucoValue;

  static bool isRaiseValue({
    required int currentAcceptedValue,
    required int value,
    required int maxAllowedValue,
  }) {
    return raiseOptions(
      pendingValue: currentAcceptedValue,
      maxAllowedValue: maxAllowedValue,
    ).contains(value);
  }

  /// Puntos que suma el equipo que apostó si el rival pasa.
  ///
  /// Al pasar no se paga la subida pendiente, sino el último valor aceptado.
  static int passPoints({required int currentAcceptedValue}) {
    return currentAcceptedValue;
  }

  /// Máximo que un equipo puede sumar sin llegar todavía al cierre.
  ///
  /// En Zapiti, al acercarse a 30 el Truco solo puede resolverse hasta dejar
  /// al equipo en 29; la definición final pasa por la mano siguiente.
  static int maxPointsBeforeTarget({
    required int teamScore,
    required int targetScore,
  }) {
    return (targetScore - 1 - teamScore).clamp(0, maxTrucoValue);
  }

  /// Puntos efectivos que puede cobrar un equipo por una resolución de Truco.
  ///
  /// El valor nominal de la apuesta puede ser 3 o más, pero a 27/28 solo se
  /// cobran los puntos que dejan al equipo como máximo en 29.
  static int awardedPointsForTeam({
    required int teamScore,
    required int targetScore,
    required int nominalValue,
  }) {
    final maxAllowedPoints = maxPointsBeforeTarget(
      teamScore: teamScore,
      targetScore: targetScore,
    );
    if (maxAllowedPoints <= 0) {
      return 0;
    }
    return nominalValue < maxAllowedPoints ? nominalValue : maxAllowedPoints;
  }
}
