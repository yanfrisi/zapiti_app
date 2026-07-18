import 'difficulty_profile.dart';
import 'spanish_card.dart';
import 'zapiti_rules.dart';

class BotAlVerStrategy {
  const BotAlVerStrategy._();

  /// Decide si la IA juega la mano o se va a casa al estar al ver.
  ///
  /// La decisión es determinista para que sea fácil de testear y no dependa
  /// de rebuilds ni de estados efimeros de UI.
  static bool shouldPlay({
    required List<SpanishCard> cards,
    required int difficulty,
    required int teamScore,
    required int opponentScore,
    required int targetScore,
  }) {
    if (cards.isEmpty) return false;

    final profile = DifficultyProfiles.byLevel(difficulty);
    final strengths = cards.map(ZapitiRules.strength).toList()..sort();
    final handScore = _handScoreFromStrengths(strengths);
    final strongestCard = strengths.last;
    final scoreGap = teamScore - opponentScore;

    var threshold = switch (profile.level) {
      1 => 124,
      2 => 114,
      3 => 104,
      4 => 94,
      5 => 86,
      _ => 104,
    };

    if (scoreGap < 0) {
      threshold -= 10;
    } else if (scoreGap >= 6) {
      threshold += 8;
    }

    if (opponentScore >= targetScore - 2) {
      threshold -= 12;
    }
    if (teamScore >= targetScore - 1) {
      threshold += 6;
    }
    if (strongestCard >= 97) {
      threshold -= 6;
    }
    if (profile.level == 1 && scoreGap < 0) {
      threshold -= 4;
    }

    return handScore >= threshold;
  }

  static int _handScoreFromStrengths(List<int> strengths) {
    if (strengths.isEmpty) return 0;

    final sorted = [...strengths]..sort();
    final strongest = sorted.last;
    final second = sorted.length > 1 ? sorted[sorted.length - 2] : 0;
    final third = sorted.length > 2 ? sorted[sorted.length - 3] : 0;
    return strongest + (second ~/ 2) + (third ~/ 3);
  }
}
