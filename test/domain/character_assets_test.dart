import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/character_assets.dart';

void main() {
  group('CharacterAssets', () {
    test('asigna el personaje elegido al humano y reparte el resto sin repetir',
        () {
      final assignment = CharacterAssets.assignmentForHuman(
        humanPlayerId: 'human',
        playerIds: const ['human', 'rival1', 'companion', 'rival2'],
        humanCharacterId: 'p3',
      );

      expect(assignment['human'], 'p3');
      expect(assignment.values.toSet(), hasLength(4));
      expect(assignment.values.toSet(), CharacterAssets.characterIds.toSet());
    });

    test('usa un personaje seguro si el guardado ya no existe', () {
      final assignment = CharacterAssets.assignmentForHuman(
        humanPlayerId: 'human',
        playerIds: const ['human', 'rival1', 'companion', 'rival2'],
        humanCharacterId: 'desconocido',
      );

      expect(assignment['human'], CharacterAssets.characterIds.first);
      expect(assignment.values.toSet(), hasLength(4));
    });
  });
}
