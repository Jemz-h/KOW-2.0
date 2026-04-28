// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'level_map.dart';
import '../screens/settings.dart';
import '../widgets/mock_background.dart';
import '../widgets/coming_soon.dart'; // ← comingsoon()

// ── Responsive helper ──────────────────────────────────────────
class R {
  final double w;
  final double h;
  final bool isTablet;
  R(this.w, this.h) : isTablet = w >= 600;
  double s(double val) => val * (w / 390).clamp(0.85, isTablet ? 1.25 : 1.4);
  double sw(double val) => val * (w / 390).clamp(0.85, isTablet ? 1.25 : 1.4);
  double sh(double val) => val * (h / 844).clamp(0.85, isTablet ? 1.20 : 1.4);
  double get popupMaxW => isTablet ? w * 0.65 : w * 0.88;
}

class GradeApp extends StatelessWidget {
  const GradeApp({super.key});
  @override
  Widget build(BuildContext context) => const GradeSelectScreen();
}

// ── Grade data ─────────────────────────────────────────────────
const List<Map<String, String>> _kGrades = [
  {'label': 'PUNLA', 'age': '3-5 YRS OLD'},
  {'label': 'BINHI', 'age': '6-8 YRS OLD'},
  {'label': 'COMING', 'age': 'SOON'},
];

String _gradeAsset(int gradeIndex, String theme) {
  const Map<String, List<String>> themeAssets = {
    'sauyo': [
      'assets/grade_select/s_1.svg',
      'assets/grade_select/s_2.svg',
      'assets/grade_select/s_3.svg',
    ],
    'classroom': [
      'assets/grade_select/c_1.svg',
      'assets/grade_select/c_2.svg',
      'assets/grade_select/c_3.svg',
    ],
    'space': [
      'assets/grade_select/o_1.svg',
      'assets/grade_select/o_2.svg',
      'assets/grade_select/o_3.svg',
    ],
  };
  final assets = themeAssets[theme] ?? themeAssets['space']!;
  return assets[gradeIndex.clamp(0, assets.length - 1)];
}

const Map<String, Map<String, String>> _themePageBackgrounds = {
  'classroom': {
    'grade_select': 'assets/themes/p.class-def.png',
    'level_map': 'assets/themes/p.class-lvl.png',
  },
  'space': {
    'grade_select': 'assets/themes/p.space-m2.png',
    'level_map': 'assets/themes/p.space-def.png',
  },
  'sauyo': {
    'grade_select': 'assets/themes/s.card.png',
    'level_map': 'assets/themes/s.card.png',
  },
};

String _pageBg(String theme, String page) {
  return _themePageBackgrounds[theme]?[page] ??
      themeBackgrounds[theme] ??
      themeBackgrounds['space']!;
}

// ── Each rendered card holds its grade index and whether it is
//    the one being displaced (exits with a fade-out).
class _CardSlot {
  final int slot;
  final int gradeIdx;
  final bool isExiting; // true → fade out as it leaves centre
  const _CardSlot(this.slot, this.gradeIdx, {this.isExiting = false});
}

class GradeSelectScreen extends StatefulWidget {
  const GradeSelectScreen({super.key});
  @override
  State<GradeSelectScreen> createState() => _GradeSelectScreenState();
}

class _GradeSelectScreenState extends State<GradeSelectScreen>
    with TickerProviderStateMixin {
  final int _n = _kGrades.length;

  int _centreIndex = 0;
  double _offset = 0.0;
  late List<_CardSlot> _cards;

  final ValueNotifier<bool> _showPopup = ValueNotifier(false);

  late final AnimationController _carouselCtrl;
  late final AnimationController _bobCtrl;
  late final Animation<double> _bobAnim;
  late final AnimationController _popupCtrl;
  late final Animation<double> _popupScale;
  late final Animation<double> _popupFade;
  late final AnimationController _shipCtrl;
  final Tween<double> _offsetTween = Tween<double>(begin: 0, end: 0);
  late final CurvedAnimation _offsetCurved;

  int _wrap(int i) => ((i % _n) + _n) % _n;

  // True when the currently centred grade is the "COMING SOON" placeholder.
  bool get _isComing => _kGrades[_centreIndex]['label'] == 'COMING';

  @override
  void initState() {
    super.initState();

    _rebuildCards(centre: 0, dir: 0);

    _carouselCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );

    _offsetCurved = CurvedAnimation(
      parent: _carouselCtrl,
      curve: Curves.easeInOut,
    );

    _carouselCtrl.addListener(() {
      setState(() => _offset = _offsetTween.evaluate(_offsetCurved));
    });

    _carouselCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _offset = 0.0;
          _rebuildCards(centre: _centreIndex, dir: 0);
        });
      }
    });

    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _bobAnim = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut));

    _popupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _popupScale = Tween<double>(
      begin: 0.75,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOutBack));
    _popupFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOut));

    _shipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  // ── Card layout ────────────────────────────────────────────────
  // Slots map to visual positions BEFORE the tween plays.
  //
  // dir == 0  →  normal resting state (init / after snap)
  //
  // dir == 1  →  swiped forward (next grade, from the right)
  //   offset tween: 0 → 1
  //   new centre sits at slot 1  → dist = 1-0=1 (right) … 1-1=0 (centre) ✓
  //   old centre sits at slot 0  → dist = 0-0=0 (centre) … 0-1=-1 (exit left) ✓  isExiting=true
  //   right wing  sits at slot 2
  //
  // dir == -1 →  swiped back (previous grade, from the left) — mirror image

  void _rebuildCards({required int centre, required int dir}) {
    if (dir == 0) {
      _cards = [
        _CardSlot(-1, _wrap(centre - 1)),
        _CardSlot(0, _wrap(centre)),
        _CardSlot(1, _wrap(centre + 1)),
      ];
    } else if (dir == 1) {
      _cards = [
        _CardSlot(
          0,
          _wrap(centre - 1),
          isExiting: true,
        ), // previous centre → exits left
        _CardSlot(1, _wrap(centre)), // NEW centre → slides in from right
        _CardSlot(2, _wrap(centre + 1)), // right wing
      ];
    } else {
      // dir == -1
      _cards = [
        _CardSlot(-2, _wrap(centre - 1)), // left wing
        _CardSlot(-1, _wrap(centre)), // NEW centre → slides in from left
        _CardSlot(
          0,
          _wrap(centre + 1),
          isExiting: true,
        ), // previous centre → exits right
      ];
    }
  }

  List<_CardSlot> get _zSorted {
    final sorted = List<_CardSlot>.from(_cards);
    sorted.sort((a, b) {
      final da = (a.slot - _offset).abs();
      final db = (b.slot - _offset).abs();
      return db.compareTo(da);
    });
    return sorted;
  }

  // ── Opacity for a card given its current dist from centre ──────
  // All cards maintain full opacity for smooth slide animations
  double _opacityFor(double dist, bool isExiting) {
    final absDist = dist.abs();
    // Full opacity for all cards - no fade effect
    if (absDist <= 1.0) {
      return 1.0;
    }
    return 1.0;
  }

  @override
  void dispose() {
    _carouselCtrl.dispose();
    _offsetCurved.dispose();
    _bobCtrl.dispose();
    _popupCtrl.dispose();
    _shipCtrl.dispose();
    _showPopup.dispose();
    super.dispose();
  }

  void _go(int dir) {
    if (_carouselCtrl.isAnimating) return;
    _centreIndex = _wrap(_centreIndex + dir);
    _offsetTween.begin = 0.0;
    _offsetTween.end = dir.toDouble();
    // Rebuild BEFORE forwarding so the incoming card starts at its off-screen slot
    setState(() => _rebuildCards(centre: _centreIndex, dir: dir));
    _carouselCtrl.forward(from: 0);
  }

  // Called when the play button is tapped.
  // Shows the coming-soon dialog if the selected grade is a placeholder,
  // otherwise opens the subject picker popup as normal.
  void _onPlayTapped() {
    if (_isComing) {
      comingsoon(context);
    } else {
      _openPopup();
    }
  }

  void _openPopup() {
    _showPopup.value = true;
    _popupCtrl.forward(from: 0);
  }

  void _closePopup() {
    _popupCtrl.reverse().then((_) => _showPopup.value = false);
  }

  void _goToLevelMap(String subject) {
    _popupCtrl.reverse().then((_) {
      _showPopup.value = false;
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => LevelMapScreen(
            grade: _kGrades[_centreIndex]['label']!,
            subject: subject,
            gradeImg: _gradeAsset(_centreIndex, selectedThemeNotifier.value),
          ),
          transitionsBuilder: (_, animation, __, child) {
            final slide =
                Tween<Offset>(
                  begin: const Offset(0.0, 0.30),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeIn,
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 480),
        ),
      );
    });
  }

  void _goToSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  double _scaleFor(double dist) => (1.0 - dist.abs() * 0.42).clamp(0.48, 1.0);
  double _yFor(double dist) => dist * dist * 70;
  double _xFor(double dist, double sw) => dist * sw * 0.38;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final r = R(size.width, size.height);
    final islandSize = r.sw(300.0);
    final settingSize = r.s(54.0);
    final backSize = r.s(58.0);
    final bannerH = r.sh(90.0);
    final arrowSize = r.s(95.0);
    final labelSize = r.s(24.0);
    final ageSize = r.s(17.0);
    final bannerRadius = r.sw(30.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ───────────────────────────────────────────
          ValueListenableBuilder<String>(
            valueListenable: selectedThemeNotifier,
            builder: (context, theme, _) => RepaintBoundary(
              child: Image.asset(
                _pageBg(theme, 'grade_select'),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF0D1B2E)),
              ),
            ),
          ),

          // ── Title ────────────────────────────────────────────────
          Positioned(
            top: size.height * 0.05,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width * 0.85),
                child: Text(
                  'SELECT\nGRADE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'SuperCartoon',
                    fontSize: r.s(r.isTablet ? 44 : 52),
                    height: 1.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 4,
                        offset: const Offset(3, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Settings button ──────────────────────────────────────
          Positioned(
            top: r.sh(36),
            right: r.sw(16),
            child: _TapIcon(
              onTap: _goToSettings,
              child: SvgPicture.asset(
                'assets/icons/setting.svg',
                width: settingSize,
                height: settingSize,
              ),
            ),
          ),

          // ── Island carousel ──────────────────────────────────────
          Positioned(
            top: size.height * 0.20,
            height: size.height * 0.50,
            left: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) _go(1);
                if (details.primaryVelocity! > 200) _go(-1);
              },
              child: ValueListenableBuilder<String>(
                valueListenable: selectedThemeNotifier,
                builder: (_, theme, __) {
                  return AnimatedBuilder(
                    animation: Listenable.merge([_carouselCtrl, _bobCtrl]),
                    builder: (_, __) {
                      final cards = _zSorted;
                      return Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip
                            .none, // allow off-screen cards to slide in visibly
                        children: cards.map((card) {
                          final dist = card.slot.toDouble() - _offset;
                          final scale = _scaleFor(dist);
                          final x = _xFor(dist, size.width);
                          final y = _yFor(dist);
                          final bobWeight = (1.0 - dist.abs()).clamp(0.0, 1.0);
                          final opacity = _opacityFor(dist, card.isExiting);

                          return RepaintBoundary(
                            key: ValueKey(card.gradeIdx),
                            child: Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset: Offset(
                                  x,
                                  y + _bobAnim.value * bobWeight,
                                ),
                                child: Transform.scale(
                                  scale: scale,
                                  child: SvgPicture.asset(
                                    _gradeAsset(card.gradeIdx, theme),
                                    width: islandSize,
                                    height: islandSize,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // ── Bottom banner ────────────────────────────────────────
          ValueListenableBuilder<String>(
            valueListenable: selectedThemeNotifier,
            builder: (_, theme, __) {
              final isSpaceTheme = theme == 'space';
              return Positioned(
                bottom: size.height * 0.06,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: r.sw(4)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // LEFT ARROW
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _go(-1),
                            child: SizedBox(
                              width: arrowSize,
                              height: bannerH * 1.25,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      '<',
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize: arrowSize,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 4
                                          ..color = Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '<',
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize: arrowSize,
                                        color: const Color(0xFFFFD700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // CENTRE LABEL PANEL
                          Expanded(
                            child: Container(
                              height: bannerH * 1.25,
                              margin: EdgeInsets.symmetric(horizontal: r.sw(2)),
                              padding: EdgeInsets.symmetric(
                                horizontal: r.sw(12),
                                vertical: r.sh(6),
                              ),
                              decoration: BoxDecoration(
                                color: isSpaceTheme
                                    ? const Color.fromARGB(150, 255, 255, 255)
                                    : const Color.fromARGB(150, 17, 17, 17),
                                borderRadius: BorderRadius.circular(
                                  bannerRadius * 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        _kGrades[_centreIndex]['label']!,
                                        style: TextStyle(
                                          fontFamily: 'SuperCartoon',
                                          fontSize: labelSize * 1.15,
                                          letterSpacing: labelSize * 0.20,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 4
                                            ..color = Colors.black,
                                        ),
                                      ),
                                      Text(
                                        _kGrades[_centreIndex]['label']!,
                                        style: TextStyle(
                                          fontFamily: 'SuperCartoon',
                                          fontSize: labelSize * 1.15,
                                          color: const Color(0xFFFFD700),
                                          letterSpacing: labelSize * 0.20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: r.sh(6),
                                      horizontal: r.sw(16),
                                    ),
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isSpaceTheme
                                            ? Colors.black
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isSpaceTheme
                                                        ? Colors.black
                                                        : Colors.white)
                                                    .withValues(alpha: 0.6),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        _kGrades[_centreIndex]['age']!,
                                        style: TextStyle(
                                          fontFamily: 'SuperCartoon',
                                          fontSize: ageSize * 1.1,
                                          letterSpacing: ageSize * 0.20,
                                          foreground: Paint()
                                            ..style = PaintingStyle.stroke
                                            ..strokeWidth = 3
                                            ..color = Colors.black,
                                        ),
                                      ),
                                      Text(
                                        _kGrades[_centreIndex]['age']!,
                                        style: TextStyle(
                                          fontFamily: 'SuperCartoon',
                                          fontSize: ageSize * 1.1,
                                          color: const Color(0xFFFFD700),
                                          letterSpacing: ageSize * 0.20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // RIGHT ARROW
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _go(1),
                            child: SizedBox(
                              width: arrowSize,
                              height: bannerH * 1.25,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      '>',
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize: arrowSize,
                                        foreground: Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 4
                                          ..color = Colors.black,
                                      ),
                                    ),
                                    Text(
                                      '>',
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize: arrowSize,
                                        color: const Color(0xFFFFD700),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: r.sh(14)),

                    // PLAY BUTTON — routes to comingsoon() or subject popup
                    AnimatedOpacity(
                      opacity: _carouselCtrl.isAnimating ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: _TapIcon(
                        onTap: _onPlayTapped,
                        child: SvgPicture.asset(
                          'assets/icons/play.svg',
                          width: r.sw(90),
                          height: r.sw(90),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Back button ──────────────────────────────────────────
          Positioned(
            bottom: r.sh(20),
            left: r.sw(20),
            child: _TapIcon(
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/icons/back.svg',
                width: backSize,
                height: backSize,
              ),
            ),
          ),

          // ── Subject popup ────────────────────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: _showPopup,
            builder: (_, visible, __) {
              if (!visible) return const SizedBox.shrink();
              return Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: _closePopup,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
                  Positioned(
                    top: size.height * (r.isTablet ? 0.16 : 0.20),
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: r.popupMaxW),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: r.sw(20)),
                          child: FadeTransition(
                            opacity: _popupFade,
                            child: ScaleTransition(
                              scale: _popupScale,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.fromLTRB(
                                      r.sw(20),
                                      r.sh(28),
                                      r.sw(20),
                                      r.sh(28),
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(197, 0, 0, 0),
                                      borderRadius: BorderRadius.circular(
                                        r.sw(32),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black54,
                                          blurRadius: 24,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'CHOOSE\nSUBJECT',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'SuperCartoon',
                                            fontSize: r.s(30),
                                            color: Colors.white,
                                            height: 1.1,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black45,
                                                blurRadius: 4,
                                                offset: Offset(2, 3),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: r.sh(22)),
                                        _SubjectButton(
                                          label: 'MATH',
                                          iconPath: 'assets/icons/math.svg',
                                          color: const Color(0xFF4FC3F7),
                                          r: r,
                                          iconSize: 95,
                                          labelSize: 22,
                                          onTap: () => _goToLevelMap('MATH'),
                                        ),
                                        SizedBox(height: r.sh(12)),
                                        _SubjectButton(
                                          label: 'SCIENCE',
                                          iconPath: 'assets/icons/science.svg',
                                          color: const Color(0xFF81C784),
                                          r: r,
                                          iconSize: 100,
                                          labelSize: 22,
                                          onTap: () => _goToLevelMap('SCIENCE'),
                                        ),
                                        SizedBox(height: r.sh(12)),
                                        _SubjectButton(
                                          label: 'READING',
                                          iconPath: 'assets/icons/reading.svg',
                                          color: const Color(0xFFFFB74D),
                                          r: r,
                                          iconSize: 90,
                                          labelSize: 22,
                                          onTap: () => _goToLevelMap('READING'),
                                        ),
                                        SizedBox(height: r.sh(12)),
                                        _SubjectButton(
                                          label: 'WRITING',
                                          iconPath: 'assets/icons/writing.svg',
                                          color: const Color(0xFFFFCA28),
                                          r: r,
                                          iconSize: 100,
                                          labelSize: 22,
                                          onTap: () => _goToLevelMap('WRITING'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: r.sh(12),
                                    right: r.sw(12),
                                    child: _TapIcon(
                                      onTap: _closePopup,
                                      child: SvgPicture.asset(
                                        'assets/icons/x.svg',
                                        width: r.s(38),
                                        height: r.s(38),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Subject button ─────────────────────────────────────────────
class _SubjectButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;
  final double labelSize;
  final R r;
  const _SubjectButton({
    required this.label,
    required this.iconPath,
    required this.color,
    required this.onTap,
    required this.r,
    this.iconSize = 48,
    this.labelSize = 22,
  });
  @override
  Widget build(BuildContext context) {
    final scaledIcon = r.sw(iconSize);
    final scaledLabel = r.s(labelSize);
    final scaledBtnH = r.sh(66);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: scaledBtnH,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r.sw(14)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.55),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: scaledLabel,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      blurRadius: 3,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: r.sw(6),
              top: (scaledBtnH - scaledIcon) / 2,
              child: SvgPicture.asset(
                iconPath,
                width: scaledIcon,
                height: scaledIcon,
                allowDrawingOutsideViewBox: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tap icon ───────────────────────────────────────────────────
class _TapIcon extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapIcon({required this.child, required this.onTap});
  @override
  State<_TapIcon> createState() => _TapIconState();
}

class _TapIconState extends State<_TapIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.80,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
