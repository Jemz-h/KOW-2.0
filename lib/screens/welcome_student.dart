import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../api_service.dart';
import '../navigation/route_transitions.dart';
import '../widgets/form.dart';
import '../widgets/mock_background.dart';
import 'menu.dart';
import 'welcome_back.dart';

/// Student registration form screen.
class WelcomeStudentScreen extends StatefulWidget {
  const WelcomeStudentScreen({super.key});

  @override
  State<WelcomeStudentScreen> createState() => _WelcomeStudentScreenState();
}

class _WelcomeStudentScreenState extends State<WelcomeStudentScreen> {
  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _nicknameCtrl   = TextEditingController();
  final _birthdayCtrl   = TextEditingController();
  final _areaCtrl       = TextEditingController();
  String? _selectedSex;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _nicknameCtrl.dispose();
    _birthdayCtrl.dispose();
    _areaCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty  ||
        _nicknameCtrl.text.trim().isEmpty  ||
        _birthdayCtrl.text.trim().isEmpty  ||
        _selectedSex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.register(
        firstName: _firstNameCtrl.text.trim(),
        lastName:  _lastNameCtrl.text.trim(),
        nickname:  _nicknameCtrl.text.trim(),
        birthday:  _birthdayCtrl.text.trim(),
        sex:       _selectedSex!,
        area:      _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
      );
      if (!mounted) return;
      pushFade(context, const MenuScreen());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                      LightField(hintText: 'Example: Sisa', controller: _firstNameCtrl),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'LAST NAME'),
                      LightField(hintText: 'Example: Antido', controller: _lastNameCtrl),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'NICKNAME'),
                      LightField(hintText: 'Example: Sample', controller: _nicknameCtrl),
                      const SizedBox(height: 10),
                      const FormLabel(text: 'BIRTHDAY'),
                      LightField(
                        hintText: '10/22/2004',
                        keyboardType: TextInputType.datetime,
                        prefixIcon: Icons.calendar_month,
                        controller: _birthdayCtrl,
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
                        controller: _areaCtrl,
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
                            imagePath: 'assets/misc/boy.png',
                            label: 'MALE',
                            backgroundColor: const Color(0xFF67D1F2),
                            selected: _selectedSex == 'MALE',
                            onTap: () => setState(() => _selectedSex = 'MALE'),
                          ),
                          SexCard(
                            imagePath: 'assets/misc/girl.png',
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
                          onPressed: _isLoading ? null : _handleSubmit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('SUBMIT'),
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
