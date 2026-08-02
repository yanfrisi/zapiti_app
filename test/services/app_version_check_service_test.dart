import 'package:flutter_test/flutter_test.dart';
import 'package:zapiti_app/services/app_version_check_service.dart';

void main() {
  group('AppVersionCheckService', () {
    test('usa un timeout largo para permitir arranque frio del servicio', () {
      final service = AppVersionCheckService(
        manifestUri: Uri.parse('https://example.test/version.json'),
      );
      final production = AppVersionCheckService.production();

      expect(service.timeout, const Duration(seconds: 30));
      expect(production.timeout, const Duration(seconds: 30));
    });

    test('compara versiones semanticas sin orden lexicografico', () {
      expect(compareAppVersions('0.10.0', '0.2.0'), greaterThan(0));
      expect(compareAppVersions('1.0.0+4', '1.0.0'), 0);
      expect(compareAppVersions('1.2.0', '1.2.1'), lessThan(0));
    });

    test('permite multijugador cuando la app alcanza la version requerida',
        () async {
      final service = AppVersionCheckService(
        manifestUri: Uri.parse('https://example.test/version.json'),
        installedVersionProvider: () async => '1.2.0',
        fetchManifest: (_) async => '''
{
  "latestVersion": "1.2.0",
  "minimumMultiplayerVersion": "1.1.0"
}
''',
      );

      final result = await service.check();

      expect(result.status, AppVersionCheckStatus.compatible);
      expect(result.multiplayerEnabled, isTrue);
    });

    test('reintenta fallos inmediatos mientras quede timeout', () async {
      var attempts = 0;
      final service = AppVersionCheckService(
        manifestUri: Uri.parse('https://example.test/version.json'),
        timeout: const Duration(seconds: 3),
        installedVersionProvider: () async => '1.2.0',
        fetchManifest: (_) async {
          attempts += 1;
          if (attempts == 1) throw StateError('server waking');
          return '''
{
  "latestVersion": "1.2.0",
  "minimumMultiplayerVersion": "1.2.0"
}
''';
        },
      );

      final result = await service.check();

      expect(attempts, 2);
      expect(result.status, AppVersionCheckStatus.compatible);
    });

    test('bloquea multijugador cuando requiere actualizacion', () async {
      final service = AppVersionCheckService(
        manifestUri: Uri.parse('https://example.test/version.json'),
        installedVersionProvider: () async => '1.1.9',
        fetchManifest: (_) async => '''
{
  "latestVersion": "1.2.0",
  "minimumMultiplayerVersion": "1.2.0",
  "message": "Actualiza Zapiti para jugar online."
}
''',
      );

      final result = await service.check();

      expect(result.status, AppVersionCheckStatus.updateRequired);
      expect(result.multiplayerEnabled, isFalse);
      expect(result.multiplayerStatusMessage,
          'Actualiza Zapiti para jugar online.');
    });

    test('bloquea multijugador si no puede comprobar la version', () async {
      final service = AppVersionCheckService(
        manifestUri: Uri.parse('https://example.test/version.json'),
        timeout: const Duration(milliseconds: 100),
        installedVersionProvider: () async => '1.2.0',
        fetchManifest: (_) async => throw StateError('offline'),
      );

      final result = await service.check();

      expect(result.status, AppVersionCheckStatus.unavailable);
      expect(result.multiplayerEnabled, isFalse);
    });
  });
}
