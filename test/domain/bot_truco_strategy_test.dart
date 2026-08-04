import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/bot_truco_strategy.dart';

void main() {
  group('BotTrucoStrategy', () {
    test('no truca demasiado rapido al salir con fuerza media de equipo', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 3,
        teamScore: 125,
        ownMaxStrength: 90,
        cardsOnTable: 0,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );

      expect(shouldCall, isFalse);
    });

    test('normal no abre truco de salida solo por mano decente', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 3,
        teamScore: 145,
        ownMaxStrength: 90,
        cardsOnTable: 0,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );

      expect(shouldCall, isFalse);
    });

    test(
        'truca antes de salir si va a jugar una carta muy grande y tiene apoyo',
        () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 3,
        teamScore: 145,
        ownMaxStrength: 112,
        handStrength: 0.82,
        cardsOnTable: 0,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );

      expect(shouldCall, isTrue);
    });

    test('truca con menos fuerza cuando ya vio varias cartas en la mesa', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 3,
        teamScore: 134,
        ownMaxStrength: 90,
        cardsOnTable: 2,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );

      expect(shouldCall, isTrue);
    });

    test('puede trucar apoyandose en una seña fuerte del compañero', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 3,
        teamScore: 118,
        ownMaxStrength: 70,
        cardsOnTable: 1,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: true,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );

      expect(shouldCall, isTrue);
    });

    test('frena el truco si vio seña fuerte rival sin ronda ganada', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 4,
        teamScore: 150,
        ownMaxStrength: 97,
        cardsOnTable: 2,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: true,
        isCompanion: false,
        needsPoints: true,
      );

      expect(shouldCall, isFalse);
    });

    test('ni en dificultad baja abre de salida con respaldo flojo', () {
      bool shouldCallAt(int difficulty) {
        return BotTrucoStrategy.shouldCall(
          difficulty: difficulty,
          teamScore: 145,
          ownMaxStrength: 90,
          cardsOnTable: 0,
          teamRoundWins: 0,
          opponentRoundWins: 0,
          teamHasStrongSignal: false,
          opponentHasStrongSignal: false,
          isCompanion: false,
          needsPoints: false,
        );
      }

      expect(shouldCallAt(1), isFalse);
      expect(shouldCallAt(5), isFalse);
    });

    test('experto espera mas informacion si no sale con carta grande', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 5,
        teamScore: 145,
        ownMaxStrength: 90,
        cardsOnTable: 0,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );

      expect(shouldCall, isFalse);
    });

    test('facil no interpreta una senya fuerte rival como freno', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 1,
        teamScore: 150,
        ownMaxStrength: 97,
        cardsOnTable: 2,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: true,
        isCompanion: false,
        needsPoints: true,
      );

      expect(shouldCall, isTrue);
    });

    test('con un chico ganado se apoya en dificultad para cerrar la mano', () {
      bool shouldCallAt(int difficulty) {
        return BotTrucoStrategy.shouldCall(
          difficulty: difficulty,
          teamScore: 92,
          ownMaxStrength: 80,
          cardsOnTable: 1,
          teamRoundWins: 1,
          opponentRoundWins: 0,
          teamHasStrongSignal: false,
          opponentHasStrongSignal: false,
          isCompanion: false,
          needsPoints: false,
        );
      }

      expect(shouldCallAt(1), isTrue);
      expect(shouldCallAt(5), isFalse);
    });

    test('una tirada alta deja pasar el truco aunque la mano sea fuerte', () {
      final lowRoll = BotTrucoStrategy.shouldCallWithRoll(
        difficulty: 3,
        roll: 0.12,
        teamScore: 145,
        ownMaxStrength: 112,
        handStrength: 0.82,
        cardsOnTable: 2,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );
      final highRoll = BotTrucoStrategy.shouldCallWithRoll(
        difficulty: 3,
        roll: 0.48,
        teamScore: 145,
        ownMaxStrength: 112,
        handStrength: 0.82,
        cardsOnTable: 2,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
      );

      expect(lowRoll, isTrue);
      expect(highRoll, isFalse);
    });

    test('experto no abre de salida solo por ir perdiendo si no hay carta grande', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 5,
        teamScore: 168,
        ownMaxStrength: 90,
        handStrength: 0.83,
        cardsOnTable: 0,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: true,
        scoreGap: -8,
      );

      expect(shouldCall, isFalse);
    });

    test('si los rivales ya gastaron fuerza truca mas facil con mesa avanzada', () {
      final shouldCall = BotTrucoStrategy.shouldCall(
        difficulty: 5,
        teamScore: 128,
        ownMaxStrength: 97,
        handStrength: 0.74,
        cardsOnTable: 2,
        teamRoundWins: 0,
        opponentRoundWins: 0,
        teamHasStrongSignal: false,
        opponentHasStrongSignal: false,
        isCompanion: false,
        needsPoints: false,
        opponentsSpentPower: true,
        teamSpentPower: false,
      );

      expect(shouldCall, isTrue);
    });
  });
}
