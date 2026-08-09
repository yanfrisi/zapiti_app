import 'played_card.dart';
import 'player.dart';
import 'signal_context.dart';
import 'spanish_card.dart';

class BotDecisionContext {
  final int difficulty;
  final Player bot;
  final List<Player> players;
  final List<SpanishCard> hand;
  final Map<String, List<SpanishCard>> hands;
  final List<PlayedCard> playedCards;
  final int teamRoundWins;
  final int opponentRoundWins;
  final bool preserveStrongCards;
  final bool teammateHasStrongSignal;
  final bool opponentHasStrongSignal;
  final bool forceWinIfPossible;
  final bool teammateStillToPlay;
  final bool opponentStillToPlay;
  final SignalContext signalContext;
  final int handVersion;
  final int trickIndex;

  const BotDecisionContext({
    required this.difficulty,
    required this.bot,
    required this.players,
    required this.hand,
    required this.hands,
    required this.playedCards,
    required this.teamRoundWins,
    required this.opponentRoundWins,
    required this.preserveStrongCards,
    required this.teammateHasStrongSignal,
    required this.opponentHasStrongSignal,
    required this.forceWinIfPossible,
    required this.teammateStillToPlay,
    required this.opponentStillToPlay,
    this.signalContext = SignalContext.empty,
    this.handVersion = 0,
    this.trickIndex = 0,
  });
}
