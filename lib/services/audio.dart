import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../local_sync_store.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _initialized = false;
  bool _pluginAvailable = true;
  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  Future<void> init() async {
    if (_initialized) return;

    final savedMusicEnabled = await LocalSyncStore.instance.getMusicEnabled();
    final savedSfxEnabled = await LocalSyncStore.instance.getSfxEnabled();
    final savedMusicVolume = await LocalSyncStore.instance.getMusicVolume();
    final savedSfxVolume = await LocalSyncStore.instance.getSfxVolume();

    _musicEnabled = savedMusicEnabled ?? true;
    _sfxEnabled = savedSfxEnabled ?? true;
    _musicVolume = (savedMusicVolume ?? 0.8).clamp(0.0, 1.0);
    _sfxVolume = (savedSfxVolume ?? 0.8).clamp(0.0, 1.0);

    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setSource(AssetSource('sounds/bittown.mp3'));
      await _musicPlayer.setVolume(_musicVolume);
    } on MissingPluginException {
      _pluginAvailable = false;
      debugPrint('Audio plugin is unavailable. Run a full app restart to enable music.');
      return;
    } on PlatformException catch (e) {
      _pluginAvailable = false;
      debugPrint('Audio platform initialization failed: ${e.message ?? e.code}');
      return;
    }

    _initialized = true;
    if (_musicEnabled) {
      await _musicPlayer.resume();
    }
  }

  Future<void> playBackgroundMusic() async {
    if (!_initialized) {
      await init();
      return;
    }
    if (!_pluginAvailable) return;
    if (_musicEnabled) {
      try {
        await _musicPlayer.resume();
      } on MissingPluginException {
        _pluginAvailable = false;
      }
    }
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    await LocalSyncStore.instance.saveMusicEnabled(enabled);
    if (!_pluginAvailable) return;
    if (enabled) {
      await playBackgroundMusic();
    } else {
      try {
        await _musicPlayer.pause();
      } on MissingPluginException {
        _pluginAvailable = false;
      }
    }
  }

  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    await LocalSyncStore.instance.saveMusicVolume(_musicVolume);
    if (!_pluginAvailable) return;
    try {
      await _musicPlayer.setVolume(_musicVolume);
    } on MissingPluginException {
      _pluginAvailable = false;
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    await LocalSyncStore.instance.saveSfxEnabled(enabled);
  }

  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);
    await LocalSyncStore.instance.saveSfxVolume(_sfxVolume);
  }

  Future<void> onAppResumed() async {
    if (!_pluginAvailable) return;
    if (_musicEnabled) {
      try {
        await _musicPlayer.resume();
      } on MissingPluginException {
        _pluginAvailable = false;
      }
    }
  }

  Future<void> onAppPaused() async {
    if (!_pluginAvailable) return;
    try {
      await _musicPlayer.pause();
    } on MissingPluginException {
      _pluginAvailable = false;
    }
  }

  Future<void> stop() async {
    if (!_pluginAvailable) return;
    try {
      await _musicPlayer.stop();
    } on MissingPluginException {
      _pluginAvailable = false;
    }
  }
}