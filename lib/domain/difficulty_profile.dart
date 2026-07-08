class DifficultyProfile {
  final int level;
  final String label;
  final String summary;
  final String cardPlay;
  final String trucoPlay;
  final double cardMistakeChance;
  final double impulsiveTrucoChance;
  final double bluffChance;
  final int callThresholdModifier;
  final bool readsOpponentSignals;
  final bool allowsPerfectCardPlay;

  const DifficultyProfile({
    required this.level,
    required this.label,
    required this.summary,
    required this.cardPlay,
    required this.trucoPlay,
    required this.cardMistakeChance,
    required this.impulsiveTrucoChance,
    required this.bluffChance,
    required this.callThresholdModifier,
    required this.readsOpponentSignals,
    required this.allowsPerfectCardPlay,
  });
}

class DifficultyProfiles {
  const DifficultyProfiles._();

  static const values = {
    1: DifficultyProfile(
      level: 1,
      label: 'Muy facil',
      summary: 'Bots distraidos, errores claros y trucos precipitados.',
      cardPlay: 'Puede regalar cartas si no va ganando la ronda.',
      trucoPlay: 'Truca con impulsos y acepta apuestas pequenas.',
      cardMistakeChance: 0.34,
      impulsiveTrucoChance: 0.18,
      bluffChance: 0.06,
      callThresholdModifier: -24,
      readsOpponentSignals: false,
      allowsPerfectCardPlay: false,
    ),
    2: DifficultyProfile(
      level: 2,
      label: 'Facil',
      summary: 'Juega aceptable, pero todavia se precipita.',
      cardPlay: 'Comete menos errores, sobre todo bajo presion.',
      trucoPlay: 'Truca algo antes de tiempo si ve oportunidad.',
      cardMistakeChance: 0.18,
      impulsiveTrucoChance: 0.10,
      bluffChance: 0.10,
      callThresholdModifier: -12,
      readsOpponentSignals: false,
      allowsPerfectCardPlay: false,
    ),
    3: DifficultyProfile(
      level: 3,
      label: 'Normal',
      summary: 'Equilibrado para probar reglas, senas y ritmo.',
      cardPlay: 'Suele jugar por mesa, pareja y valor de la mano.',
      trucoPlay: 'Truca con informacion de mesa o fuerza real.',
      cardMistakeChance: 0.08,
      impulsiveTrucoChance: 0,
      bluffChance: 0.07,
      callThresholdModifier: 0,
      readsOpponentSignals: true,
      allowsPerfectCardPlay: false,
    ),
    4: DifficultyProfile(
      level: 4,
      label: 'Dificil',
      summary: 'Lee mejor senas, marcador y valor del reparto.',
      cardPlay: 'Conserva fuertes y protege rondas con mas criterio.',
      trucoPlay: 'Es mas paciente y sube solo con respaldo.',
      cardMistakeChance: 0.03,
      impulsiveTrucoChance: 0,
      bluffChance: 0.04,
      callThresholdModifier: 8,
      readsOpponentSignals: true,
      allowsPerfectCardPlay: false,
    ),
    5: DifficultyProfile(
      level: 5,
      label: 'Experto',
      summary: 'Sin fallos artificiales y decisiones mas finas.',
      cardPlay: 'No se equivoca por dificultad; solo por estrategia.',
      trucoPlay: 'Truca tarde, con cartas, senas o mesa a favor.',
      cardMistakeChance: 0,
      impulsiveTrucoChance: 0,
      bluffChance: 0.025,
      callThresholdModifier: 14,
      readsOpponentSignals: true,
      allowsPerfectCardPlay: true,
    ),
  };

  static DifficultyProfile byLevel(int level) {
    return values[level.clamp(1, 5)]!;
  }
}
