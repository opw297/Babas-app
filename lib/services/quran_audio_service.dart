import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class QuranAudioService {
  QuranAudioService() {
    _initAudioSession();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        onPlaybackCompleted?.call();
      }
    });
    _player.positionStream.listen((position) {
      onPositionChanged?.call(position);
    });
    _player.durationStream.listen((duration) {
      onDurationChanged?.call(duration);
    });
  }

  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Duration position = Duration.zero;

  Duration? duration;

  int _currentSurahNumber = 1;
  int get currentSurahNumber => _currentSurahNumber;

  int _currentAyahNumber = 1;
  int get currentAyahNumber => _currentAyahNumber;

  String _qariCode = 'abdullah_basfar';
  String _qariName = 'Abdullah Basfar';
  String get qariCode => _qariCode;
  String get qariName => _qariName;

  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  bool _autoPlay = true;
  bool get autoPlay => _autoPlay;

  bool _repeatAyah = false;
  bool get repeatAyah => _repeatAyah;

  bool _repeatSurah = false;
  bool get repeatSurah => _repeatSurah;

  bool _shuffle = false;
  bool get shuffle => _shuffle;

  Future<void> setQari(String code, String name) async {
    _qariCode = code;
    _qariName = name;
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
  }

  Future<void> setAutoPlay(bool value) async {
    _autoPlay = value;
  }

  Future<void> setRepeatAyah(bool value) async {
    _repeatAyah = value;
    if (value) {
      await _player.setLoopMode(LoopMode.one);
    } else if (!_repeatSurah) {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  Future<void> setRepeatSurah(bool value) async {
    _repeatSurah = value;
    if (value) {
      await _player.setLoopMode(LoopMode.off);
    } else if (!_repeatAyah) {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  Future<void> setShuffle(bool value) async {
    _shuffle = value;
  }

  void Function()? onPlaybackCompleted;
  void Function(Duration)? onPositionChanged;
  void Function(Duration?)? onDurationChanged;
  void Function()? onPlaybackStateChanged;

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (_) {}
  }

  Future<void> playAyah({
    required int surahNumber,
    required int ayahNumber,
    required int totalAyahs,
  }) async {
    _currentSurahNumber = surahNumber;
    _currentAyahNumber = ayahNumber;
    _isLoading = true;
    onPlaybackStateChanged?.call();

    final localPath = await _buildLocalAudioPath(surahNumber: surahNumber, ayahNumber: ayahNumber);
    final localFile = File(localPath);
    final audioUrl = localFile.existsSync()
        ? 'file://$localPath'
        : _buildRemoteAudioUrl(surahNumber: surahNumber, ayahNumber: ayahNumber);

    try {
      if (localFile.existsSync()) {
        await _player.setAudioSource(AudioSource.uri(Uri.file(localPath)));
      } else {
        await _player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      }
      await _player.setSpeed(_playbackSpeed);
      if (_repeatAyah) {
        await _player.setLoopMode(LoopMode.one);
      } else if (_repeatSurah) {
        await _player.setLoopMode(LoopMode.off);
      } else {
        await _player.setLoopMode(LoopMode.off);
      }
      await _player.play();
      _isPlaying = true;
      _isLoading = false;
      onPlaybackStateChanged?.call();
    } catch (_) {
      _isLoading = false;
      _isPlaying = false;
      onPlaybackStateChanged?.call();
    }
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
    onPlaybackStateChanged?.call();
  }

  Future<void> resume() async {
    if (_player.processingState == ProcessingState.idle) {
      await playAyah(
        surahNumber: _currentSurahNumber,
        ayahNumber: _currentAyahNumber,
        totalAyahs: 1,
      );
      return;
    }
    await _player.play();
    _isPlaying = true;
    onPlaybackStateChanged?.call();
  }

  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
    position = Duration.zero;
    onPlaybackStateChanged?.call();
  }

  Future<void> seekTo(Duration newPosition) async {
    await _player.seek(newPosition);
    position = newPosition;
  }

  Future<void> nextAyah({required int totalAyahs}) async {
    final nextAyah = _currentAyahNumber + 1;
    if (nextAyah <= totalAyahs) {
      await playAyah(surahNumber: _currentSurahNumber, ayahNumber: nextAyah, totalAyahs: totalAyahs);
    }
  }

  Future<void> previousAyah({required int totalAyahs}) async {
    final previousAyah = _currentAyahNumber - 1;
    if (previousAyah >= 1) {
      await playAyah(surahNumber: _currentSurahNumber, ayahNumber: previousAyah, totalAyahs: totalAyahs);
    }
  }

  Future<void> downloadCurrentAudio() async {
    final localPath = await _buildLocalAudioPath(surahNumber: _currentSurahNumber, ayahNumber: _currentAyahNumber);
    final remoteUrl = _buildRemoteAudioUrl(surahNumber: _currentSurahNumber, ayahNumber: _currentAyahNumber);
    final response = await http.get(Uri.parse(remoteUrl));
    if (response.statusCode == 200) {
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
    }
  }

  Future<void> deleteCurrentAudio() async {
    final localPath = await _buildLocalAudioPath(surahNumber: _currentSurahNumber, ayahNumber: _currentAyahNumber);
    final file = File(localPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> isCurrentAudioAvailableOffline() async {
    final localPath = await _buildLocalAudioPath(surahNumber: _currentSurahNumber, ayahNumber: _currentAyahNumber);
    return File(localPath).existsSync();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }

  Future<String> _buildLocalAudioPath({required int surahNumber, required int ayahNumber}) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/quran_${_qariCode}_${surahNumber.toString().padLeft(3, '0')}_${ayahNumber.toString().padLeft(3, '0')}.mp3';
  }

  String _buildRemoteAudioUrl({required int surahNumber, required int ayahNumber}) {
    final surahPart = surahNumber.toString().padLeft(3, '0');
    final ayahPart = ayahNumber.toString().padLeft(3, '0');
    return 'https://download.quranicaudio.com/quran/$_qariCode/$surahPart$ayahPart.mp3';
  }
}
