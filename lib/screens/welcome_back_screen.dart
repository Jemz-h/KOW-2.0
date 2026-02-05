import 'package:flutter/material.dart';

import '../navigation/route_transitions.dart';
import '../widgets/chalk_widgets.dart';
import '../widgets/mock_background.dart';
import 'menu_screen.dart';
import 'welcome_student_screen.dart';

/// Login screen that leads to menu or sign-up flow.
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return SafeArea(
              child: Stack(
                children: [
                Positioned(
                  top: h * 0.03,
                  left: w * 0.05,
                  child: Text(
                    '2 + 2 =',
                    style: TextStyle(
                      fontSize: w * 0.05,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Positioned(
                  top: h * 0.06,
                  right: w * 0.12,
                  child: Container(
                    width: w * 0.18,
                    height: w * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white38, width: 2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  bottom: h * 0.04,
                  left: w * 0.06,
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: w * 0.08,
                  ),
                ),
                Positioned(
                  bottom: h * 0.04,
                  right: w * 0.06,
                  child: Icon(
                    Icons.info,
                    color: Colors.white70,
                    size: w * 0.06,
                  ),
                ),
                Positioned(
                  top: h * 0.2,
                  left: w * 0.08,
                  child: Image.asset(
                    'assets/images/oyo.png',
                    height: h * 0.22,
                  ),
                ),
                Positioned(
                  top: h * 0.24,
                  right: w * 0.1,
                  child: Image.asset(
                    'assets/images/sisa.png',
                    height: h * 0.18,
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'WELCOME\nBACK!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: w * 0.12,
                                color: Colors.white,
                                height: 0.9,
                                shadows: const [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Colors.black45,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'LOGIN TO CONTINUE\nYOUR ADVENTURE!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: w * 0.04,
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
                            SizedBox(height: h * 0.03),
                            const ChalkTextField(
                              hintText: 'NICKNAME',
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 12),
                            ChalkTextField(
                              hintText: '10/22/2004',
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
                            const SizedBox(height: 16),
                            ChalkButton(
                              label: 'START',
                              color: const Color(0xFF5C87E5),
                              textColor: Colors.white,
                              onPressed: () => _handleStart(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'NO NICKNAME YET? CLICK THE BUTTON BELOW',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: w * 0.03,
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
                            const SizedBox(height: 10),
                            ChalkButton(
                              label: 'SIGN UP',
                              color: const Color(0xFFF2F089),
                              textColor: const Color(0xFF2B2B2B),
                              onPressed: () => pushFade(
                                context,
                                const WelcomeStudentScreen(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
