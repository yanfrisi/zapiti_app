class TrucoRules {
  const TrucoRules._();

  static const int firstTrucoValue = 3;
  static const int raiseStep = 3;
  static const int maxTrucoValue = 18;

  /// Devuelve el valor máximo que puede proponer un equipo concreto.
  ///
  /// La escalera oficial no se recorta por marcador: Truco, Seis, Nueve,
  /// Doce, Quince y Ahorrisi.
  static int maxAllowedValueForTeam({
    required int teamScore,
    required int targetScore,
    required int currentAcceptedValue,
  }) {
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
    return maxTrucoValue;
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
}
