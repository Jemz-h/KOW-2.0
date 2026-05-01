import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOnline = false;
  bool _showingSyncFeedback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreSavedTheme());
    unawaited(_watchConnectivity());
  }

  Future<void> _watchConnectivity() async {
    final connectivity = Connectivity();
    _wasOnline = _isOnline(await connectivity.checkConnectivity());
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final isOnline = _isOnline(results);
      final cameBackOnline = !_wasOnline && isOnline;
      _wasOnline = isOnline;
      if (cameBackOnline && mounted) {
        unawaited(_syncPendingWithFeedback(showWhenIdle: true));
      }
    });
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
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

  Future<void> _syncPendingWithFeedback({bool showWhenIdle = false}) async {
    if (_showingSyncFeedback) {
      return;
    }

    final feedbackContext = _navigatorKey.currentContext;
    if (feedbackContext == null) {
      await ApiService.syncPending();
      return;
    }

    final hasPendingWork = await LocalSyncStore.instance.hasPendingSyncWork();
    final needsBootstrap = !await ApiService.isOfflineBootstrapComplete();
    if (!mounted || !feedbackContext.mounted) return;

    if (!hasPendingWork && !needsBootstrap && !showWhenIdle) {
      await ApiService.syncPending();
      return;
    }

    _showingSyncFeedback = true;
    try {
      await BackendFeedbackOverlay.runWithLoading<void>(
        context: feedbackContext,
        title: 'Syncing Online',
        message: 'Updating this device for online and offline play.',
        loadingMessages: const [
          'Uploading local data',
          'Syncing learner progress',
          'Downloading questions',
          'Saving image cache',
        ],
        task: needsBootstrap
            ? ApiService.bootstrapOfflineData
            : () async {
                await ApiService.syncPending();
                await ApiService.checkContentVersion();
              },
      );

      if (needsBootstrap && feedbackContext.mounted) {
        await BackendFeedbackOverlay.showMessage(
          context: feedbackContext,
          title: 'Ready Offline',
          tone: BackendFeedbackTone.success,
          message:
              'This device has the latest question cache and can keep working offline. It will sync again when internet returns.',
        );
      }
    } finally {
      _showingSyncFeedback = false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(useMaterial3: true);

    return MaterialApp(
      // debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
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
  bool _checkedOfflineReadiness = false;

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

        if (!_checkedOfflineReadiness) {
          _checkedOfflineReadiness = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(_checkOfflineReadiness());
            }
          });
        }

        // Always land on title first; StartScreen decides where to go on tap.
        return const StartScreen();
      },
    );
  }

  Future<void> _checkOfflineReadiness() async {
    if (await ApiService.isOfflineBootstrapComplete()) {
      return;
    }

    final isOnline = _isOnline(await Connectivity().checkConnectivity());
    if (!mounted) return;

    final shouldSync = await BackendFeedbackOverlay.showChoice(
      context: context,
      title: 'Sync First',
      tone: isOnline ? BackendFeedbackTone.warning : BackendFeedbackTone.error,
      message: isOnline
          ? 'Download the latest KOW questions and image cache before using this device offline.'
          : 'Connect to internet once so this device can download questions, image cache, and saved learner data from future logins.',
      primaryLabel: 'Sync Now',
      secondaryLabel: 'Later',
      barrierDismissible: true,
    );

    if (shouldSync != true || !mounted) {
      return;
    }

    try {
      await BackendFeedbackOverlay.runWithLoading<void>(
        context: context,
        title: 'First Sync',
        message: 'Preparing this device for offline play.',
        loadingMessages: const [
          'Connecting to KOW',
          'Downloading questions',
          'Saving image cache',
          'Preparing offline mode',
        ],
        task: ApiService.bootstrapOfflineData,
      );

      if (!mounted) return;
      await BackendFeedbackOverlay.showMessage(
        context: context,
        title: 'Ready Offline',
        tone: BackendFeedbackTone.success,
        message:
            'This device can now play with saved content and will auto-sync when internet returns.',
      );
    } catch (_) {
      if (!mounted) return;
      await BackendFeedbackOverlay.showMessage(
        context: context,
        title: 'Sync Needed',
        tone: BackendFeedbackTone.warning,
        message:
            'The first sync did not finish. Connect to stable internet and tap Sync Now again before offline use.',
      );
    }
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }
}
