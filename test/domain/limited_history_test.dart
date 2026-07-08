import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/domain/limited_history.dart';

void main() {
  group('LimitedHistory', () {
    test('mantiene los elementos mas recientes hasta el limite', () {
      final history = LimitedHistory(limit: 2);

      history
        ..add('uno')
        ..add('dos')
        ..add('tres');

      expect(history.items, ['tres', 'dos']);
    });

    test('clear vacia el historial', () {
      final history = LimitedHistory(limit: 2)..add('uno');

      history.clear();

      expect(history.items, isEmpty);
    });
  });
}
