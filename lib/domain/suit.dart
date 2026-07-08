enum Suit {
  bastos,
  copas,
  oros,
  espadas;

  String get label {
    switch (this) {
      case Suit.bastos:
        return 'Bastos';
      case Suit.copas:
        return 'Copas';
      case Suit.oros:
        return 'Oros';
      case Suit.espadas:
        return 'Espadas';
    }
  }
}
