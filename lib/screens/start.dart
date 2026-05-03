import 'dart:async';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../api_service.dart';
import '../local_sync_store.dart';
import '../main.dart';
import '../navigation/route_transitions.dart';
import '../widgets/backend_feedback.dart';
import '../widgets/mock_background.dart';
import 'menu.dart';
import 'welcome_back.dart';

const double _kTabletBreakpoint = 700;
const double _kMaxContentWidth = 560.0;

const _kBlinkDuration = Duration(milliseconds: 1800);
const _kIntroDuration = Duration(milliseconds: 1200);
const _kIdleDuration = Duration(milliseconds: 3200);
const _kIntroDelay = Duration(milliseconds: 180);

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final AnimationController _introController;
  late final AnimationController _idleController;
  late final AnimationController _tapController;

  late final Animation<double> _blinkOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _idleTitleScale;
  late final Animation<double> _idleSubtitleScale;

  late final Animation<double> _tapScale;
  late final Animation<double> _tapRipple;

  CurvedAnimation _introInterval(
    double begin,
    double end, {
    Curve curve = Curves.easeOut,
  }) {
    return CurvedAnimation(
      parent: _introController,
      curve: Interval(begin, end, curve: curve),
    );
  }

  Future<void> _playIntro() async {
    _introController
      ..stop()
      ..value = 0;
    await Future.delayed(_kIntroDelay);
    if (mounted) _introController.forward();
  }

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: _kBlinkDuration,
    )..repeat(reverse: true);

    _introController = AnimationController(
      vsync: this,
      duration: _kIntroDuration,
    );

    _idleController = AnimationController(
      vsync: this,
      duration: _kIdleDuration,
    );

    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _blinkOpacity = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );

    _subtitleOpacity = _introInterval(0.8, 1);

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(_introInterval(0.0, 0.65, curve: Curves.easeOutCubic));

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(_introInterval(0.3, 1.0, curve: Curves.easeOutCubic));

    _idleTitleScale = Tween<double>(begin: 1.0, end: 1.014).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _idleSubtitleScale = Tween<double>(begin: 1.0, end: 1.008).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _tapScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.94,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.94,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_tapController);

    _tapRipple = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _playIntro());

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _idleController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _introController.dispose();
    _idleController.dispose();
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_tapController.isAnimating) return;

    await _tapController.forward();

    if (!mounted) return;

    final autoSyncEnabled = await LocalSyncStore.instance
        .isAutoSyncListenerEnabled();

    // Start the background listener only after the device has been bootstrapped
    // or the user explicitly armed auto-sync from the login error flow.
    if (autoSyncEnabled &&
        !stableConnectionListener.hasDetectedStableConnection) {
      unawaited(_waitForStableConnectionAndSync());
    }

    if (ApiService.hasActiveSession) {
      pushFadeReplacement(context, const MenuScreen());
    } else {
      pushFade(context, const WelcomeBackScreen());
    }

    _tapController.reset();
  }

  /// Wait for stable connection and show non-blocking sync prompt
  Future<void> _waitForStableConnectionAndSync() async {
    stableConnectionListener.startListening(
      onStableConnection: () async {
        if (!mounted) return;
        await _syncSilentlyWhenStable();
      },
      triggerImmediatelyIfOnline: false,
    );
  }

  /// Sync in the background after stable connection is detected.
  Future<void> _syncSilentlyWhenStable() async {
    if (!mounted) return;

    final hasPendingWork = await LocalSyncStore.instance.hasPendingSyncWork();
    final needsBootstrap = !await ApiService.isOfflineBootstrapComplete();
    final hasOnlineLogin = await LocalSyncStore.instance.hasOnlineLogin();

    if (!mounted || (!hasPendingWork && !needsBootstrap)) {
      return;
    }

    if (hasOnlineLogin) {
      try {
        if (needsBootstrap) {
          await ApiService.bootstrapOfflineData();
        } else {
          await ApiService.syncPending();
          await ApiService.checkContentVersion();
        }
      } catch (_) {
        // Silent by design for normal online mode.
      }
      return;
    }

    await _runBlockingFirstSyncWithProgress(
      needsBootstrap: needsBootstrap,
      hasPendingWork: hasPendingWork,
    );
  }

  Future<void> _runBlockingFirstSyncWithProgress({
    required bool needsBootstrap,
    required bool hasPendingWork,
  }) async {
    final progress = ValueNotifier<double>(0.0);
    final percent = ValueNotifier<int>(0);
    final status = ValueNotifier<String>('Checking stable connection');
    var closed = false;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: const Color(0xFF101327),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF45D9FF), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ValueListenableBuilder<String>(
                  valueListenable: status,
                  builder: (_, statusText, __) {
                    return ValueListenableBuilder<double>(
                      valueListenable: progress,
                      builder: (_, progressValue, __) {
                        return ValueListenableBuilder<int>(
                          valueListenable: percent,
                          builder: (_, percentValue, __) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Syncing Online',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'SuperCartoon',
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  statusText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'SuperCartoon',
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: progressValue,
                                  minHeight: 8,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$percentValue%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'SuperCartoon',
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ).whenComplete(() => closed = true),
    );

    Future<void> tick(
      double p,
      int pc,
      String text, {
      int delayMs = 900,
    }) async {
      if (!mounted || closed) return;
      progress.value = p.clamp(0.0, 1.0);
      percent.value = pc.clamp(0, 100);
      status.value = text;
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    try {
      await tick(0.10, 10, 'Checking stable connection');
      if (hasPendingWork) {
        await tick(0.35, 35, 'Uploading offline progress');
        await ApiService.syncPending();
      }
      await tick(0.70, 70, 'Downloading server updates');
      if (needsBootstrap) {
        await ApiService.bootstrapOfflineData();
      } else {
        await ApiService.checkContentVersion();
      }
      await tick(0.92, 92, 'Saving Sisa position');
      await tick(1.00, 100, 'Offline-ready setup complete', delayMs: 600);
    } catch (_) {
      rethrow;
    } finally {
      progress.dispose();
      percent.dispose();
      status.dispose();
      if (mounted && !closed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;
    await BackendFeedbackOverlay.showMessage(
      context: context,
      title: 'Ready Offline',
      tone: BackendFeedbackTone.success,
      message:
          'Sync completed. Connect to internet every once in a while so progress and new data stay updated.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _tapController,
        builder: (context, child) {
          return Stack(
            children: [
              Transform.scale(scale: _tapScale.value, child: child),

              // ripple flash
              IgnorePointer(
                child: Opacity(
                  opacity: (1 - _tapRipple.value) * 0.4,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: _tapRipple.value * 1.5,
                        colors: [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: MockBackground(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final isTablet = w >= _kTabletBreakpoint;
              final contentW = isTablet ? _kMaxContentWidth : w;

              return SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentW),
                    child: Column(
                      children: [
                        // LOGO
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: h * 0.02,
                          ),
                          child: Transform.scale(
                            scale: 2.2,
                            child: LogoRow(top: 0, width: contentW),
                          ),
                        ),

                        // TITLE IMAGE
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: h * 0.01,
                          ),
                          child: FadeTransition(
                            opacity: Tween<double>(
                              begin: 0.6,
                              end: 1.0,
                            ).animate(_blinkOpacity),
                            child: SlideTransition(
                              position: _titleSlide,
                              child: ScaleTransition(
                                scale: _idleTitleScale,
                                child: Transform.scale(
                                  scale: 1.1,
                                  child: Image.asset('assets/misc/kow.png'),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // SUBTITLE
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FadeTransition(
                            opacity: _subtitleOpacity,
                            child: SlideTransition(
                              position: _subtitleSlide,
                              child: ScaleTransition(
                                scale: _idleSubtitleScale,
                                child: AutoSizeText(
                                  '"ENHANCING FUNCTIONAL LITERACY THROUGH LOCALLY DEVELOPED INSTRUCTIONAL MATERIALS"',
                                  maxLines: 2,
                                  minFontSize: 10,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'SuperCartoon',
                                    fontSize: isTablet
                                        ? 28.0
                                        : contentW * 0.058,
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFFFFE34D),
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 2,
                                        color: Colors.black,
                                        offset: Offset(1.5, 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // CHARACTERS (SISA + OYO)
                        Expanded(
                          flex: 5,
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: isTablet ? 0.8 : 1.2,
                                  child: Transform.translate(
                                    offset: Offset(-contentW * 0.2, h * 0.05),
                                    child: Image.asset(
                                      'assets/sisa_oyo/oyo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: FractionallySizedBox(
                                  widthFactor: 0.6,
                                  child: Transform.translate(
                                    offset: Offset(contentW * 0.01, h * 0.02),
                                    child: Image.asset(
                                      'assets/sisa_oyo/sisa.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // TAP TEXT
                        Padding(
                          padding: EdgeInsets.only(bottom: h * 0.03),
                          child: FadeTransition(
                            opacity: _blinkOpacity,
                            child: Text(
                              'Tap screen to play',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: isTablet ? 26 : contentW * 0.08,
                                color: Colors.white70,

                                // spacing
                                letterSpacing:
                                    2.0, // ← adjust (1.5–3.0 sweet spot)
                                height: 1.2, // ← vertical spacing
                                // black outline
                                shadows: const [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    color: Colors.black,
                                  ),
                                  Shadow(
                                    offset: Offset(-1, 1),
                                    color: Colors.black,
                                  ),
                                  Shadow(
                                    offset: Offset(1, -1),
                                    color: Colors.black,
                                  ),
                                  Shadow(
                                    offset: Offset(-1, -1),
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
