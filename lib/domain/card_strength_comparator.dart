import 'spanish_card.dart';
import 'zapiti_rules.dart';

class CardStrengthComparator {
  const CardStrengthComparator();

  int compare(SpanishCard a, SpanishCard b) {
    return ZapitiRules.strength(a).compareTo(ZapitiRules.strength(b));
  }
}
