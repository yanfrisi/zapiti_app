class CharacterAssets {
  const CharacterAssets._();

  static const characterIds = ['p1', 'p2', 'p3', 'p4'];

  static const displayNames = {
    'p1': 'Jugador 1',
    'p2': 'Jugador 2',
    'p3': 'Jugador 3',
    'p4': 'Jugador 4',
  };

  static Map<String, String> assignmentForHuman({
    required String humanPlayerId,
    required List<String> playerIds,
    required String humanCharacterId,
  }) {
    final safeHumanCharacterId = characterIds.contains(humanCharacterId)
        ? humanCharacterId
        : characterIds.first;
    final remainingCharacters = characterIds
        .where((characterId) => characterId != safeHumanCharacterId)
        .toList();
    var nextCharacterIndex = 0;

    return {
      for (final playerId in playerIds)
        playerId: playerId == humanPlayerId
            ? safeHumanCharacterId
            : remainingCharacters[nextCharacterIndex++],
    };
  }

  static const _signalFiles = {
    '4 Bastos': 'signal_4_bastos_raise_eyebrows.png',
    '7 Copas': 'signal_7_copas_wink_right.png',
    '7 Oros': 'signal_7_oros_wink_left.png',
    'As Espadas': 'signal_as_espadas_mouth_right.png',
    'Mala': 'signal_mala_eyes_closed.png',
    'Treses': 'signal_treses_kiss.png',
    'Doses': 'signal_doses_tongue.png',
    'Ases': 'signal_ases_open_mouth.png',
  };

  /// Imagen neutral frontal para el jugador indicado (`p1`, `p2`, `p3`, `p4`).
  static String neutral(String playerId) {
    return 'assets/characters/$playerId/front/neutral.png';
  }

  static String selection(String playerId) {
    return 'assets/characters/$playerId/front/selection.png';
  }

  /// Imagen frontal de seña, o neutral si la seña no está mapeada.
  static String frontForSignal(String playerId, String? signal) {
    final file = signal == null ? null : _signalFiles[signal];
    return file == null
        ? neutral(playerId)
        : 'assets/characters/$playerId/front/$file';
  }

  /// Imagen lateral de apoyo para rivales sentados a izquierda/derecha.
  static String side(String playerId, {required bool left}) {
    return 'assets/characters/$playerId/${left ? 'left' : 'right'}/neutral.png';
  }
}
