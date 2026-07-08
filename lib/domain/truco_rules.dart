class TrucoRules {
  const TrucoRules._();

  static const int firstTrucoValue = 3;
  static const int raiseStep = 3;

  /// Devuelve el valor máximo que puede proponer un equipo concreto.
  ///
  /// Se usa para impedir que un equipo que ya está demasiado cerca del final
  /// sea quien fuerce una apuesta que le daría la partida directamente.
  static int maxAllowedValueForTeam({
    required int teamScore,
    required int targetScore,
    required int currentAcceptedValue,
  }) {
    final maxValue = targetScore - 1 - teamScore;
    return maxValue < currentAcceptedValue ? currentAcceptedValue : maxValue;
  }

  /// Devuelve el valor máximo al que puede quedar apostado el reparto.
  ///
  /// El truco base siempre debe estar disponible mientras la partida siga
  /// viva. Las subidas quedan capadas para no forzar escalones por encima del
  /// margen restante de cualquiera de los equipos.
  static int maxAllowedValue({
    required int scoreTeamOne,
    required int scoreTeamTwo,
    required int targetScore,
    required int currentAcceptedValue,
  }) {
    final maxForTeamOne = targetScore - 1 - scoreTeamOne;
    final maxForTeamTwo = targetScore - 1 - scoreTeamTwo;
    final maxValue =
        maxForTeamOne < maxForTeamTwo ? maxForTeamOne : maxForTeamTwo;
    final minimumValue = currentAcceptedValue < firstTrucoValue
        ? firstTrucoValue
        : currentAcceptedValue;
    return maxValue < minimumValue ? minimumValue : maxValue;
  }

  /// Lista de subidas disponibles para quien debe responder al truco.
  ///
  /// Si te suben a 3, la primera contra-subida posible es 6. Solo se devuelve
  /// el siguiente escalón inmediato para impedir saltos de nivel.
  static List<int> raiseOptions({
    required int pendingValue,
    required int maxAllowedValue,
  }) {
    final firstRaise = pendingValue + raiseStep;
    if (firstRaise > maxAllowedValue) return const [];
    return [firstRaise];
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
}
