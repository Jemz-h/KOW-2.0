import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kow/grade_select/grade.dart';

import '../navigation/route_transitions.dart';
import '../widgets/menu_button.dart';
import '../widgets/mock_background.dart';
import 'about.dart';
import 'settings.dart';
import 'tutorial.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _idleController;

  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _idleTitleScale;
  late final Animation<double> _idleSubtitleScale;

  Future<void> _playIntro() async {
    _introController
      ..stop()
      ..value = 0;
    await Future.delayed(const Duration(milliseconds: 180));
    if (mounted) {
      _introController.forward();
    }
  }

  @override
  void initState() {
    super.initState();
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

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _playIntro());
    _introController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _idleController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;
            final isTablet = screenW >= 700;
            final contentMaxW = isTablet ? 560.0 : screenW;
            final contentW = math.min(screenW, contentMaxW);
            final scale = math.min(contentW / 412, screenH / 917);
            final designW = 412 * scale;
            final designH = 917 * scale;

            double sx(double px) => px * scale;
            double sy(double px) => px * scale;

            return SafeArea(
              child: Center(
                child: SizedBox(
                  width: designW,
                  height: designH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: sx(20),
                        top: sy(20),
                        width: sx(372),
                        height: sy(110),
                        child: LogoRow(top: 0, width: sx(372)),
                      ),
                      Positioned(
                        top: designH * 0.14,
                        left: 20,
                        right: 20,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: ScaleTransition(
                              scale: _idleTitleScale,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'KARUNUNGAN\nON WHEELS',
                                  textAlign: TextAlign.center,
                                  softWrap: false,
                                  maxLines: 2,
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
                      ),
                      Positioned(
                        top: designH * 0.28,
                        left: 10,
                        right: 10,
                        child: FadeTransition(
                          opacity: _subtitleOpacity,
                          child: SlideTransition(
                            position: _subtitleSlide,
                            child: ScaleTransition(
                              scale: _idleSubtitleScale,
                              child: Text(
                                '"ENHANCING FUNCTIONAL LITERACY THROUGH LOCALLY DEVELOPED INSTRUCTIONAL MATERIALS"',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isTablet ? 20 : contentW * 0.046,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
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
                      Positioned(
                        left: sx(80),
                        right: sx(80),
                        top: sy(320),
                        height: sy(280),
                        child: Image.asset('assets/sisa_oyo/sisa.png', fit: BoxFit.contain),
                      ),
                      Positioned(
                        left: sx(40),
                        right: sx(40),
                        top: sy(600),
                        child: Column(
                          children: [
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(
                                label: 'START',
                                onTap: () => pushFade(context, const GradeApp()),
                              ),
                            ),
                            SizedBox(height: sy(12)),
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(
                                label: 'TUTORIAL',
                                onTap: () => pushFade(context, const TutorialScreen()),
                              ),
                            ),
                            SizedBox(height: sy(12)),
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(
                                label: 'SETTINGS',
                                onTap: () => pushFade(context, const SettingsScreen()),
                              ),
                            ),
                            SizedBox(height: sy(12)),
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(
                                label: 'ABOUT',
                                onTap: () => pushFade(context, const AboutScreen()),
                              ),
                            ),
                          ],
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
