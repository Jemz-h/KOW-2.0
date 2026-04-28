import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'local_sync_store.dart';
import 'services/audio.dart';
import 'screens/start.dart';
import 'widgets/backend_feedback.dart';
import 'widgets/mock_background.dart';

// ─── MAIN ─────────────────────────────────────────────
void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      unawaited(ApiService.syncPending());

      // Start background music
      unawaited(AudioService().playBackgroundMusic());

      // Fullscreen setup
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
        ),
      );

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

      runApp(const MyApp());
    },
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
    unawaited(_restoreSavedTheme());
  }

  Future<void> _restoreSavedTheme() async {
    final savedTheme = await LocalSyncStore.instance.getSelectedTheme();
    if (savedTheme == null || savedTheme.trim().isEmpty) {
      return;
    }

    if (!themeBackgrounds.containsKey(savedTheme)) {
      return;
    }

    selectedThemeNotifier.value = savedTheme;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause music when app goes to background, resume when it comes back
    if (state == AppLifecycleState.paused) {
      AudioService().stop();
    } else if (state == AppLifecycleState.resumed) {
      AudioService().playBackgroundMusic();
      unawaited(_syncPendingWithFeedback());
    }
  }

  Future<void> _syncPendingWithFeedback() async {
    final hasPendingWork = await LocalSyncStore.instance.hasPendingSyncWork();
    if (!mounted) return;

    if (!hasPendingWork) {
      await ApiService.syncPending();
      return;
    }

    await BackendFeedbackOverlay.runWithLoading<void>(
      context: context,
      title: 'Syncing Online',
      message: 'Sending saved adventure progress to KOW.',
      loadingMessages: const [
        'Syncing learner profile',
        'Uploading scores',
        'Refreshing questions',
        'Saving progress online',
      ],
      task: ApiService.syncPending,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final Future<bool> _restoreFuture;

  @override
  void initState() {
    super.initState();
    _restoreFuture = ApiService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _restoreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Always land on title first; StartScreen decides where to go on tap.
        return const StartScreen();
      },
    );
  }
}
