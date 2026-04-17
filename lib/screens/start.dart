// Main landing screen for the app. Shows the title, mascots, and tap-to-play hint.
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../navigation/route_transitions.dart';
import '../widgets/mock_background.dart';
import 'welcome_back.dart';

// ─── Layout constants ────────────────────────────────────────────────────────
const double _kTabletBreakpoint = 700;
const double _kMaxContentWidth  = 560.0;

// ─── Duration constants ───────────────────────────────────────────────────────
const _kBlinkDuration = Duration(milliseconds: 900);
const _kIntroDuration = Duration(milliseconds: 1200);
const _kIdleDuration  = Duration(milliseconds: 3200);
const _kIntroDelay    = Duration(milliseconds: 180);

/// Landing screen that opens the welcome back flow.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  late final AnimationController _blinkController;
  late final AnimationController _introController;
  late final AnimationController _idleController;

  // ── Animations ───────────────────────────────────────────────────────────────
  late final Animation<double>  _blinkOpacity;
  late final Animation<double>  _titleOpacity;
  late final Animation<double>  _subtitleOpacity;
  late final Animation<Offset>  _titleSlide;
  late final Animation<Offset>  _subtitleSlide;
  late final Animation<double>  _idleTitleScale;
  late final Animation<double>  _idleSubtitleScale;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Builds an [Interval]-wrapped [CurvedAnimation] from [_introController].
  CurvedAnimation _introInterval(
    double begin,
    double end, {
    Curve curve = Curves.easeOut,
  }) =>
      CurvedAnimation(
        parent: _introController,
        curve: Interval(begin, end, curve: curve),
      );

  Future<void> _playIntro() async {
    _introController
      ..stop()
      ..value = 0;
    await Future.delayed(_kIntroDelay);
    if (mounted) _introController.forward();
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _setupAnimations();

    WidgetsBinding.instance.addPostFrameCallback((_) => _playIntro());

    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _idleController.repeat(reverse: true);
      }
    });
  }

  void _setupControllers() {
    _blinkController = AnimationController(vsync: this, duration: _kBlinkDuration)
      ..repeat(reverse: true);
    _introController = AnimationController(vsync: this, duration: _kIntroDuration);
    _idleController  = AnimationController(vsync: this, duration: _kIdleDuration);
  }

  void _setupAnimations() {
    _blinkOpacity = CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    );

    _titleOpacity    = _introInterval(0.0, 0.65);
    _subtitleOpacity = _introInterval(0.3, 1.0);

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
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _introController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

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
            final isTablet = w >= _kTabletBreakpoint;
            final contentW = isTablet ? _kMaxContentWidth : w;

            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentW),
                  child: Column(
                    children: [
                      _buildLogoRow(h, contentW),
                      _buildTitle(isTablet, contentW),
                      _buildSubtitle(isTablet, contentW),
                      _buildMascots(isTablet, contentW, h),
                      _buildTapHint(h, isTablet, contentW),
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

  // ── Section builders ──────────────────────────────────────────────────────────

  Widget _buildLogoRow(double h, double contentW) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: h * 0.02),
      child: Transform.scale(
        scale: 2.2,
        child: LogoRow(top: 0, width: contentW),
      ),
    );
  }

  Widget _buildTitle(bool isTablet, double contentW) {
    return Expanded(
      flex: 2,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _titleOpacity,
          child: SlideTransition(
            position: _titleSlide,
            child: ScaleTransition(
              scale: _idleTitleScale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'KARUNUNGAN\nON WHEELS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SuperCartoon',
                    fontSize: isTablet ? 70 : contentW * 0.13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: (isTablet ? 28 : contentW * 0.065) * 0.1,
                    height: 1.2,
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
    );
  }

  Widget _buildSubtitle(bool isTablet, double contentW) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 15,
        bottom: 10,
      ),
      child: FadeTransition(
        opacity: _subtitleOpacity,
        child: SlideTransition(
          position: _subtitleSlide,
          child: ScaleTransition(
            scale: _idleSubtitleScale,
            child: AutoSizeText(
              '"ENHANCING FUNCTIONAL LITERACY THROUGH LOCALLY DEVELOPED INSTRUCTIONAL MATERIALS"',
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize: 12,
              stepGranularity: 0.1,
              style: TextStyle(
                fontFamily: 'SuperCartoon',
                fontSize: isTablet ? 28 : contentW * 0.065,
                letterSpacing: (isTablet ? 28 : contentW * 0.065) * 0.08,
                fontWeight: FontWeight.w800,
                height: 1.1,
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
    );
  }

  Widget _buildMascots(bool isTablet, double contentW, double h) {
    return Expanded(
      flex: 5,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: isTablet ? 0.8 : 1.2,
              child: Transform.translate(
                offset: Offset(-contentW * 0.2, h * 0.05),
                child: Image.asset('assets/sisa_oyo/oyo.png', fit: BoxFit.contain),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: FractionallySizedBox(
              widthFactor: 0.6,
              child: Transform.translate(
                offset: Offset(contentW * 0.01, h * 0.05),
                child: Image.asset('assets/sisa_oyo/sisa.png', fit: BoxFit.contain),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTapHint(double h, bool isTablet, double contentW) {
    return Padding(
      padding: EdgeInsets.only(bottom: h * 0.03),
      child: FadeTransition(
        opacity: _blinkOpacity,
        child: Text(
          'Tap screen to play',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SuperCartoon',
            fontSize: isTablet ? 26 : contentW * 0.08,
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
    );
  }
}