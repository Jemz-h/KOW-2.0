import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kow/grade_select/grade.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../widgets/menu_button.dart';
import '../widgets/mock_background.dart';
import '../navigation/route_transitions.dart';
import 'tutorial.dart';
import 'settings.dart';
import 'about.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _subtitleSlide;

  late final AnimationController _idleController;
  late final Animation<double> _idleTitleScale;
  late final Animation<double> _idleSubtitleScale;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // 🔥 faster
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
      begin: const Offset(0, 0.25), // 🔥 less travel = faster feel
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutCubic,
      ),
    );

    // 🔥 PRELOAD ASSETS (big fix)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('assets/themes/p.space-m2.png'),
        context,
      );
      precacheImage(
        const AssetImage('assets/sisa_oyo/sisa.png'),
        context,
      );

      _introController.forward();
    });

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

            Widget _buildLogoRow() {
              return Positioned(
                top: sx(20),
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.scale(
                    scale: 2.2,
                    child: SizedBox(
                      width: contentW,
                      child: LogoRow(top: 0, width: contentW),
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              child: Center(
                child: SizedBox(
                  width: designW,
                  height: designH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildLogoRow(),

                      // TITLE
                     Positioned(
                      top: sx(20) + (contentW * 0.12),
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Transform.scale(
                          scale: 0.8, // ← adjust this (1.2–1.8 sweet spot)
                          child: Image.asset(
                            'assets/misc/kow.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                      // SUBTITLE
                      Positioned(
                        top: designH * 0.30,
                        left: 10,
                        right: 10,
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
                                style: TextStyle(
                                  fontFamily: 'SuperCartoon',
                                  fontSize: isTablet ? 28 : contentW * 0.065,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFE34D),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // IMAGE
                      Positioned(
                        left: sx(80),
                        right: sx(80),
                        top: sy(320),
                        height: sy(280),
                        child: Image.asset(
                          'assets/sisa_oyo/sisa.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // BUTTONS
                      Positioned(
                        left: sx(40),
                        right: sx(40),
                        top: sy(600),
                        child: Column(
                          children: [
                            _btn('START', () {
                              pushFadeFast(context, const GradeApp());
                            }, sy),

                            SizedBox(height: sy(12)),

                            _btn('TUTORIAL', () {
                              pushFadeFast(context, const TutorialScreen());
                            }, sy),

                            SizedBox(height: sy(12)),

                            _btn('SETTINGS', () {
                              pushFadeFast(context, const SettingsScreen());
                            }, sy),

                            SizedBox(height: sy(12)),

                            _btn('ABOUT', () {
                              pushFadeFast(context, const AboutScreen());
                            }, sy),
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

  Widget _btn(String text, VoidCallback onTap, double Function(double) sy) {
    return SizedBox(
      height: sy(58),
      child: MenuButton(
        label: text,
        onTap: onTap,
        gradientColors: const [
          Color(0xFFCCCCCC),
          Color(0xFF999999),
        ],
        gradientRadius: 2,
      ),
    );
  }
}

/// 🔥 FASTER NAVIGATION (replaces pushFade)
void pushFadeFast(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 180), // 🔥 faster
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    ),
  );
}