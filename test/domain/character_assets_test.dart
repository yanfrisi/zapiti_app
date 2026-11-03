import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/character_assets.dart';

void main() {
  group('CharacterAssets', () {
    test('usa fallback seguro para ids remotos de multijugador', () {
      expect(
        CharacterAssets.neutral('player_1785685639317000_2073404750'),
        'assets/characters/p1/front/neutral.png',
      );
      expect(
        CharacterAssets.frontForSignal(
          'player_1785685639317000_2073404750',
          'Ases',
        ),
        'assets/characters/p1/front/signal_ases_open_mouth.png',
      );
    });
  });
}
