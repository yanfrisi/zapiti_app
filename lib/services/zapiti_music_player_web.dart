// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

class ZapitiMusicPlayer {
  static const _menuAsset = 'assets/assets/audio/menu_zapiti.mp3';
  static const _tableAsset = 'assets/assets/audio/mesa_de_cartas.mp3';

  html.AudioElement? _audio;
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
    _volume = volume.clamp(0, 1);
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
    _volume = volume.clamp(0, 1);
    final audio = _audio;
    if (audio != null) {
      audio.volume = _volume;
    }
  }

  Future<void> stop() async {
    final audio = _audio;
    if (audio == null) return;
    audio.pause();
  }

  void dispose() {
    _audio?.pause();
    _audio?.src = '';
    _audio = null;
  }

  Future<void> _play(String asset, {required double volume}) async {
    _currentAsset = asset;
    _volume = volume.clamp(0, 1);
    if (!_enabled) return;

    final audio = _audio ??= html.AudioElement()
      ..loop = true
      ..preload = 'auto';

    if (audio.src.isEmpty || !audio.src.endsWith(asset)) {
      audio
        ..pause()
        ..src = asset
        ..currentTime = 0;
    }
    audio
      ..volume = _volume
      ..loop = true;

    try {
      await audio.play();
    } catch (_) {
      // Browsers may block autoplay until the first user gesture. The next
      // menu click or game transition will try again with the same track.
    }
  }
}
