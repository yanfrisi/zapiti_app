import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

typedef VersionManifestFetcher = Future<String> Function(Uri uri);
typedef InstalledVersionProvider = Future<String> Function();

enum AppVersionCheckStatus {
  notChecked,
  checking,
  compatible,
  updateRequired,
  unavailable,
}

class AppVersionCheckResult {
  final AppVersionCheckStatus status;
  final String installedVersion;
  final String? latestVersion;
  final String? requiredVersion;
  final String? message;

  const AppVersionCheckResult({
    required this.status,
    this.installedVersion = '',
    this.latestVersion,
    this.requiredVersion,
    this.message,
  });

  static const checking = AppVersionCheckResult(
    status: AppVersionCheckStatus.checking,
  );

  static const notChecked = AppVersionCheckResult(
    status: AppVersionCheckStatus.notChecked,
  );

  bool get multiplayerEnabled => status == AppVersionCheckStatus.compatible;

  String get multiplayerStatusMessage {
    switch (status) {
      case AppVersionCheckStatus.notChecked:
        return '';
      case AppVersionCheckStatus.checking:
        return 'Comprobando versión. El servicio puede tardar unos segundos...';
      case AppVersionCheckStatus.compatible:
        return latestVersion == null
            ? 'Multijugador disponible.'
            : 'Multijugador disponible. Version $installedVersion.';
      case AppVersionCheckStatus.updateRequired:
        final target = requiredVersion ?? latestVersion;
        return message ??
            (target == null
                ? 'Actualiza la app para jugar online.'
                : 'Actualiza a la version $target para jugar online.');
      case AppVersionCheckStatus.unavailable:
        return message ??
            'No se pudo comprobar la version. Multijugador desactivado.';
    }
  }
}

class AppVersionCheckService {
  final Uri? manifestUri;
  final VersionManifestFetcher fetchManifest;
  final InstalledVersionProvider installedVersionProvider;
  final Duration timeout;

  AppVersionCheckService({
    required this.manifestUri,
    VersionManifestFetcher? fetchManifest,
    InstalledVersionProvider? installedVersionProvider,
    this.timeout = const Duration(seconds: 30),
  })  : fetchManifest = fetchManifest ?? _defaultFetchManifest,
        installedVersionProvider =
            installedVersionProvider ?? _defaultInstalledVersionProvider;

  factory AppVersionCheckService.production() {
    const endpoint = String.fromEnvironment(
      'APP_VERSION_MANIFEST_URL',
      defaultValue: 'https://zapiti-server.onrender.com/version.json',
    );
    const timeoutSeconds = int.fromEnvironment(
      'APP_VERSION_CHECK_TIMEOUT_SECONDS',
      defaultValue: 30,
    );
    return AppVersionCheckService(
      manifestUri: endpoint.trim().isEmpty ? null : Uri.parse(endpoint),
      timeout: const Duration(seconds: timeoutSeconds),
    );
  }

  Future<AppVersionCheckResult> check() async {
    if (manifestUri == null) {
      final installedVersion = await installedVersionProvider();
      return AppVersionCheckResult(
        status: AppVersionCheckStatus.compatible,
        installedVersion: installedVersion,
      );
    }

    final installedVersion = await installedVersionProvider();
    final deadline = DateTime.now().add(timeout);
    while (true) {
      try {
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) break;
        final raw = await fetchManifest(manifestUri!).timeout(remaining);
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          return AppVersionCheckResult(
            status: AppVersionCheckStatus.unavailable,
            installedVersion: installedVersion,
          );
        }

        final latestVersion = _readString(decoded['latestVersion']);
        final requiredVersion =
            _readString(decoded['minimumMultiplayerVersion']) ?? latestVersion;
        final message = _readString(decoded['message']);

        if (requiredVersion == null) {
          return AppVersionCheckResult(
            status: AppVersionCheckStatus.unavailable,
            installedVersion: installedVersion,
            message: 'No se ha podido comprobar la versión requerida.',
          );
        }

        final compatible =
            compareAppVersions(installedVersion, requiredVersion) >= 0;
        return AppVersionCheckResult(
          status: compatible
              ? AppVersionCheckStatus.compatible
              : AppVersionCheckStatus.updateRequired,
          installedVersion: installedVersion,
          latestVersion: latestVersion,
          requiredVersion: requiredVersion,
          message: compatible ? null : message,
        );
      } catch (_) {
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) break;
        await Future<void>.delayed(
          remaining < const Duration(seconds: 2)
              ? remaining
              : const Duration(seconds: 2),
        );
      }
    }

    return AppVersionCheckResult(
      status: AppVersionCheckStatus.unavailable,
      installedVersion: installedVersion,
    );
  }

  static Future<String> _defaultFetchManifest(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('No se ha podido comprobar la versión.');
    }
    return response.body;
  }

  static Future<String> _defaultInstalledVersionProvider() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}

int compareAppVersions(String left, String right) {
  final leftParts = _versionParts(left);
  final rightParts = _versionParts(right);
  final length = leftParts.length > rightParts.length
      ? leftParts.length
      : rightParts.length;

  for (var index = 0; index < length; index++) {
    final leftPart = index < leftParts.length ? leftParts[index] : 0;
    final rightPart = index < rightParts.length ? rightParts[index] : 0;
    if (leftPart != rightPart) return leftPart.compareTo(rightPart);
  }
  return 0;
}

List<int> _versionParts(String version) {
  final normalized = version.split('+').first.split('-').first;
  return normalized
      .split('.')
      .map((part) => int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}

String? _readString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
