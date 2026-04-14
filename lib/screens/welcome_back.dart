import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api_service.dart';
import '../navigation/route_transitions.dart';
import '../widgets/form.dart';
import '../widgets/kow_animated_button.dart';
import '../widgets/mock_background.dart';
import 'menu.dart';
import 'welcome_student.dart';

/// Login screen that leads to menu or sign-up flow.
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  // Figma base frame (keep consistent with StartScreen)
  static const double _figmaW = 412;
  static const double _figmaH = 917;

  // Tablet handling
  static const double _maxContentWidth = 560;
  static const double _tabletBreakpoint = 700;
  static const double _webMaxWidth = 600;

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
  with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _birthdayController = TextEditingController();
  bool _isLoading = false;
  DateTime? _selectedBirthday;
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

  Future<void> _handleStart() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your nickname and birthday.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.login(
        nickname: _nicknameController.text.trim(),
        birthday: _birthdayController.text.trim(),
      );
      if (!mounted) return;
      pushFadeReplacement(context, const MenuScreen());
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

  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (picked == null) return;

    setState(() {
      _selectedBirthday = picked;
      _birthdayController.text = _formatBirthday(picked);
    });
  }

  String _formatBirthday(DateTime date) {
    final yyyy = date.year.toString();
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _showSignUpDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (dialogContext) {
        final media = MediaQuery.of(dialogContext).size;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: WelcomeBackScreen._maxContentWidth,
                maxHeight: media.height * 0.92,
              ),
              child: SingleChildScrollView(
                child: WelcomeStudentFormCard(
                  onClose: () => Navigator.of(dialogContext).pop(),
                  onSubmit: () {
                    Navigator.of(dialogContext).pop();
                    pushFadeReplacement(context, const MenuScreen());
                  },
                  onAlreadyHaveAccountTap: () =>
                      Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
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
            final screenW = math.min(
              constraints.maxWidth,
              WelcomeBackScreen._webMaxWidth,
            );
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: WelcomeBackScreen._webMaxWidth,
                  ),
                  child: SingleChildScrollView(
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
                        child: LogoRow(width: sx(372)),
                      ),
                      // Planet (Figma shows an extra planet near the lower-left area)
                      Positioned(
                        left: sx(22),
                        top: sy(640),
                        width: sx(300),
                        height: sx(300),
                        child: Image.asset(
                          'assets/themes/planets_spc.png',
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
                          'assets/sisa_oyo/oyo.png',
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
                          'assets/sisa_oyo/sisa.png',
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
                        left: sx(20),
                        top: sy(360),
                        width: sx(372),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              KowTextField(
                                hintText: 'NICKNAME',
                                controller: _nicknameController,
                                prefixIcon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                height: sy(76).clamp(60.0, 80.0),
                                fontSize: sx(24).clamp(18.0, 28.0),
                                borderRadius: sy(22).clamp(16.0, 24.0),
                                fillColor: Colors.white,
                              ),
                              SizedBox(height: sy(18)),
                              KowTextField(
                                hintText: 'BIRTHDAY',
                                readOnly: true,
                                onTap: () => _pickBirthday(context),
                                controller: _birthdayController,
                                suffixIcon: Icon(
                                  Icons.arrow_drop_down,
                                  size: sx(40),
                                  color: const Color(0xFF111111),
                                ),
                                prefixIconWidget: Padding(
                                  padding: EdgeInsets.all(sx(10)),
                                  child: SvgPicture.asset(
                                    'assets/icons/bday.svg',
                                    width: sx(50),
                                    height: sy(50),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  return null;
                                },
                                height: sy(76).clamp(60.0, 80.0),
                                fontSize: sx(24).clamp(18.0, 28.0),
                                borderRadius: sy(22).clamp(16.0, 24.0),
                                fillColor: Colors.white,
                              ),
                              SizedBox(height: sy(22)),
                              SizedBox(
                                height: sy(66).clamp(56.0, 76.0),
                                child: KowAnimatedButton(
                                  label: _isLoading ? 'LOADING...' : 'START',
                                  backgroundColor: const Color(0xFF5C87E5),
                                  textColor: Colors.white,
                                  onPressed: _isLoading
                                      ? null
                                      : _handleStart,
                                  height: sy(66).clamp(56.0, 76.0),
                                  fontSize: sx(25).clamp(20.0, 28.0),
                                ),
                              ),
                              SizedBox(height: sy(18)),
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
                              SizedBox(height: sy(14)),
                              SizedBox(
                                width: sy(150).clamp(140.0, 180.0),
                                height: sy(60).clamp(56.0, 70.0),
                                child: KowAnimatedButton(
                                  label: 'SIGN UP',
                                  backgroundColor: const Color(0xFFF2F089),
                                  textColor: const Color(0xFF2B2B2B),
                                  onPressed: () => _showSignUpDialog(context),
                                  height: sy(60).clamp(56.0, 70.0),
                                  fontSize: sx(22).clamp(18.0, 26.0),
                                  width: sy(150).clamp(140.0, 180.0),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
