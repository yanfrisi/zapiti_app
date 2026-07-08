import 'played_card.dart';
import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_rules.dart';

class BotStrategy {
  const BotStrategy._();

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

    final sorted = [...hand]..sort(_compareByStrength);
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

    if (currentWinningTeam == player.teamId) {
      return sorted.first;
    }

    if (teammateHasStrongSignal &&
        playedCards.length <= 1 &&
        currentWinningTeam != player.teamId &&
        !handMustBeSaved) {
      return sorted.first;
    }

    final bestTableStrength = _bestTableStrength(playedCards);
    final winningCards = sorted.where((card) {
      return ZapitiRules.strength(card) > bestTableStrength;
    }).toList();
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

  static int? _currentWinningTeam(List<PlayedCard> playedCards) {
    final bestStrength = _bestTableStrength(playedCards);
    final strongestTeams = {
      for (final playedCard in playedCards)
        if (ZapitiRules.strength(playedCard.card) == bestStrength)
          playedCard.player.teamId,
    };

    return strongestTeams.length == 1 ? strongestTeams.first : null;
  }

  static int _bestTableStrength(List<PlayedCard> playedCards) {
    return playedCards
        .map((playedCard) => ZapitiRules.strength(playedCard.card))
        .reduce((best, current) => current > best ? current : best);
  }

  static int _compareByStrength(SpanishCard a, SpanishCard b) {
    return ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b));
  }
}
