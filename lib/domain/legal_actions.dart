import 'player.dart';
import 'spanish_card.dart';
import 'zapiti_game_controller.dart';

enum BetActionType { call, accept, pass }

class BetAction {
  final BetActionType type;
  final int? value;

  const BetAction._(this.type, {this.value});

  const BetAction.call(int value) : this._(BetActionType.call, value: value);
  const BetAction.accept() : this._(BetActionType.accept);
  const BetAction.pass() : this._(BetActionType.pass);

  @override
  bool operator ==(Object other) {
    return other is BetAction && other.type == type && other.value == value;
  }

  @override
  int get hashCode => Object.hash(type, value);
}

abstract interface class LegalActionProvider {
  List<SpanishCard> legalCardsFor(Player player);
  List<BetAction> legalBetActionsFor(Player player);
}

class ControllerLegalActionProvider implements LegalActionProvider {
  final ZapitiGameController controller;

  const ControllerLegalActionProvider(this.controller);

  @override
  List<SpanishCard> legalCardsFor(Player player) {
    if (controller.handFinished ||
        controller.isGameFinished ||
        controller.isRoundAwaitingContinue ||
        controller.alVerState == AlVerState.awaitingDecision ||
        controller.trucoState == TrucoNegotiationState.awaitingResponse ||
        controller.currentPlayer.id != player.id) {
      return const [];
    }
    return List<SpanishCard>.unmodifiable(
      controller.hands[player.id] ?? const <SpanishCard>[],
    );
  }

  @override
  List<BetAction> legalBetActionsFor(Player player) {
    final actions = <BetAction>[];

    final nextValue = controller.nextTrucoValueForPlayer(player);
    if (nextValue != null &&
        controller.canCallTruco(
          player,
          value: nextValue,
          actorPlayerId: player.id,
        )) {
      actions.add(BetAction.call(nextValue));
    }

    if (controller.respondingTrucoTeamId == player.teamId) {
      if (controller.canAcceptTruco(
        teamId: player.teamId,
        actorPlayerId: player.id,
      )) {
        actions.add(const BetAction.accept());
      }
      if (controller.canPassTruco(
        passingTeamId: player.teamId,
        actorPlayerId: player.id,
      )) {
        actions.add(const BetAction.pass());
      }
    }

    return List<BetAction>.unmodifiable(actions);
  }
}
