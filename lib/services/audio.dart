import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  late AudioPlayer _musicPlayer;
  late AudioPlayer _sfxPlayer;

  bool _musicOn = true;
  double _musicVolume = 1.0;
  bool _sfxOn = true;
  double _sfxVolume = 1.0;

  bool get musicOn => _musicOn;
  double get musicVolume => _musicVolume;
  bool get sfxOn => _sfxOn;
  double get sfxVolume => _sfxVolume;

  AudioService._internal() {
    _musicPlayer = AudioPlayer();
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _sfxPlayer = AudioPlayer();
    _sfxPlayer.setReleaseMode(ReleaseMode.release);
  }

  // ── Music ──

  Future<void> playBackgroundMusic() async {
    await _musicPlayer.setVolume(_musicOn ? _musicVolume : 0.0);
    await _musicPlayer.play(AssetSource('sounds/bittown.mp3'));
  }

  Future<void> setMusicOn(bool value) async {
    _musicOn = value;
    // Directly set volume — no need to stop/start, just silence or restore
    await _musicPlayer.setVolume(_musicOn ? _musicVolume : 0.0);
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value;
    // Always apply volume regardless of _musicOn state so slider works live
    await _musicPlayer.setVolume(_musicOn ? _musicVolume : 0.0);
  }

  Future<void> stop() async {
    await _musicPlayer.stop();
  }

  // ── SFX ──

  Future<void> playSfx(String assetPath) async {
    if (!_sfxOn) return;
    await _sfxPlayer.setVolume(_sfxVolume);
    await _sfxPlayer.play(AssetSource(assetPath));
  }

  Future<void> setSfxOn(bool value) async {
    _sfxOn = value;
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value;
  }
}