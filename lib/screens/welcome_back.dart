import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api_service.dart';
import '../local_sync_store.dart';
import '../navigation/route_transitions.dart';
import '../widgets/backend_feedback.dart';
import '../widgets/form.dart';
import '../widgets/kow_animated_button.dart';
import '../widgets/mock_background.dart';
import 'start.dart';
import 'welcome_student.dart';

const double _kFigmaW = 412;
const double _kFigmaH = 917;
const double _kMaxContentWidth = 560;
const double _kTabletBreakpoint = 700;
const double _kWebMaxWidth = 600;

const _kIntroDuration = Duration(milliseconds: 900);
const _kEmphasisDuration = Duration(milliseconds: 2200);

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _birthdayController = TextEditingController();
  DateTime? _selectedBirthday;
  bool _isLoading = false;

  late final AnimationController _introController;
  late final AnimationController _emphasisController;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: _kIntroDuration,
    )..forward();
    _emphasisController = AnimationController(
      vsync: this,
      duration: _kEmphasisDuration,
    )..repeat();
  }

  @override
  void dispose() {
    _emphasisController.dispose();
    _introController.dispose();
    _nicknameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Widget _introWrap({
    required Widget child,
    required double begin,
    required double end,
    Offset slideBegin = const Offset(0, 0.06),
  }) {
    final curved = CurvedAnimation(
      parent: _introController,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: slideBegin,
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  Widget _waveWrap({
    required Widget child,
    double phaseOffset = 0,
    required double Function(double wave) liftBuilder,
    required double Function(double wave) scaleBuilder,
  }) {
    return AnimatedBuilder(
      animation: _emphasisController,
      builder: (_, inner) {
        final wave = math.sin(
          _emphasisController.value * 2 * math.pi + phaseOffset,
        );
        return Transform.translate(
          offset: Offset(0, -liftBuilder(wave)),
          child: Transform.scale(scale: scaleBuilder(wave), child: inner),
        );
      },
      child: child,
    );
  }

  Future<void> _handleStart(BuildContext context) async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      await BackendFeedbackOverlay.showMessage(
        context: context,
        title: 'Missing Info',
        message: 'Please enter your nickname and birthday.',
        tone: BackendFeedbackTone.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await BackendFeedbackOverlay.runWithLoading<void>(
        context: context,
        title: 'Checking Account',
        message: 'Opening your saved KOW adventure...',
        loadingMessages: const [
          'Checking this device',
          'Looking for saved progress',
          'Trying online account lookup',
        ],
        task: () => ApiService.login(
          nickname: _nicknameController.text.trim(),
          birthday: _birthdayController.text.trim(),
        ),
      );

      if (!context.mounted) {
        return;
      }
      pushFadeReplacement(context, const StartScreen());
    } on ApiException catch (e) {
      if (!context.mounted) {
        return;
      }
      if (e.message.contains('connect to the internet before signing in')) {
        final connectNow = await BackendFeedbackOverlay.showChoice(
          context: context,
          title: 'Connect First',
          message:
              'This device has not been synced online yet. Connect to the internet, then tap Connect to arm auto-sync.',
          tone: BackendFeedbackTone.warning,
          primaryLabel: 'Connect',
          secondaryLabel: 'Cancel',
        );

        if (connectNow == true) {
          await LocalSyncStore.instance.setAutoSyncListenerEnabled(true);
          try {
            await BackendFeedbackOverlay.runWithLoading<void>(
              context: context,
              title: 'First Sync',
              message: 'Downloading learner data for offline sign-in.',
              loadingMessages: const [
                'Connecting to KOW server',
                'Downloading learner login cache',
                'Downloading learner progress',
                'Downloading questions and images',
                'Finalizing offline-ready data',
              ],
              task: ApiService.bootstrapOfflineData,
            );
            if (!context.mounted) return;
            await BackendFeedbackOverlay.showMessage(
              context: context,
              title: 'Ready Offline',
              tone: BackendFeedbackTone.success,
              message:
                  'Sync complete. This device can now sign in learners offline.',
              barrierDismissible: false,
              showCloseButton: false,
            );
          } on ApiException {
            if (!context.mounted) return;
            await BackendFeedbackOverlay.showMessage(
              context: context,
              title: 'Sync Paused',
              tone: BackendFeedbackTone.warning,
              message:
                  'Stable internet is needed to finish first sync. Please reconnect and tap Connect again.',
            );
          }
        }
        return;
      }

      await BackendFeedbackOverlay.showMessage(
        context: context,
        title: 'Login Failed',
        message: e.message,
        tone: BackendFeedbackTone.error,
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      await BackendFeedbackOverlay.showMessage(
        context: context,
        title: 'Server Unreachable',
        message: 'Could not connect to the KOW server. Try again.',
        tone: BackendFeedbackTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthday ?? DateTime(now.year - 8, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) {
      return;
    }

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
        final mediaH = MediaQuery.of(dialogContext).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: _kMaxContentWidth,
                maxHeight: mediaH * 0.92,
              ),
              child: SingleChildScrollView(
                child: WelcomeStudentFormCard(
                  onClose: () => Navigator.of(dialogContext).pop(),
                  onSubmit: () {
                    Navigator.of(dialogContext).pop();
                    pushFadeReplacement(context, const StartScreen());
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = math.min(constraints.maxWidth, _kWebMaxWidth);
            final screenH = constraints.maxHeight;
            final isTablet = screenW >= _kTabletBreakpoint;
            final contentW = math.min(
              screenW,
              isTablet ? _kMaxContentWidth : screenW,
            );
            final scale = math.min(contentW / _kFigmaW, screenH / _kFigmaH);
            final designW = _kFigmaW * scale;
            final designH = _kFigmaH * scale;

            double sx(double px) => px * scale;

            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kWebMaxWidth),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: designW,
                      height: designH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: sx(20),
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Transform.scale(
                                scale: 2.2,
                                child: LogoRow(top: 8, width: sx(372)),
                              ),
                            ),
                          ),
                          Positioned(
                            left: sx(-30),
                            bottom: sx(200),
                            width: sx(160),
                            height: sx(160),
                            child: Image.asset(
                              'assets/themes/planets_spc.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            left: sx(60),
                            bottom: sx(20),
                            width: sx(140),
                            height: sx(140),
                            child: Image.asset(
                              'assets/themes/planets_spc.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            right: sx(10),
                            bottom: sx(10),
                            width: sx(130),
                            height: sx(130),
                            child: Image.asset(
                              'assets/themes/planets_spc.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            left: sx(-50),
                            top: sx(100),
                            width: sx(200),
                            height: sx(200),
                            child: Image.asset(
                              'assets/sisa_oyo/oyo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            right: sx(-10),
                            top: sx(100),
                            width: sx(110),
                            height: sx(240),
                            child: Image.asset(
                              'assets/sisa_oyo/sisa.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            top: sx(160),
                            height: sx(120),
                            child: _introWrap(
                              begin: 0.0,
                              end: 0.45,
                              slideBegin: const Offset(0, 0.08),
                              child: _waveWrap(
                                liftBuilder: (wave) => wave * sx(3),
                                scaleBuilder: (wave) => 1 + (wave * 0.012),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'WELCOME\nBACK!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize: sx(50),
                                        fontWeight: FontWeight.w900,
                                        height: 0.95,
                                        letterSpacing: 3,
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
                          Positioned(
                            left: sx(20),
                            right: sx(20),
                            top: sx(300),
                            height: sx(48),
                            child: _introWrap(
                              begin: 0.2,
                              end: 0.65,
                              slideBegin: const Offset(0, 0.08),
                              child: _waveWrap(
                                phaseOffset: math.pi / 2,
                                liftBuilder: (wave) => wave * sx(2),
                                scaleBuilder: (wave) => 1 + (wave * 0.008),
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
                                        letterSpacing: 1.5,
                                        color: const Color(0xFFEFEA50),
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
                          Positioned(
                            left: sx(20),
                            top: sx(360),
                            width: sx(372),
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  KowTextField(
                                    hintText: 'NICKNAME',
                                    controller: _nicknameController,
                                    prefixIcon: Icons.person,
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                    height: sx(76).clamp(60.0, 80.0),
                                    fontSize: sx(24).clamp(18.0, 28.0),
                                    borderRadius: sx(22).clamp(16.0, 24.0),
                                    fillColor: Colors.white,
                                  ),
                                  SizedBox(height: sx(18)),
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
                                        height: sx(50),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                    height: sx(76).clamp(60.0, 80.0),
                                    fontSize: sx(24).clamp(18.0, 28.0),
                                    borderRadius: sx(22).clamp(16.0, 24.0),
                                    fillColor: Colors.white,
                                  ),
                                  SizedBox(height: sx(22)),
                                  SizedBox(
                                    height: sx(60).clamp(56.0, 76.0),
                                    child: KowAnimatedButton(
                                      label: _isLoading
                                          ? 'LOADING...'
                                          : 'START',
                                      backgroundColor: const Color(0xFF5C87E5),
                                      textColor: Colors.white,
                                      onPressed: _isLoading
                                          ? null
                                          : () => _handleStart(context),
                                      height: sx(66).clamp(56.0, 76.0),
                                      fontSize: sx(25).clamp(20.0, 28.0),
                                    ),
                                  ),
                                  SizedBox(height: sx(18)),
                                  AnimatedBuilder(
                                    animation: _emphasisController,
                                    builder: (_, child) {
                                      final wave = math.sin(
                                        _emphasisController.value * 2 * math.pi,
                                      );
                                      final opacity =
                                          0.65 + ((wave + 1) * 0.175);
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
                                        color: const Color(0xFFEFEA50),
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
                                  SizedBox(height: sx(14)),
                                  SizedBox(
                                    width: sx(150).clamp(140.0, 180.0),
                                    height: sx(60).clamp(45.0, 70.0),
                                    child: KowAnimatedButton(
                                      label: 'SIGN UP',
                                      backgroundColor: const Color(0xFFF2F089),
                                      textColor: const Color(0xFF2B2B2B),
                                      onPressed: () =>
                                          _showSignUpDialog(context),
                                      height: sx(60).clamp(56.0, 70.0),
                                      fontSize: sx(22).clamp(18.0, 26.0),
                                      width: sx(150).clamp(140.0, 180.0),
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
