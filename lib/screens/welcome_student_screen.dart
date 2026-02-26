import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../navigation/route_transitions.dart';
import '../widgets/form_widgets.dart';
import '../widgets/mock_background.dart';
import 'menu_screen.dart';
import 'welcome_back_screen.dart';

/// Student registration form screen.
class WelcomeStudentScreen extends StatefulWidget {
  const WelcomeStudentScreen({super.key});

  // Figma base frame (keep consistent with WelcomeBackScreen)
  static const double _figmaW = 412;
  static const double _figmaH = 917;

  // Tablet handling
  static const double _maxContentWidth = 560;
  static const double _tabletBreakpoint = 700;

  @override
  State<WelcomeStudentScreen> createState() => _WelcomeStudentScreenState();
}

class _WelcomeStudentScreenState extends State<WelcomeStudentScreen> {
  String? _selectedSex;
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;

            final isTablet =
                screenW >= WelcomeStudentScreen._tabletBreakpoint;
            final contentMaxW = isTablet
                ? WelcomeStudentScreen._maxContentWidth
                : screenW;
            final contentW = math.min(screenW, contentMaxW);

            final scale = math.min(
              contentW / WelcomeStudentScreen._figmaW,
              screenH / WelcomeStudentScreen._figmaH,
            );

            double sx(double px) => px * scale;
            double sy(double px) => px * scale;

            return SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: sx(40),
                    vertical: sy(20),
                  ),
                  child: Container(
                    width: sx(332),
                    padding: EdgeInsets.symmetric(
                      horizontal: sx(20),
                      vertical: sy(16),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(sx(16)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Exit button ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Image.asset(
                                'assets/images/exit_btn.png',
                                width: sx(34),
                                height: sx(34),
                                errorBuilder: (_, __, ___) => Container(
                                  width: sx(34),
                                  height: sx(34),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE74C3C),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(Icons.close,
                                      color: Colors.white, size: sx(20)),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // ── Title ──
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'WELCOME\nSTUDENT!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SuperCartoon',
                              fontSize: sx(48),
                              fontWeight: FontWeight.w900,
                              height: 0.95,
                              color: const Color(0xFF2D2D2D),
                            ),
                          ),
                        ),
                        SizedBox(height: sy(6)),

                        // ── Subtitle ──
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'TELL US SOMETHING ABOUT YOU!',
                            style: TextStyle(
                              fontFamily: 'SuperCartoon',
                              fontSize: sx(16),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF606060),
                            ),
                          ),
                        ),
                        SizedBox(height: sy(16)),

                        // ── First Name ──
                        _buildLabel('FIRST NAME', sx),
                        SizedBox(height: sy(4)),
                        const LightField(hintText: 'Example: Sisa'),
                        SizedBox(height: sy(10)),

                        // ── Last Name ──
                        _buildLabel('LAST NAME', sx),
                        SizedBox(height: sy(4)),
                        const LightField(hintText: 'Example: Antido'),
                        SizedBox(height: sy(10)),

                        // ── Nickname ──
                        _buildLabel('NICKNAME', sx),
                        SizedBox(height: sy(4)),
                        const LightField(hintText: 'Example: Sample'),
                        SizedBox(height: sy(10)),

                        // ── Birthday ──
                        _buildLabel('BIRTHDAY', sx),
                        SizedBox(height: sy(4)),
                        const LightField(
                          hintText: '10/22/2004',
                          keyboardType: TextInputType.datetime,
                        ),
                        SizedBox(height: sy(4)),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '*Your birthday will serve as your password.',
                            style: TextStyle(
                              fontSize: sx(10),
                              color: const Color(0xFFE55353),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: sy(10)),

                        // ── Area ──
                        _buildLabel('AREA', sx),
                        SizedBox(height: sy(4)),
                        LightField(
                          hintText: 'Select area',
                          readOnly: true,
                          suffixIcon: Icon(
                            Icons.keyboard_arrow_down,
                            color: const Color(0xFF2D2D2D),
                            size: sx(22),
                          ),
                        ),
                        SizedBox(height: sy(14)),

                        // ── Sex ──
                        Text(
                          'SEX',
                          style: TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: sx(16),
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        SizedBox(height: sy(8)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            SexCard(
                              imagePath: 'assets/images/student_boy.png',
                              label: 'MALE',
                              backgroundColor: const Color(0xFF67D1F2),
                              selected: _selectedSex == 'MALE',
                              onTap: () =>
                                  setState(() => _selectedSex = 'MALE'),
                            ),
                            SexCard(
                              imagePath: 'assets/images/student_girl.png',
                              label: 'FEMALE',
                              backgroundColor: const Color(0xFFF58CE3),
                              selected: _selectedSex == 'FEMALE',
                              onTap: () =>
                                  setState(() => _selectedSex = 'FEMALE'),
                            ),
                          ],
                        ),
                        SizedBox(height: sy(12)),

                        // ── Terms & policy ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: sx(20),
                              height: sx(20),
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged: (v) =>
                                    setState(() => _agreedToTerms = v ?? false),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            SizedBox(width: sx(6)),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: sx(11),
                                    color: const Color(0xFF2D2D2D),
                                    height: 1.3,
                                  ),
                                  children: [
                                    const TextSpan(
                                        text: 'I have agreed on the '),
                                    TextSpan(
                                      text: 'terms and policy',
                                      style: const TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          // TODO: open terms
                                        },
                                    ),
                                    const TextSpan(
                                        text:
                                            ' about data privacy while using this application.'),
                                    const TextSpan(
                                      text: '*',
                                      style: TextStyle(
                                        color: Color(0xFFE55353),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sy(14)),

                        // ── Submit ──
                        SizedBox(
                          width: sx(180),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8CFF9A),
                              foregroundColor: Colors.black,
                              padding:
                                  EdgeInsets.symmetric(vertical: sy(10)),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(sx(24)),
                              ),
                            ),
                            onPressed: () =>
                                pushFade(context, const MenuScreen()),
                            child: Text(
                              'SUBMIT',
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: sx(16),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: sy(10)),

                        // ── Already have account ──
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'ALREADY HAVE AN ACCOUNT? ',
                                style: TextStyle(
                                  fontFamily: 'SuperCartoon',
                                  fontSize: sx(12),
                                  color: const Color(0xFFF6FF79),
                                  fontWeight: FontWeight.w700,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              TextSpan(
                                text: 'CLICK ME!',
                                style: TextStyle(
                                  fontFamily: 'SuperCartoon',
                                  fontSize: sx(12),
                                  color: const Color(0xFF79EBFF),
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => pushFade(
                                      context, const WelcomeBackScreen()),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sy(8)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Reusable field label matching the SuperCartoon style.
  Widget _buildLabel(String text, double Function(double) sx) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'SuperCartoon',
          fontSize: sx(14),
          fontWeight: FontWeight.w800,
          color: const Color(0xFF2D2D2D),
        ),
      ),
    );
  }
}
