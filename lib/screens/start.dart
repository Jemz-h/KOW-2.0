// Main landing screen for the app. Shows the title, mascots, and tap-to-play hint.
import 'package:flutter/material.dart';

// Navigation helpers and background widget imports
import '../navigation/route_transitions.dart';
import '../widgets/mock_background.dart';
import 'welcome_back.dart';

/// Landing screen that opens the welcome back flow.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  // Breakpoint for tablet layout (in pixels)
  static const double _tabletBreakpoint = 700;
  // Maximum content width for tablets
  static const double _maxContentWidth = 560.0;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  late final AnimationController _blinkController;
  late final Animation<double> _blinkOpacity;

  late final AnimationController _introController;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _subtitleSlide;

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

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _blinkOpacity = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
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
  void dispose() {
    _blinkController.dispose();
    _introController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => pushFade(context, const WelcomeBackScreen()),
      child: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            final isTablet = w >= StartScreen._tabletBreakpoint;
            final contentW =
                isTablet ? StartScreen._maxContentWidth : w;

            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: contentW,
                  ),
                  child: Column(
                    children: [
                      // 🔝 Logos
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: h * 0.02,
                        ),
                        child: LogoRow(width: contentW),
                      ),

                      // 🧠 Title
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: FadeTransition(
                            opacity: _titleOpacity,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: ScaleTransition(
                                scale: _idleTitleScale,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'KARUNUNGAN\nON WHEELS',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize:
                                            isTablet ? 70 : contentW * 0.15,
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
                          ),
                        ),
                      ),

                      // 🦉 Mascots
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
                                  offset: Offset(contentW * 0.01, h * 0.05),
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

                      // 📜 Subtitle
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: h * 0.015,
                        ),
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
                                  fontSize:
                                      isTablet ? 18 : contentW * 0.042,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
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

                      // 👇 Tap hint
                      Padding(
                        padding: EdgeInsets.only(bottom: h * 0.03),
                        child: FadeTransition(
                          opacity: _blinkOpacity,
                          child: Text(
                            'Tap screen to play',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SuperCartoon',
                              fontSize:
                                  isTablet ? 26 : contentW * 0.08,
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
