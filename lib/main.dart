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
    _wasOnline = await ApiService.canReachServer(
      timeout: const Duration(seconds: 3),
    );
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((
      results,
    ) {
      unawaited(_handleConnectivityChange(results));
    });
  }

  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    if (!_isOnline(results)) {
      _wasOnline = false;
      return;
    }

    final isReachable = await ApiService.canReachServer(
      timeout: const Duration(seconds: 3),
    );
    final cameBackOnline = !_wasOnline && isReachable;
    _wasOnline = isReachable;
    if (cameBackOnline && mounted) {
      unawaited(_syncPendingWithFeedback(showWhenIdle: true));
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

    final serverReachable = await ApiService.canReachServer();
    if (!serverReachable) {
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

    if (!hasPendingWork && !needsBootstrap && showWhenIdle) {
      await ApiService.checkContentVersion();
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
        hideButtonLabel: needsBootstrap ? null : 'Hide',
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
    } catch (_) {
      if (feedbackContext.mounted) {
        await BackendFeedbackOverlay.showMessage(
          context: feedbackContext,
          title: 'Sync Paused',
          tone: BackendFeedbackTone.warning,
          message:
              'The connection was interrupted. KOW will continue syncing when internet is stable again.',
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

    var showedReady = false;

    while (mounted && !await ApiService.isOfflineBootstrapComplete()) {
      final canReachServer = await ApiService.canReachServer();
      if (!mounted) return;

      if (!canReachServer) {
        await BackendFeedbackOverlay.showChoice(
          context: context,
          title: 'Connect First',
          tone: BackendFeedbackTone.error,
          message:
              'Open WiFi or mobile data, then tap Sync Now. This first sync downloads learners, questions, images, and progress for offline play.',
          primaryLabel: 'Sync Now',
          secondaryLabel: null,
          barrierDismissible: false,
          showCloseButton: false,
        );
        continue;
      }

      try {
        await BackendFeedbackOverlay.runWithLoading<void>(
          context: context,
          title: 'First Sync',
          message: 'Preparing this device for offline play.',
          loadingMessages: const [
            'Connecting to KOW',
            'Downloading learner logins',
            'Downloading questions',
            'Saving image cache',
            'Preparing offline mode',
          ],
          task: ApiService.bootstrapOfflineData,
        );
        showedReady = true;
      } catch (_) {
        if (!mounted) return;
        await BackendFeedbackOverlay.showChoice(
          context: context,
          title: 'Sync Paused',
          tone: BackendFeedbackTone.warning,
          message:
              'The download was interrupted. Reconnect to stable internet and tap Sync Now to continue.',
          primaryLabel: 'Sync Now',
          secondaryLabel: null,
          barrierDismissible: false,
          showCloseButton: false,
        );
      }
    }

    if (!mounted || !showedReady) return;
    await BackendFeedbackOverlay.showMessage(
      context: context,
      title: 'Ready Offline',
      tone: BackendFeedbackTone.success,
      message:
          'This device can now play with saved content and will auto-sync when internet returns.',
    );
  }
}
