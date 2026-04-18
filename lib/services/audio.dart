import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  late AudioPlayer _player;

  AudioService._internal() {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.loop); // loop forever
  }

  Future<void> playBackgroundMusic() async {
    await _player.play(AssetSource('sounds/bittown.mp3'));
  }

  Future<void> stop() async {
    await _player.stop();
  }
}