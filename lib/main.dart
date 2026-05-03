import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api_service.dart';
import 'break_time_coordinator.dart';
import 'local_sync_store.dart';
import 'services/audio.dart';
import 'screens/start.dart';
import 'stable_connection_listener.dart';
import 'widgets/backend_feedback.dart';
import 'widgets/mock_background.dart';

/// Global stable connection listener for resource downloads
final stableConnectionListener = StableConnectionListener(
  stabilityDuration: const Duration(seconds: 12),
);

// ─── MAIN ─────────────────────────────────────────────
void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await ApiService.prepareInstallStateForCurrentBuild();
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
    BreakTimeCoordinator.instance.initialize(_navigatorKey);
    unawaited(_restoreSavedTheme());
    // Keep light connectivity watching for resumed state syncing only
    unawaited(_watchConnectivityLightweight());
  }

  /// Lightweight connectivity watching - only for detecting when app resumes online
  Future<void> _watchConnectivityLightweight() async {
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
    if (!await LocalSyncStore.instance.isAutoSyncListenerEnabled()) {
      _wasOnline = _isOnline(results);
      return;
    }

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
      BreakTimeCoordinator.instance.onPaused();
      AudioService().stop();
    } else if (state == AppLifecycleState.resumed) {
      BreakTimeCoordinator.instance.onResumed();
      AudioService().playBackgroundMusic();
      unawaited(_syncPendingWithFeedback());
    }
  }

  Future<void> _syncPendingWithFeedback({bool showWhenIdle = false}) async {
    if (_showingSyncFeedback) {
      return;
    }

    if (!await LocalSyncStore.instance.isAutoSyncListenerEnabled()) {
      return;
    }

    final serverReachable = await ApiService.canReachServer();
    if (!serverReachable) {
      return;
    }

    final hasPendingWork = await LocalSyncStore.instance.hasPendingSyncWork();
    final needsBootstrap = !await ApiService.isOfflineBootstrapComplete();
    final shouldShowBlockingSync =
        showWhenIdle || hasPendingWork || needsBootstrap;
    final feedbackContext = _navigatorKey.currentContext;
    _showingSyncFeedback = true;
    try {
      if (!hasPendingWork && !needsBootstrap && !showWhenIdle) {
        await ApiService.syncPending();
        return;
      }

      if (shouldShowBlockingSync &&
          feedbackContext != null &&
          feedbackContext.mounted) {
        await BackendFeedbackOverlay.runWithLoading<void>(
          context: feedbackContext,
          title: 'Syncing Online',
          message: 'Please wait while KOW updates offline data.',
          loadingMessages: const [
            'Checking connection stability',
            'Uploading offline progress',
            'Downloading learner updates',
            'Downloading questions and media',
            'Finalizing offline-ready files',
          ],
          task: () async {
            if (needsBootstrap) {
              await ApiService.bootstrapOfflineData();
            } else {
              await ApiService.syncPending();
              await ApiService.checkContentVersion();
            }
          },
        );
        if (feedbackContext.mounted) {
          await BackendFeedbackOverlay.showMessage(
            context: feedbackContext,
            title: 'Ready Offline',
            tone: BackendFeedbackTone.success,
            message:
                'Sync complete. You may continue offline and reconnect later to keep progress updated.',
            barrierDismissible: false,
            showCloseButton: false,
          );
        }
      } else {
        if (needsBootstrap) {
          await ApiService.bootstrapOfflineData();
        } else {
          await ApiService.syncPending();
          await ApiService.checkContentVersion();
        }
      }
    } catch (_) {
      if (feedbackContext != null && feedbackContext.mounted) {
        await BackendFeedbackOverlay.showMessage(
          context: feedbackContext,
          title: 'Sync Paused',
          tone: BackendFeedbackTone.warning,
          message:
              'Sync was interrupted. Keep internet stable and KOW will continue syncing.',
        );
      }
    } finally {
      _showingSyncFeedback = false;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    stableConnectionListener.stopListening();
    BreakTimeCoordinator.instance.dispose();
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
    final autoSyncEnabled = await LocalSyncStore.instance
        .isAutoSyncListenerEnabled();
    if (!autoSyncEnabled) {
      return;
    }

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
            'Downloading learner progress',
            'Saving Sisa position',
            'Downloading questions',
            'Downloading question images',
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
