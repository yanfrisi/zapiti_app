import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ZapitiMusicPlayer {
  static const _channel = MethodChannel('zapiti/music');
  static const _menuAsset = 'assets/audio/menu_zapiti.mp3';
  static const _tableAsset = 'assets/audio/mesa_de_cartas.mp3';

  String? _currentAsset;
  bool _enabled = true;
  double _volume = 0.65;

  Future<void> playMenu({required double volume}) {
    return _play(_menuAsset, volume: volume);
  }

  Future<void> playTable({required double volume}) {
    return _play(_tableAsset, volume: volume);
  }

  Future<void> setEnabled(bool enabled, {required double volume}) async {
    _enabled = enabled;
    _volume = volume.clamp(0, 1).toDouble();
    if (!_enabled) {
      await stop();
      return;
    }

    final current = _currentAsset;
    if (current != null) {
      await _play(current, volume: _volume);
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0, 1).toDouble();

    try {
      await _channel.invokeMethod<void>('setVolume', {'volume': _volume});
    } catch (error) {
      // Native audio is unavailable in tests and unsupported desktop shells.
      debugPrint('Zapiti audio setVolume unavailable: $error');
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } catch (error) {
      // Native audio is unavailable in tests and unsupported desktop shells.
      debugPrint('Zapiti audio stop unavailable: $error');
    }
  }

  void dispose() => unawaited(stop());

  Future<void> _play(String asset, {required double volume}) async {
    _currentAsset = asset;
    _volume = volume.clamp(0, 1).toDouble();
    if (!_enabled) return;

    try {
      await _channel.invokeMethod<void>('play', {
        'asset': asset,
        'volume': _volume,
      });
    } catch (error) {
      // Keep gameplay independent from audio availability.
      debugPrint('Zapiti audio play unavailable: $error');
    }
  }
}
