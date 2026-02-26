import 'dart:math' as math;

import 'package:flutter/material.dart';

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

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthdayController = TextEditingController();

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
    _birthdayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        backgroundAsset: 'assets/images/bg_spc_w:cloud.png',
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

                      // ...removed gray outline oval...
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

                      // Owl (left)
                      Positioned(
                        left: sx(0.1),
                        top: sy(130),
                        width: sx(130),
                        height: sy(190),
                        child: Image.asset(
                          'assets/images/oyo.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Chick (right)
                      Positioned(
                        right: sx(0.5),
                        top: sy(130),
                        width: sx(130),
                        height: sy(190),
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
                        height: sy(130),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'WELCOME\nBACK!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: sx(55),
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

                      // Subtitle
                      Positioned(
                        left: sx(20),
                        right: sx(20),
                        top: sy(300),
                        height: sy(48),
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
                                icon: Icons.cake,
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
                              Text(
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
