import 'package:flutter/material.dart';

import '../navigation/route_transitions.dart';
import '../widgets/form_widgets.dart';
import '../widgets/mock_background.dart';
import 'menu_screen.dart';

/// Student registration form screen.
class WelcomeStudentScreen extends StatelessWidget {
  const WelcomeStudentScreen({super.key});

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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              width: 26,
                              height: 26,
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
                          fontSize: w * 0.06,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TELL US SOMETHING ABOUT YOU',
                        style: TextStyle(
                          fontSize: w * 0.03,
                          color: const Color(0xFF606060),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const FormLabel(text: 'FIRST NAME'),
                      const LightField(hintText: 'Example: Sisa'),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'LAST NAME'),
                      const LightField(hintText: 'Example: Arboleda'),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'NICKNAME'),
                      const LightField(hintText: 'Example: Sample'),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'BIRTHDAY'),
                      const LightField(hintText: '12/02/2004'),
                      const SizedBox(height: 6),
                      const FormLabel(text: 'AREA'),
                      const LightField(hintText: 'Choose Area'),
                      const SizedBox(height: 8),
                      Text(
                        'SEX',
                        style: TextStyle(
                          fontSize: w * 0.03,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          SexCard(
                            imagePath: 'assets/images/student_boy.png',
                            label: 'MALE',
                          ),
                          SexCard(
                            imagePath: 'assets/images/student_girl.png',
                            label: 'FEMALE',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'I have read the terms and policy about data privacy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: w * 0.022,
                          color: const Color(0xFF8C8C8C),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8FF1A0),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                      Text(
                        'ALREADY HAVE AN ACCOUNT? CLICK ME',
                        style: TextStyle(
                          fontSize: w * 0.022,
                          color: const Color(0xFF5C87E5),
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
