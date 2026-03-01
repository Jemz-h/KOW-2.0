import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../navigation/route_transitions.dart';
import '../widgets/chalk_widgets.dart';
import '../widgets/mock_background.dart';
import 'menu_screen.dart';
import 'welcome_student_screen.dart';

/// Login screen that leads to menu or sign-up flow.
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  // Figma base frame (keep consistent with StartScreen)
  static const double _figmaW = 412;
  static const double _figmaH = 917;

  // Tablet handling
  static const double _maxContentWidth = 560;
  static const double _tabletBreakpoint = 700;

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
  with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _birthdayController = TextEditingController();
  late final AnimationController _introController;
  late final AnimationController _emphasisController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _emphasisController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  Widget _buildIntroAnimated({
    required Widget child,
    required double begin,
    required double end,
    Offset slideBegin = const Offset(0, 0.06),
  }) {
    final curve = CurvedAnimation(
      parent: _introController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: slideBegin,
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }

  void _handleStart(BuildContext context) {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your birthday before continuing.')),
      );
      return;
    }
    pushFade(context, const MenuScreen());
  }

  @override
  void dispose() {
    _emphasisController.dispose();
    _introController.dispose();
    _birthdayController.dispose();
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

            final isTablet = screenW >= WelcomeBackScreen._tabletBreakpoint;
            final contentMaxW =
                isTablet ? WelcomeBackScreen._maxContentWidth : screenW;
            final contentW = math.min(screenW, contentMaxW);

            final scale = math.min(
              contentW / WelcomeBackScreen._figmaW,
              screenH / WelcomeBackScreen._figmaH,
            );

            final designW = WelcomeBackScreen._figmaW * scale;
            final designH = WelcomeBackScreen._figmaH * scale;

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
                      // Logos (group)
                      Positioned(
                        left: sx(20),
                        top: sy(10),
                        width: sx(372),
                        height: sy(110),
                        child: LogoRow(top: 0, width: sx(372)),
                      ),
                      // Planet (Figma shows an extra planet near the lower-left area)
                      Positioned(
                        left: sx(22),
                        top: sy(640),
                        width: sx(300),
                        height: sx(300),
                        child: Image.asset(
                          'assets/images/planets_spc.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Oyo (left)
                      Positioned(
                        left: sx(0),        // move inward more
                        top: sy(100),        // move UP (was 130)
                        width: sx(110),      // slightly bigger
                        height: sy(210),
                        child: Image.asset(
                          'assets/images/oyo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Sisa (right)
                      Positioned(
                        right: sx(0),       // move inward
                        top: sy(100),        // align vertically with Oyo
                        width: sx(110),      // slightly bigger
                        height: sy(210),
                        child: Image.asset(
                          'assets/images/sisa.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Title
                      Positioned(
                        left: 0,
                        right: 0,
                        top: sy(160),
                        height: sy(120),
                        child: _buildIntroAnimated(
                          begin: 0.0,
                          end: 0.45,
                          slideBegin: const Offset(0, 0.08),
                          child: AnimatedBuilder(
                            animation: _emphasisController,
                            builder: (context, child) {
                              final wave = math.sin(
                                _emphasisController.value * 2 * math.pi,
                              );
                              final lift = wave * sy(3);
                              final scale = 1 + (wave * 0.012);

                              return Transform.translate(
                                offset: Offset(0, -lift),
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'WELCOME\nBACK!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'SuperCartoon',
                                    fontSize: sx(60),
                                    fontWeight: FontWeight.w900,
                                    height: 0.95,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 8,
                                        color: Colors.black45,
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

                      // Subtitle
                      Positioned(
                        left: sx(20),
                        right: sx(20),
                        top: sy(300),
                        height: sy(48),
                        child: _buildIntroAnimated(
                          begin: 0.2,
                          end: 0.65,
                          slideBegin: const Offset(0, 0.08),
                          child: AnimatedBuilder(
                            animation: _emphasisController,
                            builder: (context, child) {
                              final wave = math.sin(
                                (_emphasisController.value * 2 * math.pi) +
                                    (math.pi / 2),
                              );
                              final lift = wave * sy(2);
                              final scale = 1 + (wave * 0.008);

                              return Transform.translate(
                                offset: Offset(0, -lift),
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              );
                            },
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'LOGIN TO CONTINUE YOUR ADVENTURE!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'SuperCartoon',
                                    fontSize: sx(20),
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                    color: const Color(0xFFFFE34D),
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black38,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Form fields + buttons
                      Positioned(
                        left: sx(40),
                        top: sy(360),
                        width: sx(332),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ChalkTextField(
                                hintText: 'NICKNAME',
                                icon: Icons.person,
                              ),
                              SizedBox(height: sy(14)),
                              ChalkTextField(
                                hintText: 'BIRTHDAY',
                                prefixIconWidget: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: SvgPicture.asset(
                                    'assets/Icons/KOWICONS/4.svg',
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                keyboardType: TextInputType.datetime,
                                controller: _birthdayController,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: sy(18)),
                              ChalkButton(
                                label: 'START',
                                color: const Color(0xFF5C87E5),
                                textColor: Colors.white,
                                onPressed: () => _handleStart(context),
                              ),
                              SizedBox(height: sy(14)),
                              AnimatedBuilder(
                                animation: _emphasisController,
                                builder: (context, child) {
                                  final wave = math.sin(
                                    _emphasisController.value * 2 * math.pi,
                                  );
                                  final opacity = 0.65 + ((wave + 1) * 0.175);

                                  return Opacity(
                                    opacity: opacity,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  'NO NICKNAME YET? CLICK THE BUTTON BELOW',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'SuperCartoon',
                                    fontSize: sx(15),
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFFFE34D),
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 3,
                                        color: Colors.black38,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: sy(10)),
                              SizedBox(
                                width: sx(240),
                                child: ChalkButton(
                                  label: 'SIGN UP',
                                  color: const Color(0xFFF2F089),
                                  textColor: const Color(0xFF2B2B2B),
                                  onPressed: () => pushFade(
                                    context,
                                    const WelcomeStudentScreen(),
                                  ),
                                ),
                              ),
                            ],
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
