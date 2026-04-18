import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'level_map.dart';
import '../screens/settings.dart';
import '../widgets/mock_background.dart';

// ── Responsive helper ──────────────────────────────────────────
class R {
  final double w;
  final double h;
  final bool isTablet;
  R(this.w, this.h) : isTablet = w >= 600;
  double s(double val)  => val * (w / 390).clamp(0.85, isTablet ? 1.25 : 1.4);
  double sw(double val) => val * (w / 390).clamp(0.85, isTablet ? 1.25 : 1.4);
  double sh(double val) => val * (h / 844).clamp(0.85, isTablet ? 1.20 : 1.4);
  double get popupMaxW => isTablet ? w * 0.65 : w * 0.88;
}

class GradeApp extends StatelessWidget {
  const GradeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GradeSelectScreen();
  }
}

// ── Grade data as a top-level const to avoid repeated allocation ──
const List<Map<String, String>> _kGrades = [
  {'label': 'PUNLA',  'age': '3-5 YRS OLD', 'img': 'assets/grade_select/moon.png'},
  {'label': 'BINHI',  'age': '6-8 YRS OLD', 'img': 'assets/grade_select/sun.png'},
  {'label': 'COMING', 'age': 'SOON',         'img': 'assets/grade_select/star.png'},
];

const List<int> _kSlots = [-1, 0, 1];

class GradeSelectScreen extends StatefulWidget {
  const GradeSelectScreen({super.key});
  @override
  State<GradeSelectScreen> createState() => _GradeSelectScreenState();
}

class _GradeSelectScreenState extends State<GradeSelectScreen>
    with TickerProviderStateMixin {

  // ── State ────────────────────────────────────────────────────
  double _position = 0.0;
  double _toPosition = 0.0;

  // ValueNotifier avoids full-tree setState for popup open/close
  final ValueNotifier<bool> _showPopup = ValueNotifier(false);

  // ── Pre-sorted slots cache ───────────────────────────────────
  // Recomputed only when _position changes, not on bob/ship ticks
  late List<int> _sortedSlots;

  // ── Animation controllers ─────────────────────────────────
  late final AnimationController _carouselCtrl;
  late final AnimationController _bobCtrl;
  late final Animation<double>   _bobAnim;
  late final AnimationController _popupCtrl;
  late final Animation<double>   _popupScale;
  late final Animation<double>   _popupFade;
  late final AnimationController _shipCtrl;
  late final Animation<double>   _shipBob;
  late final Animation<double>   _shipWiggle;

  // Carousel tween — reused across swipes to avoid object churn
  late final Tween<double> _carouselTween = Tween<double>(begin: 0, end: 0);
  late Animation<double>   _carouselAnim;

  @override
  void initState() {
    super.initState();

    _sortedSlots = List.from(_kSlots);

    // Carousel
    _carouselCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _carouselAnim = _carouselTween.animate(
        CurvedAnimation(parent: _carouselCtrl, curve: Curves.easeInOut));

    // Bob (center island + floating icon)
    _bobCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _bobAnim = Tween<double>(begin: -10, end: 10).animate(
        CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut));

    // Popup
    _popupCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _popupScale = Tween<double>(begin: 0.75, end: 1.0).animate(
        CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOutBack));
    _popupFade  = Tween<double>(begin: 0.0,  end: 1.0).animate(
        CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOut));

    // Spaceship
    _shipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _shipBob    = Tween<double>(begin: -8,    end: 8).animate(
        CurvedAnimation(parent: _shipCtrl, curve: Curves.easeInOut));
    _shipWiggle = Tween<double>(begin: -0.08, end: 0.08).animate(
        CurvedAnimation(parent: _shipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _carouselCtrl.dispose();
    _bobCtrl.dispose();
    _popupCtrl.dispose();
    _shipCtrl.dispose();
    _showPopup.dispose();
    super.dispose();
  }

  int get _currentIndex => _toPosition.round();

  // ── Recompute sorted slots only when position changes ────────
  void _updateSortedSlots() {
    final animOffset = _position - _currentIndex;
    _sortedSlots = List.from(_kSlots)
      ..sort((a, b) {
        final da = (a - animOffset).abs();
        final db = (b - animOffset).abs();
        return db.compareTo(da);
      });
  }

  // ── Carousel slide ───────────────────────────────────────────
  void _go(int dir) {
    final next = _toPosition + dir;
    if (next < 0 || next >= _kGrades.length) return;
    final from = _position;
    _toPosition = next;

    // Reuse the same Tween — just update begin/end
    _carouselTween.begin = from;
    _carouselTween.end   = next;

    // Reassign animation so the new tween values are picked up
    _carouselAnim = _carouselTween.animate(
        CurvedAnimation(parent: _carouselCtrl, curve: Curves.easeInOut));

    _carouselAnim.addListener(() {
      setState(() {
        _position = _carouselAnim.value;
        _updateSortedSlots();
      });
    });

    _carouselCtrl.forward(from: 0);
  }

  // ── Popup open / close ───────────────────────────────────────
  void _openPopup()  {
    _showPopup.value = true;
    _popupCtrl.forward(from: 0);
  }

  void _closePopup() {
    _popupCtrl.reverse().then((_) => _showPopup.value = false);
  }

  // ── Navigate to level map ─────────────────────────────────────
  void _goToLevelMap(String subject) {
    _popupCtrl.reverse().then((_) {
      _showPopup.value = false;
      Navigator.of(context).push(PageRouteBuilder(
        pageBuilder: (_, animation, _) => LevelMapScreen(
          grade:    _kGrades[_currentIndex]['label']!,
          subject:  subject,
          gradeImg: _kGrades[_currentIndex]['img']!,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ));
    });
  }

  // ── Navigate to settings ──────────────────────────────────────
  void _goToSettings() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, animation, _) => const SettingsScreen(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  // ── Carousel layout helpers ───────────────────────────────────
  double _scaleFor(double dist) => (1.0 - dist.abs() * 0.42).clamp(0.48, 1.0);
  double _yFor(double dist)     => dist * dist * 70;
  double _xFor(double dist, double sw) => dist * sw * 0.38;
  int _wrappedIndex(int offset) => (_currentIndex + offset) % _kGrades.length;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final r    = R(size.width, size.height);

    // Scaled sizes — computed once per build, not per child
    final islandSize   = r.sw(300.0);
    final settingSize  = r.s(54.0);
    final backSize     = r.s(58.0);
    final bannerH      = r.sh(76.0);
    final bannerFloat  = r.sh(120.0);
    final floatIconSz  = r.sw(130.0);
    final arrowSize    = r.s(32.0);
    final labelSize    = r.s(20.0);
    final ageSize      = r.s(14.0);
    final bannerRadius = r.sw(40.0);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background ─────────────────────────────────────────
          // RepaintBoundary so background never repaints during animations
          RepaintBoundary(
            child: ValueListenableBuilder<String>(
              valueListenable: selectedThemeNotifier,
              builder: (context, theme, _) {
                final bgAsset = themeBackgrounds[theme] ?? themeBackgrounds['space']!;
                return Image.asset(
                  bgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(color: const Color(0xFF1A2A3A)),
                );
              },
            ),
          ),

          // ── Title ──────────────────────────────────────────────
          Positioned(
            top: size.height * 0.05, left: 0, right: 0,
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
                    shadows: [Shadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 4,
                      offset: const Offset(3, 4),
                    )],
                  ),
                ),
              ),
            ),
          ),

          // ── Settings button ────────────────────────────────────
          Positioned(
            top: r.sh(36), right: r.sw(16),
            child: _TapIcon(
              onTap: _goToSettings,
              child: SvgPicture.asset(
                'assets/icons/setting.svg',
                width: settingSize, height: settingSize,
              ),
            ),
          ),

          // ── Island carousel ─────────────────────────────────────
          Positioned(
            top: size.height * 0.20,
            height: size.height * 0.50,
            left: 0, right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -200) _go(1);
                if (details.primaryVelocity! >  200) _go(-1);
              },
              // AnimatedBuilder scope is limited to carousel + bob only
              child: AnimatedBuilder(
                animation: _bobCtrl,
                builder: (_, _) {
                  final animOffset = _position - _currentIndex;
                  return Stack(
                    alignment: Alignment.center,
                    children: _sortedSlots.map((slot) {
                      final gradeIdx = _wrappedIndex(slot);
                      final dist     = slot - animOffset;
                      final scale    = _scaleFor(dist);
                      final x        = _xFor(dist, size.width);
                      final y        = _yFor(dist);
                      final isCenter = slot == 0;

                      // Wrap each island in RepaintBoundary to isolate repaints
                      return RepaintBoundary(
                        child: Transform.translate(
                          offset: Offset(x, y + (isCenter ? _bobAnim.value : 0)),
                          child: Transform.scale(
                            scale: scale,
                            child: GestureDetector(
                              onTap: isCenter ? _openPopup : null,
                              child: Image.asset(
                                _kGrades[gradeIdx]['img']!,
                                width: islandSize, height: islandSize,
                                fit: BoxFit.contain,
                                // Preload island images for zero-jank swipes
                                cacheWidth: islandSize.toInt() * 2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // ── Bottom banner ───────────────────────────────────────
          Positioned(
            bottom: size.height * 0.10,
            left: r.sw(28), right: r.sw(28),
            child: SizedBox(
              height: bannerFloat,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Banner bar — only rebuilds on _currentIndex change
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      height: bannerH,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1A3A),
                        borderRadius: BorderRadius.circular(bannerRadius),
                        border: Border.all(color: const Color(0xFFFFD700), width: 3),
                        boxShadow: const [BoxShadow(
                          color: Colors.black54, blurRadius: 12, offset: Offset(0, 5),
                        )],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _go(-1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: r.sw(18)),
                              child: Text('<', style: TextStyle(
                                fontFamily: 'SuperCartoon', fontSize: arrowSize,
                                color: _currentIndex > 0
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFF444466),
                              )),
                            ),
                          ),
                          Expanded(
                            child: Transform.translate(
                              offset: Offset(r.sw(5), 0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_kGrades[_currentIndex]['label']!,
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize: labelSize,
                                        color: const Color(0xFFFFD700),
                                        letterSpacing: 3,
                                      )),
                                  Text(_kGrades[_currentIndex]['age']!,
                                      style: TextStyle(
                                        fontFamily: 'SuperCartoon',
                                        fontSize: ageSize,
                                        color: const Color(0xFFFFD700),
                                        letterSpacing: 1,
                                      )),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _go(1),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: r.sw(18)),
                              child: Text('>', style: TextStyle(
                                fontFamily: 'SuperCartoon', fontSize: arrowSize,
                                color: _currentIndex < _kGrades.length - 1
                                    ? const Color(0xFFFFD700)
                                    : const Color(0xFF444466),
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Floating icon — isolated AnimatedBuilder (bob only)
                  Positioned(
                    top: 2, left: r.sw(25),
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _bobAnim,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _bobAnim.value * 0.5),
                          child: child,
                        ),
                        // child is const-ish: rebuilt only on index change
                        child: Image.asset(
                          _kGrades[_currentIndex]['img']!,
                          width: floatIconSz, height: floatIconSz,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Back button ────────────────────────────────────────
          Positioned(
            bottom: r.sh(20), left: r.sw(20),
            child: _TapIcon(
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/icons/back.svg',
                width: backSize, height: backSize,
              ),
            ),
          ),

          // ── Subject popup — driven by ValueNotifier ─────────────
          ValueListenableBuilder<bool>(
            valueListenable: _showPopup,
            builder: (_, visible, _) {
              if (!visible) return const SizedBox.shrink();
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Dim overlay
                  GestureDetector(
                    onTap: _closePopup,
                    child: Container(color: Colors.black.withValues(alpha: 0.55)),
                  ),
                  Positioned(
                    top: size.height * (r.isTablet ? 0.16 : 0.20),
                    left: 0, right: 0,
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
                                  // Popup card
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.fromLTRB(
                                        r.sw(20), r.sh(28), r.sw(20), r.sh(28)),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C2B4A),
                                      borderRadius:
                                          BorderRadius.circular(r.sw(32)),
                                      border: Border.all(
                                          color: const Color(0xFF2E4A7A),
                                          width: 2.5),
                                      boxShadow: const [BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 24,
                                        offset: Offset(0, 10),
                                      )],
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
                                            shadows: const [Shadow(
                                              color: Colors.black45,
                                              blurRadius: 4,
                                              offset: Offset(2, 3),
                                            )],
                                          ),
                                        ),
                                        SizedBox(height: r.sh(22)),
                                        _SubjectButton(
                                          label: 'MATH',
                                          iconPath: 'assets/icons/math.svg',
                                          color: const Color(0xFF4FC3F7),
                                          r: r, iconSize: 95, labelSize: 22,
                                          onTap: () => _goToLevelMap('MATH'),
                                        ),
                                        SizedBox(height: r.sh(12)),
                                        _SubjectButton(
                                          label: 'SCIENCE',
                                          iconPath: 'assets/icons/science.svg',
                                          color: const Color(0xFF81C784),
                                          r: r, iconSize: 100, labelSize: 22,
                                          onTap: () => _goToLevelMap('SCIENCE'),
                                        ),
                                        SizedBox(height: r.sh(12)),
                                        _SubjectButton(
                                          label: 'READING',
                                          iconPath: 'assets/icons/reading.svg',
                                          color: const Color(0xFFFFB74D),
                                          r: r, iconSize: 90, labelSize: 22,
                                          onTap: () => _goToLevelMap('READING'),
                                        ),
                                        SizedBox(height: r.sh(12)),
                                        _SubjectButton(
                                          label: 'WRITING',
                                          iconPath: 'assets/icons/writing.svg',
                                          color: const Color(0xFFFFCA28),
                                          r: r, iconSize: 100, labelSize: 22,
                                          onTap: () => _goToLevelMap('WRITING'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Close button
                                  Positioned(
                                    top: r.sh(12), right: r.sw(12),
                                    child: _TapIcon(
                                      onTap: _closePopup,
                                      child: SvgPicture.asset(
                                        'assets/icons/x.svg',
                                        width: r.s(38), height: r.s(38),
                                      ),
                                    ),
                                  ),
                                  // Spaceship — isolated RepaintBoundary
                                  Positioned(
                                    bottom: -r.sh(40), right: -r.sw(15),
                                    child: RepaintBoundary(
                                      child: AnimatedBuilder(
                                        animation: _shipCtrl,
                                        builder: (_, child) =>
                                            Transform.translate(
                                          offset: Offset(0, _shipBob.value),
                                          child: Transform.rotate(
                                            angle: _shipWiggle.value,
                                            child: child,
                                          ),
                                        ),
                                        child: Image.asset(
                                          'assets/themes/spaceship.png',
                                          width: r.sw(120),
                                          height: r.sw(120),
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const SizedBox.shrink(),
                                        ),
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
    final scaledIcon  = r.sw(iconSize);
    final scaledLabel = r.s(labelSize);
    final scaledBtnH  = r.sh(66);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: scaledBtnH,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r.sw(14)),
          boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 8,
            offset: const Offset(0, 5),
          )],
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
                  shadows: const [Shadow(
                    color: Colors.black38, blurRadius: 3, offset: Offset(1, 2),
                  )],
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

// ── Tap icon — press-to-scale feedback wrapper ────────────────
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
      vsync: this, duration: const Duration(milliseconds: 100));
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.80).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}