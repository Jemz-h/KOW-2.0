import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../api_service.dart';
import '../navigation/route_transitions.dart';
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

    if (ApiService.hasActiveSession) {
      pushFadeReplacement(context, const MenuScreen());
    } else {
      pushFade(context, const WelcomeBackScreen());
    }

    _tapController.reset();
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
