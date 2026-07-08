import 'package:flutter/foundation.dart';

class ServerConfig {
  const ServerConfig._();

  static const bool useLocalServer = bool.fromEnvironment('USE_LOCAL_SERVER');

  static const String _productionWebsocketUrl = String.fromEnvironment(
    'SERVER_WS_URL',
    defaultValue: 'wss://zapiti-server.onrender.com',
  );

  static const String _localServerUrlOverride = String.fromEnvironment(
    'LOCAL_SERVER_URL',
    defaultValue: '',
  );

  static String get websocketUrl {
    if (!useLocalServer) {
      return _productionWebsocketUrl;
    }

    if (_localServerUrlOverride.isNotEmpty) {
      return _localServerUrlOverride;
    }

    if (kIsWeb) {
      return 'ws://localhost:8080';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ws://10.0.2.2:8080';
      case TargetPlatform.iOS:
        return 'ws://localhost:8080';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'ws://localhost:8080';
    }
  }
}
