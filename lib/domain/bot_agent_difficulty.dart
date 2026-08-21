import 'player.dart';

class BotAgentDifficulty {
  const BotAgentDifficulty._();

  static const normalCompanionDifficulty = 3;

  static int forOfflineBot({
    required Player bot,
    required Player human,
    required Player companion,
    required int selectedDifficulty,
  }) {
    if (bot.id == human.id) return selectedDifficulty.clamp(1, 5);
    if (bot.id == companion.id) return normalCompanionDifficulty;
    return selectedDifficulty.clamp(1, 5);
  }
}
