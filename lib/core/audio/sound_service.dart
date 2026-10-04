import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/application/settings_controller.dart';

/// Every sound effect of the game. Files live in `assets/audio/` and are
/// produced by `tool/generate_sounds.dart`.
enum Sfx {
  move,
  capture,
  check,
  promotion,
  gameStart,
  win,
  lose,
  draw,
  illegal,
  place,
  tick,
  curtain,
  reveal;

  String get asset => 'audio/$name.wav';
}

/// What the rest of the app needs from audio and haptics.
abstract interface class SoundService {
  void play(Sfx sfx);
  void haptic({bool strong = false});
  void setMusic({required bool playing});
  Future<void> dispose();
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AudioSoundService(
    soundEnabled: () => ref.read(settingsProvider).sound,
    vibrationEnabled: () => ref.read(settingsProvider).vibration,
  );
  ref.onDispose(service.dispose);
  return service;
});

class AudioSoundService implements SoundService {
  AudioSoundService({
    required this.soundEnabled,
    required this.vibrationEnabled,
  });

  final bool Function() soundEnabled;
  final bool Function() vibrationEnabled;

  static const int _voices = 3;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  AudioPlayer? _music;
  bool _broken = false;

  AudioPlayer? _voice() {
    if (_broken) return null;
    try {
      if (_pool.length < _voices) {
        final player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
        _pool.add(player);
        return player;
      }
      return _pool[_next++ % _voices];
    } catch (_) {
      _broken = true;
      return null;
    }
  }

  @override
  void play(Sfx sfx) {
    if (!soundEnabled()) return;
    final player = _voice();
    if (player == null) return;
    // Audio is a nicety: a failing device must never break the game.
    unawaited(
      player
          .play(AssetSource(sfx.asset), mode: PlayerMode.lowLatency)
          .catchError((Object _) => _broken = true),
    );
  }

  @override
  void haptic({bool strong = false}) {
    if (!vibrationEnabled()) return;
    unawaited(
      (strong ? HapticFeedback.mediumImpact() : HapticFeedback.selectionClick())
          .catchError((Object _) {}),
    );
  }

  @override
  void setMusic({required bool playing}) {
    if (_broken) return;
    try {
      if (playing) {
        final player = _music ??= AudioPlayer();
        unawaited(
          player
              .setReleaseMode(ReleaseMode.loop)
              .then(
                (_) =>
                    player.play(AssetSource('audio/music.wav'), volume: 0.35),
              )
              .catchError((Object _) => _broken = true),
        );
      } else {
        unawaited(_music?.stop().catchError((Object _) {}));
      }
    } catch (_) {
      _broken = true;
    }
  }

  @override
  Future<void> dispose() async {
    for (final player in [..._pool, ?_music]) {
      try {
        await player.dispose();
      } catch (_) {
        // Nothing to release.
      }
    }
    _pool.clear();
    _music = null;
  }
}

/// Silent implementation for tests.
class SilentSoundService implements SoundService {
  final List<Sfx> played = [];

  @override
  void play(Sfx sfx) => played.add(sfx);

  @override
  void haptic({bool strong = false}) {}

  @override
  void setMusic({required bool playing}) {}

  @override
  Future<void> dispose() async {}
}
