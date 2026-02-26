import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/menu_button.dart';
import '../widgets/mock_background.dart';
import '../widgets/coming_soon_popup.dart';
import '../navigation/route_transitions.dart';
import 'tutorial_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

/// Main menu screen showing the title and primary navigation buttons.
/// The main menu screen for the app, showing the app title, subtitle,
/// and navigation buttons for all major sections.
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

/// State for the main menu screen. Handles entrance and idle animations.
class _MenuScreenState extends State<MenuScreen>
    with TickerProviderStateMixin {
  // Animation controller for the entrance (fade/slide in)
  late final AnimationController _introController;
  // Opacity and slide for title and subtitle
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<Offset> _subtitleSlide;

  // Animation controller for continuous idle floating effect
  late final AnimationController _idleController;
  // Scale animations for subtle floating of title/subtitle
  late final Animation<double> _idleTitleScale;
  late final Animation<double> _idleSubtitleScale;

  // Plays the entrance animation for the title and subtitle
  Future<void> _playIntro() async {
    _introController
      ..stop()
      ..value = 0;

    // Small delay for a more natural entrance
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _introController.forward();
  }

  @override
  void initState() {
    super.initState();
    // Set up entrance animation controller
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      animationBehavior: AnimationBehavior.preserve,
    );

    // Set up idle floating animation controller
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
      animationBehavior: AnimationBehavior.preserve,
    );

    // Subtle scale up/down for floating effect
    _idleTitleScale = Tween<double>(begin: 1.0, end: 1.014).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );
    _idleSubtitleScale = Tween<double>(begin: 1.0, end: 1.008).animate(
      CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
    );

    // Fade and slide in for title
    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );
    _subtitleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // Slide up for title and subtitle
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

    // Play entrance animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playIntro();
    });

    // When entrance animation completes, start idle floating
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
    // The menu screen uses a background, responsive scaling, and animated title/subtitle.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive layout calculations
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;

            final isTablet = screenW >= 700;
            final contentMaxW = isTablet ? 560.0 : screenW;
            final contentW = math.min(screenW, contentMaxW);

            // Scale content to fit phone/tablet
            final scale = math.min(contentW / 412, screenH / 917);
            final designW = 412 * scale;
            final designH = 917 * scale;

            // Helper functions for scaled coordinates
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
                      // App logo row at the top
                      Positioned(
                        left: sx(20), top: sy(20),
                        width: sx(372), height: sy(110),
                        child: LogoRow(top: 0, width: sx(372)),
                      ),
                      // Main title — animated fade-in, slide-up, and idle floating
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

                      // Subtitle — animated fade-in, slide-up, and idle floating (slight delay)
                      Positioned(
                        top: designH * 0.28,
                        left: 30,
                        right: 30,
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
                      // Mascot/character image in the center
                      Positioned(
                        left: sx(80), right: sx(80), top: sy(320), height: sy(280),
                        child: Image.asset('assets/images/sisa.png', fit: BoxFit.contain),
                      ),
                      // Main menu buttons (START, TUTORIAL, SETTINGS, ABOUT)
                      Positioned(
                        left: sx(40), right: sx(40), top: sy(600),
                        child: Column(
                          children: [
                            // START button (currently shows coming soon popup)
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(label: 'START', onTap: () => showComingSoonPopup(context)),
                            ),
                            SizedBox(height: sy(12)),
                            // TUTORIAL button
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(label: 'TUTORIAL', onTap: () => pushFade(context, const TutorialScreen())),
                            ),
                            SizedBox(height: sy(12)),
                            // SETTINGS button
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(label: 'SETTINGS', onTap: () => pushFade(context, const SettingsScreen())),
                            ),
                            SizedBox(height: sy(12)),
                            // ABOUT button
                            SizedBox(
                              height: sy(58),
                              child: MenuButton(label: 'ABOUT', onTap: () => pushFade(context, const AboutScreen())),
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
