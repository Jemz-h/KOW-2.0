import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../api_service.dart';
import '../navigation/route_transitions.dart';
import '../widgets/form.dart';
import '../widgets/kow_animated_button.dart';
import '../widgets/mock_background.dart';
import 'start.dart';
import 'welcome_student.dart';

// ─── Layout / Figma constants ─────────────────────────────────────────────────
const double _kFigmaW           = 412;
const double _kFigmaH           = 917;
const double _kMaxContentWidth  = 560;
const double _kTabletBreakpoint = 700;
const double _kWebMaxWidth      = 600;

// ─── Duration constants ───────────────────────────────────────────────────────
const _kIntroDuration    = Duration(milliseconds: 900);
const _kEmphasisDuration = Duration(milliseconds: 2200);

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with TickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _birthdayController = TextEditingController();
  DateTime? _selectedBirthday;
  bool _isLoading = false;

  // ── Controllers ───────────────────────────────────────────────────────────────
  late final AnimationController _introController;
  late final AnimationController _emphasisController;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _introController    = AnimationController(vsync: this, duration: _kIntroDuration)..forward();
    _emphasisController = AnimationController(vsync: this, duration: _kEmphasisDuration)..repeat();
  }

  @override
  void dispose() {
    _emphasisController.dispose();
    _introController.dispose();
    _nicknameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  // ── Animation helpers ─────────────────────────────────────────────────────────

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
        position: Tween<Offset>(begin: slideBegin, end: Offset.zero).animate(curved),
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
        final wave = math.sin(_emphasisController.value * 2 * math.pi + phaseOffset);
        return Transform.translate(
          offset: Offset(0, -liftBuilder(wave)),
          child: Transform.scale(scale: scaleBuilder(wave), child: inner),
        );
      },
      child: child,
    );
  }

  // ── Data / actions ────────────────────────────────────────────────────────────

  Future<void> _handleStart(BuildContext context) async {
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
      if (!context.mounted) return;
      pushFadeReplacement(context, const MenuScreen());
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context:     context,
      initialDate: _selectedBirthday ?? DateTime(now.year - 8, now.month, now.day),
      firstDate:   DateTime(1900),
      lastDate:    now,
    );
    if (picked == null) return;
    setState(() {
      _selectedBirthday        = picked;
      _birthdayController.text = _formatBirthday(picked);
    });
  }

  // yyyy-mm-dd format expected by the API (from second file)
  String _formatBirthday(DateTime d) {
    final yyyy = d.year.toString();
    final mm   = d.month.toString().padLeft(2, '0');
    final dd   = d.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _showSignUpDialog(BuildContext context) async {
    await showDialog<void>(
      context:            context,
      barrierDismissible: true,
      barrierColor:       Colors.black26,
      builder: (dialogContext) {
        final mediaH = MediaQuery.of(dialogContext).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:    const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:  _kMaxContentWidth,
                maxHeight: mediaH * 0.92,
              ),
              child: SingleChildScrollView(
                child: WelcomeStudentFormCard(
                  onClose:  () => Navigator.of(dialogContext).pop(),
                  onSubmit: () {
                    Navigator.of(dialogContext).pop();
                    pushFadeReplacement(context, const StartScreen());
                  },
                  onAlreadyHaveAccountTap: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // ← prevents layout resize on keyboard open
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;
            final scale   = math.min(screenW / _kFigmaW, screenH / _kFigmaH);
            final designW = _kFigmaW * scale;
            final designH = _kFigmaH * scale;
            double sx(double px) => px * scale;

            return SafeArea(
              child: Center(
                child: SizedBox(
                  width:  designW,
                  height: designH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildLogos(sx),
                      _buildPlanets(sx),
                      _buildMascots(sx),
                      _buildTitle(sx),
                      _buildSubtitle(sx),
                      _buildFormSection(sx, context),
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
  // ── Stack layer builders ───────────────────────────────────────────────────────

  Widget _buildLogos(double Function(double) sx) {
    return Positioned(
      top:   sx(20),
      left:  0,
      right: 0,
      child: Center(
        child: Transform.scale(
          scale: 2.2,
          child: LogoRow(top: 8, width: sx(372)),
        ),
      ),
    );
  }

  Widget _buildPlanets(double Function(double) sx) {
    return Stack(
      children: [
        Positioned(
          left:   sx(-30),
          bottom: sx(200),
          width:  sx(160),
          height: sx(160),
          child: Image.asset('assets/themes/planets_spc.png', fit: BoxFit.contain),
        ),
        Positioned(
          left:   sx(60),
          bottom: sx(20),
          width:  sx(140),
          height: sx(140),
          child: Image.asset('assets/themes/planets_spc.png', fit: BoxFit.contain),
        ),
        Positioned(
          right:  sx(10),
          bottom: sx(10),
          width:  sx(130),
          height: sx(130),
          child: Image.asset('assets/themes/planets_spc.png', fit: BoxFit.contain),
        ),
      ],
    );
  }

  Widget _buildMascots(double Function(double) sx) {
    return Stack(
      children: [
        Positioned(
          left:   sx(-50),
          top:    sx(100),
          width:  sx(200),
          height: sx(200),
          child: Image.asset('assets/sisa_oyo/oyo.png', fit: BoxFit.contain),
        ),
        Positioned(
          right:  sx(-10),
          top:    sx(100),
          width:  sx(110),
          height: sx(240),
          child: Image.asset('assets/sisa_oyo/sisa.png', fit: BoxFit.contain),
        ),
      ],
    );
  }

  Widget _buildTitle(double Function(double) sx) {
    return Positioned(
      left:   0,
      right:  0,
      top:    sx(160),
      height: sx(120),
      child: _introWrap(
        begin:      0.0,
        end:        0.45,
        slideBegin: const Offset(0, 0.08),
        child: _waveWrap(
          liftBuilder:  (wave) => wave * sx(3),
          scaleBuilder: (wave) => 1 + (wave * 0.012),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'WELCOME\nBACK!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily:    'SuperCartoon',
                  fontSize:      sx(50),
                  fontWeight:    FontWeight.w900,
                  height:        0.95,
                  letterSpacing: 3,
                  color:         Colors.white,
                  shadows: const [
                    Shadow(blurRadius: 8, color: Colors.black45, offset: Offset(2, 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(double Function(double) sx) {
    return Positioned(
      left:   sx(20),
      right:  sx(20),
      top:    sx(300),
      height: sx(48),
      child: _introWrap(
        begin:      0.2,
        end:        0.65,
        slideBegin: const Offset(0, 0.08),
        child: _waveWrap(
          phaseOffset:  math.pi / 2,
          liftBuilder:  (wave) => wave * sx(2),
          scaleBuilder: (wave) => 1 + (wave * 0.008),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'LOGIN TO CONTINUE YOUR ADVENTURE!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily:    'SuperCartoon',
                  fontSize:      sx(20),
                  fontWeight:    FontWeight.w800,
                  height:        1.0,
                  letterSpacing: 1.5,
                  color:         const Color(0xFFEFEA50),
                  shadows: const [
                    Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBox(Widget child, double Function(double) sx) {
    return Padding(
      padding: EdgeInsets.all(sx(10)),
      child: SizedBox(
        width:  sx(50),
        height: sx(50),
        child: Center(child: child),
      ),
    );
  }

 Widget _buildFormSection(double Function(double) sx, BuildContext context) {
  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

  return Positioned(
    left:   sx(20),
    top:    sx(360),
    width:  sx(372),
    // Give the column enough room to scroll if keyboard is up
    height: MediaQuery.of(context).size.height - sx(360),
    child: SingleChildScrollView(
      // Pad the bottom so content scrolls above the keyboard
      padding: EdgeInsets.only(bottom: keyboardHeight + sx(20)),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key:              _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── NICKNAME ───
            KowTextField(
              hintText:         'NICKNAME',
              controller:       _nicknameController,
              prefixIconWidget: _iconBox(
                Image.asset('assets/icons/user.png', width: sx(42), height: sx(42)),
                sx,
              ),
              validator:    (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
              height:       sx(76),
              fontSize:     sx(24),
              borderRadius: sx(22),
              fillColor:    Colors.white,
            ),
            SizedBox(height: sx(18)),
            // ─── BIRTHDAY ───
            KowTextField(
              hintText:         'BIRTHDAY',
              readOnly:         true,
              onTap:            () => _pickBirthday(context),
              controller:       _birthdayController,
              prefixIconWidget: _iconBox(
                SvgPicture.asset('assets/icons/bday.svg', width: sx(46), height: sx(46)),
                sx,
              ),
              suffixIcon: Icon(Icons.arrow_drop_down, size: sx(40), color: const Color(0xFF111111)),
              validator:    (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
              height:       sx(76),
              fontSize:     sx(24),
              borderRadius: sx(22),
              fillColor:    Colors.white,
            ),
            SizedBox(height: sx(22)),
            // ─── START button ───
            SizedBox(
              height: sx(60).clamp(56.0, 76.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFF6C93E5), Color(0xFF4A43CA)],
                    center: Alignment.center,
                    radius: 0.9,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: KowAnimatedButton(
                  label:           _isLoading ? 'LOADING...' : 'START',
                  backgroundColor: Colors.transparent,
                  textColor:       Colors.white,
                  letterSpacing:   2,
                  onPressed:       _isLoading ? null : () => _handleStart(context),
                  height:          sx(66).clamp(56.0, 76.0),
                  fontSize:        sx(25).clamp(20.0, 28.0),
                ),
              ),
            ),
            SizedBox(height: sx(18)),
            // ─── "No nickname yet?" hint ───
            AnimatedBuilder(
              animation: _emphasisController,
              builder: (_, child) {
                final wave    = math.sin(_emphasisController.value * 2 * math.pi);
                final opacity = 0.65 + ((wave + 1) * 0.175);
                return Opacity(opacity: opacity, child: child);
              },
              child: Text(
                'NO NICKNAME YET? CLICK THE BUTTON BELOW',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily:    'SuperCartoon',
                  fontSize:      sx(15),
                  letterSpacing: 0.08 * sx(15),
                  fontWeight:    FontWeight.w800,
                  color:         const Color(0xFFEFEA50),
                  shadows: const [
                    Shadow(blurRadius: 3, color: Colors.black38, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
            SizedBox(height: sx(14)),
            // ─── SIGN UP button ───
            SizedBox(
              width:  sx(150).clamp(140.0, 180.0),
              height: sx(60).clamp(45.0, 70.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Color(0xFFF6FF79), Color(0xFFCBA559)],
                    center: Alignment.center,
                    radius: 0.9,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                child: KowAnimatedButton(
                  label:           'SIGN UP',
                  backgroundColor: Colors.transparent,
                  textColor:       const Color(0xFF000000),
                  letterSpacing:   2,
                  onPressed:       () => _showSignUpDialog(context),
                  height:          sx(60).clamp(56.0, 70.0),
                  fontSize:        sx(22).clamp(18.0, 26.0),
                  width:           sx(150).clamp(140.0, 180.0),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}