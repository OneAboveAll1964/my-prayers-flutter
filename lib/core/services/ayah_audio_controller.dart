import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'recitation_service.dart';

class AyahAudioState {
  const AyahAudioState({
    this.surah,
    this.ayah,
    this.reciterId,
    this.loading = false,
    this.playing = false,
    this.error,
  });

  final int? surah;
  final int? ayah;
  final int? reciterId;
  final bool loading;
  final bool playing;
  final String? error;

  bool isFor(int surah, int ayah) =>
      this.surah == surah && this.ayah == ayah;

  AyahAudioState copyWith({
    Object? surah = _sentinel,
    Object? ayah = _sentinel,
    Object? reciterId = _sentinel,
    bool? loading,
    bool? playing,
    Object? error = _sentinel,
  }) {
    return AyahAudioState(
      surah: surah == _sentinel ? this.surah : surah as int?,
      ayah: ayah == _sentinel ? this.ayah : ayah as int?,
      reciterId:
          reciterId == _sentinel ? this.reciterId : reciterId as int?,
      loading: loading ?? this.loading,
      playing: playing ?? this.playing,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class AyahAudioController {
  AyahAudioController._();
  static final AyahAudioController instance = AyahAudioController._();

  final AudioPlayer _player = AudioPlayer();
  final StreamController<AyahAudioState> _controller =
      StreamController<AyahAudioState>.broadcast();
  AyahAudioState _state = const AyahAudioState();
  StreamSubscription<void>? _completeSub;

  bool _queueActive = false;
  int? _queueSurah;
  int? _queueReciter;
  int? _queueEndAyah;

  bool get isQueueActive => _queueActive;
  int? get queueSurah => _queueSurah;

  void _clearQueue() {
    _queueActive = false;
    _queueSurah = null;
    _queueReciter = null;
    _queueEndAyah = null;
  }

  static final AyahAudioController _ensured = (() {
    final c = instance;
    c._completeSub ??= c._player.onPlayerComplete.listen((_) {
      if (c._queueActive &&
          c._state.surah == c._queueSurah &&
          c._state.ayah != null &&
          c._queueEndAyah != null) {
        final next = c._state.ayah! + 1;
        if (next <= c._queueEndAyah!) {
          c.playAyah(
            reciterId: c._queueReciter!,
            surah: c._queueSurah!,
            ayah: next,
          );
          return;
        }
      }
      c._clearQueue();
      c._emit(c._state.copyWith(playing: false));
    });
    WidgetsBinding.instance.addObserver(_AudioLifecycleObserver(c));
    return c;
  })();

  Stream<AyahAudioState> get stream {
    _ensured;
    return _controller.stream;
  }

  AyahAudioState get state {
    _ensured;
    return _state;
  }

  void _emit(AyahAudioState s) {
    _state = s;
    if (!_controller.isClosed) _controller.add(s);
  }

  Future<void> stop() async {
    _ensured;
    _clearQueue();
    try {
      await _player.stop();
    } catch (_) {}
    _emit(_state.copyWith(playing: false));
  }

  Future<void> playSurah({
    required int reciterId,
    required int surah,
    required int startAyah,
    required int endAyah,
  }) async {
    _ensured;
    _queueActive = true;
    _queueSurah = surah;
    _queueReciter = reciterId;
    _queueEndAyah = endAyah;
    await playAyah(reciterId: reciterId, surah: surah, ayah: startAyah);
  }

  Future<void> _onAppBackgrounded() async {
    if (_state.playing || _state.loading || _queueActive) {
      await stop();
    }
  }

  Future<void> playAyah({
    required int reciterId,
    required int surah,
    required int ayah,
  }) async {
    _ensured;
    if (_state.isFor(surah, ayah) &&
        _state.playing &&
        _state.reciterId == reciterId) {
      await stop();
      return;
    }
    _emit(AyahAudioState(
      surah: surah,
      ayah: ayah,
      reciterId: reciterId,
      loading: true,
      playing: false,
    ));
    try {
      var file = await RecitationService.instance.cachedFile(
        reciterId,
        surah,
        ayah,
      );
      file ??= await RecitationService.instance.downloadSingleAyah(
        reciterId,
        surah,
        ayah,
      );
      await _player.stop();
      await _player.play(DeviceFileSource(file.path));
      _emit(_state.copyWith(loading: false, playing: true));
    } catch (e) {
      _emit(AyahAudioState(
        surah: null,
        ayah: null,
        reciterId: null,
        loading: false,
        playing: false,
        error: e.toString(),
      ));
    }
  }
}

class _AudioLifecycleObserver with WidgetsBindingObserver {
  _AudioLifecycleObserver(this._controller);
  final AyahAudioController _controller;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _controller._onAppBackgrounded();
    }
  }
}
