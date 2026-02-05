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

  @override
  State<WelcomeStudentScreen> createState() => _WelcomeStudentScreenState();
}

class _WelcomeStudentScreenState extends State<WelcomeStudentScreen> {
  String? _selectedSex;

  @override
  Widget build(BuildContext context) {
    return MockBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: w * 0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE74C3C),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'WELCOME STUDENT!',
                        style: TextStyle(
                          fontSize: w * 0.062,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'TELL US SOMETHING ABOUT YOU!',
                        style: TextStyle(
                          fontSize: w * 0.028,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF606060),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const FormLabel(text: 'FIRST NAME'),
                      const LightField(hintText: 'Example: Sisa'),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'LAST NAME'),
                      const LightField(hintText: 'Example: Antido'),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'NICKNAME'),
                      const LightField(hintText: 'Example: Sample'),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'BIRTHDAY'),
                      const LightField(
                        hintText: '10/22/2004',
                        keyboardType: TextInputType.datetime,
                        prefixIcon: Icons.calendar_month,
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '*Your birthday will serve as your password.',
                          style: TextStyle(fontSize: 10, color: Color(0xFFE55353), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const FormLabel(text: 'AREA'),
                      LightField(
                        hintText: 'Select area',
                        readOnly: true,
                        suffixIcon: Icon(Icons.keyboard_arrow_down, color: Color(0xFF2D2D2D)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'SEX',
                        style: TextStyle(
                          fontSize: w * 0.03,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SexCard(
                            imagePath: 'assets/images/student_boy.png',
                            label: 'MALE',
                            backgroundColor: const Color(0xFF67D1F2),
                            selected: _selectedSex == 'MALE',
                            onTap: () => setState(() => _selectedSex = 'MALE'),
                          ),
                          SexCard(
                            imagePath: 'assets/images/student_girl.png',
                            label: 'FEMALE',
                            backgroundColor: const Color(0xFFF58CE3),
                            selected: _selectedSex == 'FEMALE',
                            onTap: () => setState(() => _selectedSex = 'FEMALE'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8CFF9A),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () => pushFade(
                            context,
                            const MenuScreen(),
                          ),
                          child: const Text('SUBMIT'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'ALREADY HAVE AN ACCOUNT? ',
                                style: TextStyle(
                                  fontSize: w * 0.022,
                                  color: const Color(0xFFF6FF79),
                                  fontWeight: FontWeight.w700,
                                  shadows: const [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))],
                                ),
                              ),
                              TextSpan(
                                text: 'CLICK ME!',
                                style: TextStyle(
                                  fontSize: w * 0.022,
                                  color: const Color(0xFF79EBFF),
                                  fontWeight: FontWeight.w800,
                                  decoration: TextDecoration.underline,
                                  shadows: const [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0, 1))],
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => pushFade(context, const WelcomeBackScreen()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
