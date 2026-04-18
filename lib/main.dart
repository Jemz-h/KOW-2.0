import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

import 'screens/start.dart';

// ─── GLOBAL AUDIO SERVICE ─────────────────────────────
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

// ─── MAIN ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fullscreen setup
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  // Start background music BEFORE app runs
  await AudioService().playBackgroundMusic();

  // Error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('Unhandled platform error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  runZonedGuarded(
    () => runApp(const MyApp()),
    (Object error, StackTrace stack) {
      debugPrint('Unhandled zoned error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

// ─── APP WITH LIFECYCLE CONTROL ──────────────────────
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AudioService().stop();
    } else if (state == AppLifecycleState.resumed) {
      AudioService().playBackgroundMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(useMaterial3: true);

    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SuperCartoon',
        useMaterial3: true,
        textTheme: baseTheme.textTheme.apply(fontFamily: 'SuperCartoon'),
        primaryTextTheme: baseTheme.textTheme.apply(fontFamily: 'SuperCartoon'),
      ),
      home: const StartScreen(),
    );
  }
}