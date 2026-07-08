import 'player.dart';

class ZapitiPlayers {
  const ZapitiPlayers._();

  static const human = Player(id: 'p1', name: 'Yo', teamId: 1);
  static const rightRival =
      Player(id: 'p2', name: 'Jugador rival 1', teamId: 2);
  static const companion = Player(id: 'p3', name: 'Compañero', teamId: 1);
  static const leftRival = Player(id: 'p4', name: 'Jugador rival 2', teamId: 2);

  /// Orden antihorario de juego: humano, rival derecha, compañero, rival izq.
  static const tableOrder = [
    human,
    rightRival,
    companion,
    leftRival,
  ];
}
