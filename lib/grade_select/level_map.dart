import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../screens/settings.dart'; // ← adjust path to match where settings.dart lives
import '../quiz_screen.dart';
import '../api_service.dart';
import '../widgets/mock_background.dart';

// ── Grade → planet image paths ────────────────────────────────
const _gradePlanets = {
  'PUNLA':  ['assets/themes/earth.png',   'assets/themes/mars.png',    'assets/themes/neptune.png'],
  'BINHI': ['assets/themes/earth.png',   'assets/themes/mars.png',    'assets/themes/neptune.png'],
  'COMING': ['assets/themes/earth.png',   'assets/themes/mars.png',    'assets/themes/neptune.png'],
};

// ── Grade → floating island image (moon / sun / star) ─────────
const _gradeIslands = {
  'PUNLA':  'assets/grade_select/moon.png',
  'BINHI':  'assets/grade_select/sun.png',
  'COMING': 'assets/grade_select/star.png',
};

// ── Subject → accent colour for label pill ────────────────────
const _subjectColors = {
  'MATH':    Color(0xFF4FC3F7),
  'SCIENCE': Color(0xFF81C784),
  'READING': Color(0xFFFFB74D),
  'WRITING': Color(0xFFFFCA28),
};

const _difficultyOrder = ['EASY', 'AVERAGE', 'HARD'];

// ════════════════════════════════════════════════════
// COORDINATES — tweak these to reposition anything
// All values are fractions of screen width (sw) or height (sh)
// ════════════════════════════════════════════════════

// ── Planets (center x, center y, radius) ─────────────────────
// CX: decrease = move LEFT,  increase = move RIGHT
// CY: decrease = move UP,    increase = move DOWN
// R:  decrease = smaller,    increase = bigger
const kEarthCX   = 0.77;
const kEarthCY   = 0.695;
const kEarthR    = 0.195;   // fraction of sw

const kMarsCX    = 0.28;
const kMarsCY    = 0.455;
const kMarsR     = 0.200;

const kNeptuneCX = 0.66;
const kNeptuneCY = 0.170;
const kNeptuneR  = 0.185;

// ── Nodes (x, y as fraction of sw/sh) ────────────────────────
// X: decrease = move LEFT,  increase = move RIGHT
// Y: decrease = move UP,    increase = move DOWN

// Top segment (above neptune): red, orange, green
const kN1X = 0.190; const kN1Y = 0.040;  // red
const kN2X = 0.490; const kN2Y = 0.070;  // orange
const kN3X = 0.775; const kN3Y = 0.062;  // green

// Middle segment (neptune → mars): red, orange, green
const kN4X = 0.835; const kN4Y = 0.290;  // red
const kN5X = 0.505; const kN5Y = 0.323;  // orange
const kN6X = 0.140; const kN6Y = 0.340;  // green

// Bottom segment (mars → earth): red, orange, green
const kN7X = 0.205; const kN7Y = 0.548;  // red
const kN8X = 0.315; const kN8Y = 0.615;  // orange
const kN9X = 0.590; const kN9Y = 0.608;  // green

// ── Gojo / sisa character ─────────────────────────────────────
const kGojoX    = 0.510;   // left edge — decrease = LEFT, increase = RIGHT
const kGojoY    = 0.520;   // top edge  — decrease = UP,   increase = DOWN
const kGojoSize = 0.18;    // fraction of sw

// ── Grade island (moon / sun / star) ─────────────────────────
const kIslandX    = 0.0;    // left edge
const kIslandY    = 0.680;  // top edge
const kIslandSize = 0.50;   // fraction of sw

// ── Label pill (PUNLA / MATH box) ────────────────────────────
const kLabelLeft   = 0.30;  // fraction of sw from left  — decrease = pill starts more LEFT
const kLabelRight  = 0.14;  // fraction of sw from right — decrease = pill stretches more RIGHT
const kLabelBottom = 0.05;  // increase = move UP, decrease = move DOWN (added on top of bar height)

// ── Bottom bar button sizes (pixels) ─────────────────────────
const kBackSize     = 50.0;
const kPlaySize     = 62.0;  // keep this the biggest
const kSettingsSize = 48.0;

// ── Dashed path waypoints ─────────────────────────────────────
// Points connect: top-left → neptune → mars → earth
// X: increase = move RIGHT, decrease = move LEFT
// Y: increase = move DOWN,  decrease = move UP
// Change in steps of 0.01–0.05 for fine-tuning
const kP1X  = 0.14; const kP1Y  = 0.010;  // top-left start
const kP2X  = 0.28; const kP2Y  = 0.100;  // curve right
const kP3X  = 0.88; const kP3Y  = 0.040;  // toward neptune
const kP4X  = 0.58; const kP4Y  = 0.130;  // enter neptune
const kP5X  = 0.97; const kP5Y  = 0.375;  // exit neptune bottom
const kP6X  = 0.35; const kP6Y  = 0.305;  // swing right
const kP7X  = 0.32; const kP7Y  = 0.300;  // back left
const kP8X  = 0.20; const kP8Y  = 0.300;  // heading to mars
const kP9X  = 0.10; const kP9Y  = 0.360;  // enter mars
const kP10X = 0.25; const kP10Y = 0.500;  // exit mars bottom
const kP11X = 0.10; const kP11Y = 0.660;  // small right
const kP12X = 0.40; const kP12Y = 0.605;  // curve toward earth
const kP13X = 0.55; const kP13Y = 0.605;  // approach earth
const kP14X = 0.75; const kP14Y = 0.655;  // enter earth

// ════════════════════════════════════════════════════

class LevelMapScreen extends StatefulWidget {
  final String grade;
  final String subject;
  final String gradeImg;

  const LevelMapScreen({
    super.key,
    required this.grade,
    required this.subject,
    required this.gradeImg,
  });

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen>
    with TickerProviderStateMixin {
  static const List<int> _nodeTravelOrder = [8, 7, 6, 5, 4, 3, 2, 1, 0];

  int _selectedDifficultyIndex = 0;
  int _selectedNodeIndex = 0;
  int _maxUnlockedDifficultyIndex = 0;
  bool _loadingProgress = false;
  bool _checkingCategoryContent = false;
  bool _categoryHasContent = true;
  bool _didShowNoContentDialog = false;
  static const double _swipeVelocityThreshold = 180.0;

  // Inline init guarantees fields are ready before build() is ever called

  // ── Gojo float animation ──────────────────────────────────
  late final AnimationController _gojoCtrl;
  late final Animation<double> _gojoAnim =
      Tween<double>(begin: -6, end: 6)
          .animate(CurvedAnimation(parent: _gojoCtrl, curve: Curves.easeInOut));

  // ── Island float animation ────────────────────────────────
  late final AnimationController _islandCtrl;
  late final Animation<double> _islandAnim =
      Tween<double>(begin: -5, end: 5)
          .animate(CurvedAnimation(parent: _islandCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();

    _gojoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _islandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);

    // Warm the first question payload while user is on the map.
    unawaited(
      ApiService.getQuestions(
        grade: widget.grade,
        subject: widget.subject,
      ).catchError((_) {
        return <Map<String, dynamic>>[];
      }),
    );

    unawaited(_loadProgressUnlocks());
    unawaited(_checkCategoryHasAnyContent());
  }

  @override
  void dispose() {
    _gojoCtrl.dispose();
    _islandCtrl.dispose();
    super.dispose();
  }

  // ── Navigate to settings ──────────────────────────────────
  void _goToSettings() {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, animation, _) => const SettingsScreen(),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  Future<void> _showLevelLockedDialog() async {
    if (!mounted) return;

    final unlockedLevel = _maxUnlockedNodeIndex() + 1;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Level Locked'),
        content: Text(
          'You are currently up to Level $unlockedLevel. '
          'Finish that level first to unlock the next one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showNoContentInCategoryDialog() async {
    if (!mounted || _didShowNoContentDialog) return;

    _didShowNoContentDialog = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nothing Here Yet'),
        content: Text(
          'We do not have activities for ${widget.grade} - ${widget.subject} yet. '
          'Please choose another subject for now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkCategoryHasAnyContent() async {
    if (widget.grade.toUpperCase() == 'COMING') {
      return;
    }

    setState(() {
      _checkingCategoryContent = true;
    });

    bool hasAnyContent = false;
    bool connectionOrServerIssue = false;

    try {
      final rows = await ApiService.getQuestions(
        grade: widget.grade,
        subject: widget.subject,
      );

      hasAnyContent = rows.isNotEmpty;
    } on ApiException catch (e) {
      if (e.statusCode == 404 || e.statusCode == 400) {
        hasAnyContent = false;
      } else {
        connectionOrServerIssue = true;
      }
    } catch (_) {
      connectionOrServerIssue = true;
    } finally {
      if (mounted) {
        setState(() {
          _checkingCategoryContent = false;
          _categoryHasContent = hasAnyContent || connectionOrServerIssue;
        });
      }
    }

    if (!hasAnyContent && !connectionOrServerIssue) {
      await _showNoContentInCategoryDialog();
    }
  }

  String _normalizeSubjectName(String value) {
    switch (value.trim().toUpperCase()) {
      case 'MATH':
      case 'MATHEMATICS':
        return 'MATHEMATICS';
      case 'SCIENCE':
        return 'SCIENCE';
      case 'READING':
      case 'WRITING':
      case 'ENGLISH':
        return 'ENGLISH';
      case 'FILIPINO':
        return 'FILIPINO';
      default:
        return value.trim().toUpperCase();
    }
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  bool _isPassedScore(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value > 0;
    final normalized = value?.toString().trim().toLowerCase();
    return normalized == '1' || normalized == 'true' || normalized == 'yes';
  }

  Future<void> _loadProgressUnlocks() async {
    final studentId = ApiService.currentStudentId;
    if (studentId == null || studentId <= 0) {
      return;
    }

    setState(() {
      _loadingProgress = true;
    });

    try {
      final progressRows = await ApiService.getProgress(studentId);
      if (!mounted) return;

      final targetGrade = widget.grade.trim().toUpperCase();
      final targetSubject = _normalizeSubjectName(widget.subject);
      int highestDiffPassed = 0;

      for (final row in progressRows) {
        final gradeName = (row['gradelvl'] ?? row['GRADELVL'] ?? '').toString().trim().toUpperCase();
        final subjectName = _normalizeSubjectName((row['subject'] ?? row['SUBJECT'] ?? '').toString());

        if (gradeName == targetGrade && subjectName == targetSubject) {
          highestDiffPassed = _toInt(row['highest_diff_passed'] ?? row['HIGHEST_DIFF_PASSED']);
          break;
        }
      }

      int passedAttempts = 0;
      bool scoreRowsLoaded = false;
      try {
        final scoreRows = await ApiService.getScores(studentId);
        scoreRowsLoaded = true;

        for (final row in scoreRows) {
          final gradeName = (row['gradelvl'] ?? row['GRADELVL'] ?? '')
              .toString()
              .trim()
              .toUpperCase();
          final subjectName = _normalizeSubjectName(
            (row['subject'] ?? row['SUBJECT'] ?? '').toString(),
          );

          if (gradeName == targetGrade &&
              subjectName == targetSubject &&
              _isPassedScore(row['passed'] ?? row['PASSED'])) {
            passedAttempts++;
          }
        }
      } catch (_) {
        // Fallback to highest difficulty when score history is unavailable.
      }

      int maxUnlockedNode = passedAttempts.clamp(0, _nodeTravelOrder.length - 1);
      if (!scoreRowsLoaded || (passedAttempts == 0 && highestDiffPassed > 0)) {
        final fromDiff = ((highestDiffPassed * 3) - 1)
            .clamp(0, _nodeTravelOrder.length - 1);
        if (fromDiff > maxUnlockedNode) {
          maxUnlockedNode = fromDiff;
        }
      }

      setState(() {
        _maxUnlockedDifficultyIndex = maxUnlockedNode;
        final maxNode = _maxUnlockedNodeIndex();
        if (_selectedNodeIndex > maxNode) {
          _selectedNodeIndex = maxNode;
        }
        _selectedDifficultyIndex = _difficultyIndexFromNode(_selectedNodeIndex);
      });
    } catch (_) {
      // Keep default unlocks when progress lookup fails.
    } finally {
      if (mounted) {
        setState(() {
          _loadingProgress = false;
        });
      }
    }
  }

  int _difficultyIndexFromNode(int nodeIndex) {
    return nodeIndex % _difficultyOrder.length;
  }

  int _maxUnlockedNodeIndex() {
    return _maxUnlockedDifficultyIndex.clamp(0, _nodeTravelOrder.length - 1);
  }

  Future<void> _updateSelectedNode(int nextNodeIndex) async {
    if (nextNodeIndex < 0 || nextNodeIndex >= _nodeTravelOrder.length) {
      return;
    }

    if (nextNodeIndex > _maxUnlockedNodeIndex()) {
      await _showLevelLockedDialog();
      return;
    }

    setState(() {
      _selectedNodeIndex = nextNodeIndex;
      _selectedDifficultyIndex = _difficultyIndexFromNode(nextNodeIndex);
    });
  }

  Future<void> _handleDifficultySwipe(double velocity) async {
    if (_loadingProgress) return;
    if (velocity.abs() < _swipeVelocityThreshold) return;

    if (velocity < 0) {
      await _updateSelectedNode(_selectedNodeIndex + 1);
    } else {
      await _updateSelectedNode(_selectedNodeIndex - 1);
    }
  }

  Future<void> _launchQuizForSelectedLevel() async {
    if (widget.grade.toUpperCase() == 'COMING') {
      return;
    }

    if (!_categoryHasContent || _checkingCategoryContent) {
      return;
    }

    final selectedDifficulty = _difficultyOrder[_selectedDifficultyIndex];

    if (!mounted) return;

    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, animation, _) => QuizScreen(
        difficulty: selectedDifficulty,
        grade: widget.grade,
        subject: widget.subject,
        gradeImg: widget.gradeImg,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));

    if (!mounted) return;
    await _loadProgressUnlocks();
  }

  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.of(context).size;
    final sw      = size.width;
    final sh      = size.height;
    final planets = _gradePlanets[widget.grade] ?? _gradePlanets['PUNLA']!;
    final island  = _gradeIslands[widget.grade]  ?? _gradeIslands['PUNLA']!;
    final accent  = _subjectColors[widget.subject] ?? const Color(0xFF4FC3F7);
    final barH    = sh * 0.09;

    // ── Apply coordinate constants → pixel values ─────────────
    final earthC   = Offset(sw * kEarthCX,   sh * kEarthCY);
    final marsC    = Offset(sw * kMarsCX,    sh * kMarsCY);
    final neptuneC = Offset(sw * kNeptuneCX, sh * kNeptuneCY);
    final earthR   = sw * kEarthR;
    final marsR    = sw * kMarsR;
    final neptuneR = sw * kNeptuneR;

    // ── Path waypoints ────────────────────────────────────────
    final pathPts = <Offset>[
      Offset(sw * kP1X,  sh * kP1Y),
      Offset(sw * kP2X,  sh * kP2Y),
      Offset(sw * kP3X,  sh * kP3Y),
      Offset(sw * kP4X,  sh * kP4Y),
      Offset(sw * kP5X,  sh * kP5Y),
      Offset(sw * kP6X,  sh * kP6Y),
      Offset(sw * kP7X,  sh * kP7Y),
      Offset(sw * kP8X,  sh * kP8Y),
      Offset(sw * kP9X,  sh * kP9Y),
      Offset(sw * kP10X, sh * kP10Y),
      Offset(sw * kP11X, sh * kP11Y),
      Offset(sw * kP12X, sh * kP12Y),
      Offset(sw * kP13X, sh * kP13Y),
      Offset(sw * kP14X, sh * kP14Y),
    ];

    // ── Node colours ──────────────────────────────────────────
    const r = Color(0xFFE53935);   // red
    const g = Color(0xFF43A047);   // green
    const o = Color(0xFFFF8C00);   // orange

    final nodes = <_Node>[
      // Top segment
      _Node(sw * kN1X, sh * kN1Y, r),
      _Node(sw * kN2X, sh * kN2Y, o),
      _Node(sw * kN3X, sh * kN3Y, g),
      // Middle segment
      _Node(sw * kN4X, sh * kN4Y, r),
      _Node(sw * kN5X, sh * kN5Y, o),
      _Node(sw * kN6X, sh * kN6Y, g),
      // Bottom segment
      _Node(sw * kN7X, sh * kN7Y, r),
      _Node(sw * kN8X, sh * kN8Y, o),
      _Node(sw * kN9X, sh * kN9Y, g),
    ];

    final travelNodes = _nodeTravelOrder
        .map((index) => nodes[index])
        .toList(growable: false);
    final selectedTravelNode = travelNodes[_selectedNodeIndex];
    final characterSize = sw * kGojoSize;
    final isComingSoonWorld = widget.grade.toUpperCase() == 'COMING';
    final isPlayDisabled = isComingSoonWorld || !_categoryHasContent || _checkingCategoryContent;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragEnd: (details) {
          final velocity = details.primaryVelocity;
          if (velocity == null) return;
          unawaited(_handleDifficultySwipe(velocity));
        },
        child: Stack(
        fit: StackFit.expand,
        children: [

          // 1. Background
          ValueListenableBuilder<String>(
            valueListenable: selectedThemeNotifier,
            builder: (context, theme, _) {
              final bgAsset = themeBackgrounds[theme] ?? themeBackgrounds['space']!;
              return Image.asset(
                bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: const Color(0xFF0D1B2E)),
              );
            },
          ),

          // 2. Dashed path — behind everything
          CustomPaint(
            size: size,
            painter: _PathPainter(points: pathPts),
          ),

          // 3. Nodes — behind planets
          ...nodes.map((n) => Positioned(
            left: n.x - 15,
            top:  n.y - 9,
            child: _NodeChip(color: n.color),
          )),

          // 4. Planets — on top of path & nodes
          _planetWidget(planets[2], neptuneC, neptuneR),  // neptune — top
          _planetWidget(planets[1], marsC,    marsR),     // mars    — middle
          _planetWidget(planets[0], earthC,   earthR),    // earth   — bottom

          // 5. Gojo / sisa character — floats between mars and earth
          AnimatedBuilder(
            animation: _gojoAnim,
            builder: (_, child) => Positioned(
              left: selectedTravelNode.x - (characterSize / 2),
              top: selectedTravelNode.y - (characterSize / 2) + _gojoAnim.value,
              child: child!,
            ),
            child: Image.asset(
              'assets/sisa_oyo/sisa_node.gif',
              width: characterSize,
              height: characterSize,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.person, color: Colors.white, size: 32),
            ),
          ),

          // 6. Label pill — drawn FIRST so island overlaps it
          Positioned(
            bottom: barH + sh * kLabelBottom,
            left:   sw * kLabelLeft,
            right:  sw * kLabelRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6, offset: const Offset(0, -2),
                )],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.grade,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'SuperCartoon', fontSize: 18,
                      color: Color(0xFF1A1A2E), letterSpacing: 2,
                    )),
                  Text(widget.subject,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SuperCartoon', fontSize: 16,
                      color: accent, letterSpacing: 2,
                    )),
                ],
              ),
            ),
          ),

          // 7. Grade island — drawn AFTER label so it appears ON TOP of the pill
          AnimatedBuilder(
            animation: _islandAnim,
            builder: (_, child) => Positioned(
              left: sw * kIslandX,
              top:  sh * kIslandY + _islandAnim.value,
              child: child!,
            ),
            child: Image.asset(
              island,
              width: sw * kIslandSize,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),

          // 8. Level chip at top
          Positioned(
            top: sh * 0.02,
            left: sw * 0.35,
            right: sw * 0.35,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                'LEVEL ${_selectedNodeIndex + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  color: isComingSoonWorld ? Colors.white54 : Colors.white,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: barH,
              color: const Color(0xFF0A0A18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ← Back
                  _TapIcon(
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: kBackSize, height: kBackSize,
                    ),
                  ),

                  // ▶ Play
                  IgnorePointer(
                    ignoring: isPlayDisabled,
                    child: Opacity(
                      opacity: isPlayDisabled ? 0.35 : 1,
                      child: _TapIcon(
                        onTap: _launchQuizForSelectedLevel,
                        child: SvgPicture.asset(
                          'assets/icons/play.svg',
                          width: kPlaySize, height: kPlaySize,
                        ),
                      ),
                    ),
                  ),

                  // ⚙ Settings
                  _TapIcon(
                    onTap: _goToSettings, // ← navigates to SettingsScreen
                    child: SvgPicture.asset(
                      'assets/icons/setting.svg',
                      width: kSettingsSize, height: kSettingsSize,
                    ),
                  ),

                ],
              ),
            ),
          ),

        ],
      ),
      ),
    );
  }

  // ── Planet widget helper ──────────────────────────────────
  Widget _planetWidget(String img, Offset center, double r) {
    return Positioned(
      left: center.dx - r,
      top:  center.dy - r,
      child: Image.asset(
        img, width: r * 2, height: r * 2,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ── Node data model ───────────────────────────────────────────
class _Node {
  final double x, y;
  final Color color;
  const _Node(this.x, this.y, this.color);
}

// ── Node chip widget (coloured pill on the path) ──────────────
class _NodeChip extends StatelessWidget {
  final Color color;
  const _NodeChip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.7),
          blurRadius: 7, offset: const Offset(0, 3),
        )],
      ),
    );
  }
}

// ── Dashed path painter ───────────────────────────────────────
// Draws a smooth bezier curve through all pathPts as a dashed line
class _PathPainter extends CustomPainter {
  final List<Offset> points;
  const _PathPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.82)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Build smooth bezier curve through all points
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final c = points[i];
      final n = points[i + 1];
      path.quadraticBezierTo(c.dx, c.dy, (c.dx + n.dx) / 2, (c.dy + n.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);

    // Draw as dashes
    const dash = 13.0, gap = 9.0;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + dash).clamp(0.0, m.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter o) => false;
}

// ── Tap icon — press-to-scale feedback wrapper ────────────────
class _TapIcon extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapIcon({required this.child, required this.onTap});
  @override State<_TapIcon> createState() => _TapIconState();
}

class _TapIconState extends State<_TapIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _s = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}