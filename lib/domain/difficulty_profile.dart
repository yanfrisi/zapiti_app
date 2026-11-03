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
  final bool rivalsGiveSignals;
  final int rivalSignalRevealMilliseconds;

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
    required this.rivalsGiveSignals,
    required this.rivalSignalRevealMilliseconds,
  });
}

class DifficultyProfiles {
  const DifficultyProfiles._();

  static const values = {
    1: DifficultyProfile(
      level: 1,
      label: 'Muy fácil',
      summary: 'Bots distraídos, errores claros y trucos precipitados.',
      cardPlay: 'Puede regalar cartas si no va ganando la ronda.',
      trucoPlay: 'Truca con impulsos y acepta apuestas pequeñas.',
      cardMistakeChance: 0.20,
      impulsiveTrucoChance: 0.10,
      bluffChance: 0.06,
      callThresholdModifier: -8,
      readsOpponentSignals: false,
      allowsPerfectCardPlay: false,
      rivalsGiveSignals: true,
      rivalSignalRevealMilliseconds: 360,
    ),
    2: DifficultyProfile(
      level: 2,
      label: 'Fácil',
      summary: 'Juega aceptable, pero todavía se precipita.',
      cardPlay: 'Comete menos errores, sobre todo bajo presión.',
      trucoPlay: 'Truca algo antes de tiempo si ve oportunidad.',
      cardMistakeChance: 0.12,
      impulsiveTrucoChance: 0.06,
      bluffChance: 0.10,
      callThresholdModifier: -4,
      readsOpponentSignals: false,
      allowsPerfectCardPlay: false,
      rivalsGiveSignals: true,
      rivalSignalRevealMilliseconds: 300,
    ),
    3: DifficultyProfile(
      level: 3,
      label: 'Normal',
      summary: 'Equilibrado para probar reglas, señas y ritmo.',
      cardPlay: 'Suele jugar por mesa, pareja y valor de la mano.',
      trucoPlay: 'Truca con información de mesa o fuerza real.',
      cardMistakeChance: 0.09,
      impulsiveTrucoChance: 0,
      bluffChance: 0.07,
      callThresholdModifier: -2,
      readsOpponentSignals: true,
      allowsPerfectCardPlay: false,
      rivalsGiveSignals: true,
      rivalSignalRevealMilliseconds: 240,
    ),
    4: DifficultyProfile(
      level: 4,
      label: 'Difícil',
      summary: 'Lee mejor señas, marcador y valor del reparto.',
      cardPlay: 'Conserva fuertes y protege rondas con más criterio.',
      trucoPlay: 'Es más paciente y sube solo con respaldo.',
      cardMistakeChance: 0.03,
      impulsiveTrucoChance: 0,
      bluffChance: 0.04,
      callThresholdModifier: 8,
      readsOpponentSignals: true,
      allowsPerfectCardPlay: false,
      rivalsGiveSignals: true,
      rivalSignalRevealMilliseconds: 170,
    ),
    5: DifficultyProfile(
      level: 5,
      label: 'Experto',
      summary: 'Sin fallos artificiales y decisiones más finas.',
      cardPlay: 'No se equivoca por dificultad; solo por estrategia.',
      trucoPlay: 'Truca tarde, con cartas, señas o mesa a favor.',
      cardMistakeChance: 0,
      impulsiveTrucoChance: 0,
      bluffChance: 0.015,
      callThresholdModifier: 10,
      readsOpponentSignals: true,
      allowsPerfectCardPlay: true,
      rivalsGiveSignals: false,
      rivalSignalRevealMilliseconds: 0,
    ),
  };

  static DifficultyProfile byLevel(int level) {
    return values[level.clamp(1, 5)]!;
  }
}
