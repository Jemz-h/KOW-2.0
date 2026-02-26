// Main landing screen for the app. Shows the title, mascots, and tap-to-play hint.
import 'package:flutter/material.dart';

// Navigation helpers and background widget imports
import '../navigation/route_transitions.dart';
import '../widgets/mock_background.dart';
import 'welcome_back_screen.dart';

/// Landing screen that opens the welcome back flow.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  // Breakpoint for tablet layout (in pixels)
  static const double _tabletBreakpoint = 700;
  // Maximum content width for tablets (prevents stretching)
  static const double _maxContentWidth = 560.0;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  // Animation controller for blinking tap hint
  late final AnimationController _blinkController;
  // Animation for tap hint opacity
  late final Animation<double> _blinkOpacity;

  // Entrance animation for title/subtitle
  late final AnimationController _introController;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _subtitleSlide;

  // Continuous subtle floating animation so text never appears static
  late final AnimationController _idleController;
  late final Animation<double> _idleTitleScale;
  late final Animation<double> _idleSubtitleScale;

  Future<void> _playIntro() async {
    _introController
      ..stop()
      ..value = 0;

    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _introController.forward();
  }

  @override
  void initState() {
    super.initState();
    // Set up blinking animation for tap hint
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      animationBehavior: AnimationBehavior.preserve,
    )..repeat(reverse: true);
    _blinkOpacity = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      animationBehavior: AnimationBehavior.preserve,
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
      animationBehavior: AnimationBehavior.preserve,
    );

    _idleTitleScale = Tween<double>(begin: 1.0, end: 1.014).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    _idleSubtitleScale = Tween<double>(begin: 1.0, end: 1.008).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.45),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playIntro();
    });

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _idleController.repeat(reverse: true);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    _idleController.stop();
    _playIntro();
  }

  @override
  void dispose() {
    // Clean up animation controller
    _blinkController.dispose();
    _introController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Entire screen is tappable to start the app
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => pushFade(context, const WelcomeBackScreen()), // Go to login
      child: MockBackground(
        backgroundImage: 'assets/images/bg_spc_phone.png',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Responsive layout: cap content width for tablets
            final isTablet = w >= StartScreen._tabletBreakpoint;
            final contentW = isTablet ? StartScreen._maxContentWidth : w;

            // Figma-style scaling helpers
            double sx(double px) => px * (contentW / 412);
            double sy(double px) => px * (h / 917);

            return SafeArea(
              child: Center(
                child: SizedBox(
                  width: contentW,
                  height: h,
                  child: Stack(
                    children: [
                      // Logos (group) - precise placement
                      Positioned(
                        left: sx(20),
                        top: sy(10),
                        width: sx(372),
                        height: sy(110),
                        child: LogoRow(top: 0, width: sx(372)),
                      ),

                      // Main title — fade-in + slide-up entrance
                      Positioned(
                        top: h * 0.14,
                        left: 20,
                        right: 20,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: ScaleTransition(
                              scale: _idleTitleScale,
                              child: Text(
                                'KARUNUNGAN\nON WHEELS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'SuperCartoon',
                                  fontSize: contentW * 0.15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black54,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Subtitle — fade-in + slide-up entrance (slight delay)
                      Positioned(
                        top: h * 0.28,
                        left: 30,
                        right: 30,
                        child: FadeTransition(
                          opacity: _subtitleOpacity,
                          child: SlideTransition(
                            position: _subtitleSlide,
                            child: ScaleTransition(
                              scale: _idleSubtitleScale,
                              child: Text(
                                '“ENHANCING FUNCTIONAL LITERACY THROUGH LOCALLY DEVELOPED INSTRUCTIONAL MATERIALS”',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'SuperCartoon',
                                  fontSize: contentW * 0.045,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  color: const Color(0xFFFFE34D),
                                  shadows: const [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black45,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Owl mascot (Figma-style absolute placement)
                      Positioned(
                        left: sx(-80),
                        top: sy(342),
                        width: sx(460),
                        height: sy(575),
                        child: Image.asset(
                          'assets/images/oyo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Sisa mascot (Figma-style absolute placement)
                      Positioned(
                        left: sx(128),
                        top: sy(508),
                        width: sx(303),
                        height: sy(379),
                        child: Image.asset(
                          'assets/images/sisa.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Flashing tap hint at the bottom
                      Positioned(
                        bottom: h * 0.03,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: FadeTransition(
                            opacity: _blinkOpacity,
                            child: Text(
                              'Tap screen to play',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: contentW * 0.09,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 4,
                                    color: Colors.black45,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
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
    );
  }
}
