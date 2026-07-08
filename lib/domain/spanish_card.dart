import 'suit.dart';

class SpanishCard {
  final int value;
  final Suit suit;

  const SpanishCard({
    required this.value,
    required this.suit,
  }) : assert(value == 1 ||
            value >= 2 && value <= 7 ||
            value >= 10 && value <= 12);

  String get rankLabel {
    switch (value) {
      case 1:
        return 'As';
      case 10:
        return 'Sota';
      case 11:
        return 'Caballo';
      case 12:
        return 'Rey';
      default:
        return value.toString();
    }
  }

  @override
  String toString() => '$rankLabel de ${suit.label}';

  @override
  bool operator ==(Object other) {
    return other is SpanishCard && other.value == value && other.suit == suit;
  }

  @override
  int get hashCode => Object.hash(value, suit);
}
