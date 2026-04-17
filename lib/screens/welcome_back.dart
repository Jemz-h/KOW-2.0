import 'dart:math' as math;
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../navigation/route_transitions.dart';
import '../widgets/form.dart';
import '../widgets/kow_animated_button.dart';
import '../widgets/mock_background.dart';
import 'menu.dart';
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

/// Login screen that leads to menu or sign-up flow.
class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────────
  final _formKey             = GlobalKey<FormState>();
  final _birthdayController  = TextEditingController();
  final _nicknameController = TextEditingController();
  DateTime? _selectedBirthday;

  // ── Controllers ──────────────────────────────────────────────────────────────
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
    _birthdayController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // ── Animation helpers ─────────────────────────────────────────────────────────

  /// Wraps [child] in a fade + slide intro driven by [_introController].
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

  /// Wraps [child] in a sine-wave float + scale driven by [_emphasisController].
  Widget _waveWrap({
    required Widget child,
    double phaseOffset = 0,
    double liftFactor  = 3,
    double scaleFactor = 0.012,
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

  // ── Data / actions ────────────────────────────────────────────────────────────

  void _handleStart(BuildContext context) {
    if (_formKey.currentState?.validate() != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your birthday before continuing.')),
      );
      return;
    }
    pushFade(context, const MenuScreen());
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
      _selectedBirthday       = picked;
      _birthdayController.text = _formatBirthday(picked);
    });
  }

  String _formatBirthday(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _showSignUpDialog(BuildContext context) async {
    await showDialog<void>(
      context:          context,
      barrierDismissible: true,
      barrierColor:     Colors.black26,
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
                    pushFade(context, const MenuScreen());
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
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW   = math.min(constraints.maxWidth, _kWebMaxWidth);
            final screenH   = constraints.maxHeight;
            final isTablet  = screenW >= _kTabletBreakpoint;
            final contentW  = math.min(screenW, isTablet ? _kMaxContentWidth : screenW);

            final scale  = math.min(contentW / _kFigmaW, screenH / _kFigmaH);
            final designW = _kFigmaW * scale;
            final designH = _kFigmaH * scale;

            // Scaled-unit helpers
            double sx(double px) => px * scale;

            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _kWebMaxWidth),
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width:  designW,
                      height: designH,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildLogos(sx),
                          _buildPlanets(sx, designW, designH),
                          _buildMascots(sx),
                          _buildTitle(sx),
                          _buildSubtitle(sx),
                          _buildFormSection(sx, context),
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

  // ── Stack layer builders ───────────────────────────────────────────────────────

  Widget _buildLogos(double Function(double) sx) {
  return Positioned(
    top: sx(20),
    left: 0,
    right: 0, // ← this is the trick
    child: Center(
      child: Transform.scale(
        scale: 2.2,
        child: LogoRow(
          top: 8,
          width: sx(372),
        ),
      ),
    ),
  );
}
  /// Three planets matching the image: one bottom-left (purple/blue),
  /// one bottom-center (earth), one bottom-right (mars/orange).
  Widget _buildPlanets(double Function(double) sx, double designW, double designH) {
    return Stack(
      children: [
        // Purple/blue planet — bottom left, partially off-screen
        Positioned(
          left:   sx(-30),
          bottom: sx(200),
          width:  sx(160),
          height: sx(160),
          child: Image.asset('assets/themes/planets_spc.png', fit: BoxFit.contain),
        ),
        // Earth — bottom center-left
        Positioned(
          left:   sx(60),
          bottom: sx(20),
          width:  sx(140),
          height: sx(140),
          child: Image.asset('assets/themes/planets_spc.png', fit: BoxFit.contain),
        ),
        // Mars/orange — bottom right
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

        Widget _buildMascots(
        double Function(double) sx, {
        double oyoScale = 2.0,
        double sisaScale = 1.0,
        double topOffset = 100,
      }) {
        return Stack(
          children: [
            // Oyo — left
            Positioned(
              left: sx(-50),
              top: sx(topOffset),
              width: sx(100) * oyoScale,
              height: sx(100) * oyoScale,
              child: Image.asset(
                'assets/sisa_oyo/oyo.png',
                fit: BoxFit.contain,
              ),
            ),

            // Sisa — right
            Positioned(
              right: sx(-10),
              top: sx(topOffset),
              width: sx(110) * sisaScale,
              height: sx(240) * sisaScale,
              child: Image.asset(
                'assets/sisa_oyo/sisa.png',
                fit: BoxFit.contain,
              ),
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
      child:  _introWrap(
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
                  fontFamily:   'SuperCartoon',
                  fontSize:     sx(50),
                  fontWeight:   FontWeight.w900,
                  height:       0.95,
                  letterSpacing: 3,
                  color:        Colors.white,
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
      child:  _introWrap(
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
                  fontFamily: 'SuperCartoon',
                  fontSize:   sx(20),
                  fontWeight: FontWeight.w800,
                  height:     1.0,
                  letterSpacing: 1.5,
                  color:      const Color(0xFFEFEA50),
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

  Widget _buildFormSection(double Function(double) sx, BuildContext context) {
    return Positioned(
      left:  sx(20),
      top:   sx(360),
      width: sx(372),
      child: Form(
        key:              _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Nickname field
            KowTextField(
              hintText:     'NICKNAME',
              prefixIcon:   Icons.person,
              height:       sx(76).clamp(60.0, 80.0),
              fontSize:     sx(24).clamp(18.0, 28.0),
              borderRadius: sx(22).clamp(16.0, 24.0),
              fillColor:    Colors.white,
            ),
            SizedBox(height: sx(18)),

            // Birthday field
            KowTextField(
              hintText:   'BIRTHDAY',
              readOnly:   true,
              onTap:      () => _pickBirthday(context),
              controller: _birthdayController,
              suffixIcon: Icon(Icons.arrow_drop_down, size: sx(40), color: const Color(0xFF111111)),
              prefixIconWidget: Padding(
                padding: EdgeInsets.all(sx(10)),
                child: SvgPicture.asset(
                  'assets/icons/bday.svg',
                  width:  sx(50),
                  height: sx(50),
                  fit:    BoxFit.contain,
                ),
              ),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
              height:       sx(76).clamp(60.0, 80.0),
              fontSize:     sx(24).clamp(18.0, 28.0),
              borderRadius: sx(22).clamp(16.0, 24.0),
              fillColor:    Colors.white,
            ),
            SizedBox(height: sx(22)),

            // START button
            SizedBox(
              height: sx(60).clamp(56.0, 76.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFF6C93E5),
                      Color(0xFF4A43CA),
                    ],
                    center: Alignment.center,
                    radius: 0.9,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: Colors.black,
                      width: 1, // ← adjust thickness here
                    ),
                  ),
                ),
                child: KowAnimatedButton(
                  label: 'START',
                  backgroundColor: Colors.transparent,
                  textColor: const Color.fromARGB(255, 0, 0, 0),
                  letterSpacing: 2,
                  onPressed: () => _handleStart(context),
                  height: sx(66).clamp(56.0, 76.0),
                  fontSize: sx(25).clamp(20.0, 28.0),
                ),
              ),
            ),

            SizedBox(height: sx(18)),

            // "No nickname yet?" hint with pulse opacity
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
                  fontFamily: 'SuperCartoon',
                  fontSize: sx(15),
                  letterSpacing: 0.08 * sx(15), // ← 8%
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFEFEA50),
                  shadows: const [
                    Shadow(blurRadius: 3, color: Colors.black38, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
            SizedBox(height: sx(14)),

            // SIGN UP button
            SizedBox(
              width: sx(150).clamp(140.0, 180.0),
              height: sx(60).clamp(45.0, 70.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Color(0xFFF6FF79),
                      Color(0xFFCBA559),
                    ],
                    center: Alignment.center,
                    radius: 0.9,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: Colors.black,
                      width: 1, // adjust thickness
                    ),
                  ),
                ),
                child: KowAnimatedButton(
                  label: 'SIGN UP',
                  backgroundColor: Colors.transparent,
                  textColor: const Color.fromARGB(255, 0, 0, 0),
                  letterSpacing: 2,
                  onPressed: () => _showSignUpDialog(context),
                  height: sx(60).clamp(56.0, 70.0),
                  fontSize: sx(22).clamp(18.0, 26.0),
                  width: sx(150).clamp(140.0, 180.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}