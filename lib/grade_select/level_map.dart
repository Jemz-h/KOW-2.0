import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../break_time_policy.dart';
import '../screens/settings.dart';
import '../quiz_screen.dart';
import '../api_service.dart';
import '../level_progression.dart';
import '../local_sync_store.dart';
import '../widgets/backend_feedback.dart';
import '../widgets/break_time.dart';
import '../widgets/mock_background.dart';
import '../writing_activity.dart';

const bool _debugShowBreakTimeOnEveryNextLevel = true;

const _gradePlanets = {
  'PUNLA': [
    'assets/themes/earth.png',
    'assets/themes/mars.png',
    'assets/themes/neptune.png',
  ],
  'BINHI': [
    'assets/themes/earth.png',
    'assets/themes/mars.png',
    'assets/themes/neptune.png',
  ],
  'COMING': [
    'assets/themes/earth.png',
    'assets/themes/mars.png',
    'assets/themes/neptune.png',
  ],
};

const _subjectColors = {
  'MATH': Color(0xFF4FC3F7),
  'SCIENCE': Color(0xFF81C784),
  'READING': Color(0xFFFFB74D),
  'WRITING': Color(0xFFFFCA28),
};

const _difficultyOrder = LevelProgression.nodeDifficultyOrder;

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

int _gradeIndexFromName(String grade) {
  switch (grade.toUpperCase()) {
    case 'PUNLA':
      return 0;
    case 'BINHI':
      return 1;
    case 'COMING':
      return 2;
    default:
      return 0;
  }
}


const kEarthCX = 0.77;
const kEarthCY = 0.695;
const kEarthR = 0.195;

const kMarsCX = 0.28;
const kMarsCY = 0.455;
const kMarsR = 0.200;

const kNeptuneCX = 0.66;
const kNeptuneCY = 0.170;
const kNeptuneR = 0.185;


const kN1X = 0.190;
const kN1Y = 0.040;
const kN2X = 0.490;
const kN2Y = 0.070;
const kN3X = 0.775;
const kN3Y = 0.062;

const kN4X = 0.835;
const kN4Y = 0.290;
const kN5X = 0.505;
const kN5Y = 0.323;
const kN6X = 0.140;
const kN6Y = 0.340;

const kN7X = 0.205;
const kN7Y = 0.548;
const kN8X = 0.315;
const kN8Y = 0.615;
const kN9X = 0.590;
const kN9Y = 0.608;

const kGojoX = 0.510; ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â decrease = LEFT, increase = RIGHT
const kGojoY = 0.520;  ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â decrease = UP,   increase = DOWN
const kGojoSize = 0.18;

const kIslandX = 0.0;
const kIslandY = 0.680;
const kIslandSize = 0.50;

const kLabelLeft =
    0.30; from left  ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â decrease = pill starts more LEFT
const kLabelRight =
    0.14; from right ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â decrease = pill stretches more RIGHT
const kLabelBottom =
    0.05;

const kBackSize = 50.0;
const kPlaySize = 62.0;
const kSettingsSize = 48.0;

const kP1X = 0.14;
const kP1Y = 0.010;
const kP2X = 0.28;
const kP2Y = 0.100;
const kP3X = 0.88;
const kP3Y = 0.040;
const kP4X = 0.58;
const kP4Y = 0.130;
const kP5X = 0.97;
const kP5Y = 0.375;
const kP6X = 0.35;
const kP6Y = 0.305;
const kP7X = 0.32;
const kP7Y = 0.300;
const kP8X = 0.20;
const kP8Y = 0.300;
const kP9X = 0.10;
const kP9Y = 0.360;
const kP10X = 0.25;
const kP10Y = 0.500;
const kP11X = 0.10;
const kP11Y = 0.660;
const kP12X = 0.40;
const kP12Y = 0.605;
const kP13X = 0.55;
const kP13Y = 0.605;
const kP14X = 0.75;
const kP14Y = 0.655;


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

  late final AnimationController _nodeSlideCtrl;
  late Animation<Offset> _nodeSlideAnim;

  int _selectedDifficultyIndex = 0;
  int _selectedNodeIndex = 0;
  int _maxUnlockedTravelNodeIndex = 0;
  bool _loadingProgress = false;
  bool _checkingCategoryContent = false;
  bool _categoryHasContent = true;
  bool _didShowNoContentDialog = false;
  static const double _swipeVelocityThreshold = 180.0;


  late final AnimationController _gojoCtrl;
  late final Animation<double> _gojoAnim = Tween<double>(
    begin: -6,
    end: 6,
  ).animate(CurvedAnimation(parent: _gojoCtrl, curve: Curves.easeInOut));

  late final AnimationController _islandCtrl;
  late final Animation<double> _islandAnim = Tween<double>(
    begin: -5,
    end: 5,
  ).animate(CurvedAnimation(parent: _islandCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();

    _nodeSlideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _gojoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _islandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);

    if (!isWritingSubject(widget.subject)) {
      unawaited(
        ApiService.getQuestions(
          grade: widget.grade,
          subject: widget.subject,
        ).catchError((_) {
          return <Map<String, dynamic>>[];
        }),
      );
    }

    unawaited(_loadProgressUnlocks());
    unawaited(_checkCategoryHasAnyContent());
  }

  @override
  void dispose() {
    _nodeSlideCtrl.dispose();
    _gojoCtrl.dispose();
    _islandCtrl.dispose();
    super.dispose();
  }

  void _goToSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => const SettingsScreen(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _showLevelLockedDialog() async {
    if (!mounted) return;

    final unlockedLevel = _maxUnlockedNodeIndex() + 1;
    await BackendFeedbackOverlay.showMessage(
      context: context,
      title: 'Level Locked',
      tone: BackendFeedbackTone.warning,
      message:
          'Sisa is currently up to Level $unlockedLevel. Finish that slab first to unlock the next path.',
    );
  }

  Future<void> _showNoContentInCategoryDialog() async {
    if (!mounted || _didShowNoContentDialog) return;

    _didShowNoContentDialog = true;
    await BackendFeedbackOverlay.showMessage(
      context: context,
      title: 'Nothing Here Yet',
      tone: BackendFeedbackTone.warning,
      message:
          'No activities are ready for ${widget.grade} - ${widget.subject} yet. Try another subject for now.',
    );
  }

  Future<void> _showMissingLevelDialog(int levelNumber) async {
    if (!mounted) return;

    await BackendFeedbackOverlay.showMessage(
      context: context,
      title: 'Level $levelNumber Unavailable',
      tone: BackendFeedbackTone.warning,
      message:
          'That slab has no questions yet. Sync updates or choose another level while new questions are prepared.',
    );
  }

  Future<void> _showMapCompleteDialog() async {
    if (!mounted) return;

    await BackendFeedbackOverlay.showMessage(
      context: context,
      title: 'Map Complete',
      tone: BackendFeedbackTone.success,
      message:
          'Sisa reached the final ${widget.subject} slab for ${widget.grade}. Great adventure!',
    );
  }

  Future<void> _showNextLevelDialog(int nodeIndex) async {
    if (!mounted) return;

    final difficulty = LevelProgression.difficultyForNode(nodeIndex);
    if (isWritingSubject(widget.subject)) {
      final shouldPlay = await BackendFeedbackOverlay.showChoice(
        context: context,
        title: 'Level ${nodeIndex + 1} Unlocked',
        tone: BackendFeedbackTone.success,
        message:
            '${widget.grade} - Writing\n$difficulty slab\nUse the printed writing sheet, then record the outcome.',
        primaryLabel: 'Start Writing',
        secondaryLabel: 'Stay on Map',
        barrierDismissible: false,
      );

      if (shouldPlay == true && mounted) {
        await _launchQuizForSelectedLevel();
      }
      return;
    }

    final rows = await ApiService.getQuestions(
      grade: widget.grade,
      subject: widget.subject,
      difficulty: difficulty,
    );
    if (!mounted) return;

    final levelRows = LevelProgression.questionsForNode(
      rows: rows,
      nodeIndex: nodeIndex,
      difficulty: difficulty,
    );
    final questionCount = levelRows.length;
    if (questionCount == 0) {
      await BackendFeedbackOverlay.showMessage(
        context: context,
        title: 'Still Preparing',
        tone: BackendFeedbackTone.warning,
        message:
            'Level ${nodeIndex + 1} is unlocked, but it needs fresh questions before Sisa can play it.',
      );
      return;
    }

    final shouldPlay = await BackendFeedbackOverlay.showChoice(
      context: context,
      title: 'Level ${nodeIndex + 1} Unlocked',
      tone: BackendFeedbackTone.success,
      message:
          '${widget.grade} - ${widget.subject}\n$difficulty slab\n$questionCount questions are ready for Sisa.',
      primaryLabel: 'Play Next',
      secondaryLabel: 'Stay on Map',
      barrierDismissible: false,
    );

    if (shouldPlay == true && mounted) {
      await _launchQuizForSelectedLevel();
    }
  }

  Future<void> _checkCategoryHasAnyContent() async {
    if (widget.grade.toUpperCase() == 'COMING') {
      return;
    }

    setState(() {
      _checkingCategoryContent = true;
    });

    if (isWritingSubject(widget.subject)) {
      setState(() {
        _checkingCategoryContent = false;
        _categoryHasContent = true;
      });
      return;
    }

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
      case 'ENGLISH':
        return 'ENGLISH';
      case 'WRITING':
        return 'WRITING';
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

  Future<void> _loadProgressUnlocks() async {
    int? studentId = ApiService.currentStudentId;
    if (studentId == null) {
      final profile = await ApiService.getCurrentProfile();
      final profileId = profile?['student_id'];
      if (profileId is num) {
        studentId = profileId.toInt();
      }
    }

    if (studentId == null) {
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
        final gradeName = (row['gradelvl'] ?? row['GRADELVL'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        final subjectName = _normalizeSubjectName(
          (row['subject'] ?? row['SUBJECT'] ?? '').toString(),
        );

        if (gradeName == targetGrade && subjectName == targetSubject) {
          highestDiffPassed = _toInt(
            row['highest_diff_passed'] ?? row['HIGHEST_DIFF_PASSED'],
          );
          break;
        }
      }

      int completedAttempts = 0;
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

          final passed = _toInt(row['passed'] ?? row['PASSED']) == 1;
          if (gradeName == targetGrade &&
              subjectName == targetSubject &&
              passed) {
            completedAttempts++;
          }
        }
      } catch (_) {
      }

      int maxUnlockedNode = completedAttempts.clamp(
        0,
        _nodeTravelOrder.length - 1,
      );

      final localHighestNode = await LocalSyncStore.instance
          .getLocalLevelProgress(
            studentId: studentId,
            grade: targetGrade,
            subject: targetSubject,
          );
      if (localHighestNode != null && localHighestNode > maxUnlockedNode) {
        maxUnlockedNode = localHighestNode.clamp(
          0,
          _nodeTravelOrder.length - 1,
        );
      }

      if (!scoreRowsLoaded ||
          (completedAttempts == 0 && highestDiffPassed > 0)) {
        final fromDiff = highestDiffPassed.clamp(
          0,
          _nodeTravelOrder.length - 1,
        );
        if (fromDiff > maxUnlockedNode) {
          maxUnlockedNode = fromDiff;
        }
      }

      setState(() {
        _maxUnlockedTravelNodeIndex = maxUnlockedNode;
        final maxNode = _maxUnlockedNodeIndex();
        _selectedNodeIndex = LevelProgression.currentNodeForLearner(
          selectedNodeIndex: _selectedNodeIndex,
          maxUnlockedNodeIndex: maxNode,
        );
        _selectedDifficultyIndex = _difficultyIndexFromNode(_selectedNodeIndex);
      });
    } catch (_) {
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
    return _maxUnlockedTravelNodeIndex.clamp(0, _nodeTravelOrder.length - 1);
  }

  Future<void> _updateSelectedNode(int nextNodeIndex) async {
    if (nextNodeIndex < 0 || nextNodeIndex >= _nodeTravelOrder.length) {
      return;
    }

    if (nextNodeIndex > _maxUnlockedNodeIndex()) {
      await _showLevelLockedDialog();
      return;
    }

    final travelNodes = _nodeTravelOrder
        .map(
          (index) => _Node(
            MediaQuery.of(context).size.width *
                [kN1X, kN2X, kN3X, kN4X, kN5X, kN6X, kN7X, kN8X, kN9X][index],
            MediaQuery.of(context).size.height *
                [kN1Y, kN2Y, kN3Y, kN4Y, kN5Y, kN6Y, kN7Y, kN8Y, kN9Y][index],
            Colors.white,
          ),
        )
        .toList();

    final current = travelNodes[_selectedNodeIndex];
    final next = travelNodes[nextNodeIndex];

    _nodeSlideAnim =
        Tween<Offset>(
          begin: Offset(current.x, current.y),
          end: Offset(next.x, next.y),
        ).animate(
          CurvedAnimation(parent: _nodeSlideCtrl, curve: Curves.easeOutCubic),
        );

    setState(() {
      _selectedNodeIndex = nextNodeIndex;
      _selectedDifficultyIndex = _difficultyIndexFromNode(nextNodeIndex);
    });

    await _nodeSlideCtrl.forward(from: 0);
  }

  Future<void> _handleDifficultySwipe(double velocity) async {
    if (_loadingProgress) return;
    if (velocity.abs() < _swipeVelocityThreshold) return;

    if (velocity > 0) {
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

    if (!isWritingSubject(widget.subject)) {
      final rows = await ApiService.getQuestions(
        grade: widget.grade,
        subject: widget.subject,
        difficulty: selectedDifficulty,
      );
      if (!mounted) return;

      final levelNumber = _selectedNodeIndex + 1;
      final levelRows = LevelProgression.questionsForNode(
        rows: rows,
        nodeIndex: _selectedNodeIndex,
        difficulty: selectedDifficulty,
      );

      if (levelRows.isEmpty) {
        await _showMissingLevelDialog(levelNumber);
        return;
      }
    }

    if (!mounted) return;

    final result = await Navigator.of(context).push<QuizCompletionResult>(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => QuizScreen(
          difficulty: selectedDifficulty,
          grade: widget.grade,
          subject: widget.subject,
          gradeImg: widget.gradeImg,
          nodeIndex: _selectedNodeIndex,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );

    if (!mounted) return;
    await _loadProgressUnlocks();

    if (result == null || !result.passed) {
      return;
    }

    final nextNodeIndex = (result.completedNodeIndex + 1).clamp(
      0,
      _nodeTravelOrder.length - 1,
    );
    if (nextNodeIndex <= result.completedNodeIndex) {
      await _showMapCompleteDialog();
      return;
    }

    setState(() {
      if (nextNodeIndex > _maxUnlockedTravelNodeIndex) {
        _maxUnlockedTravelNodeIndex = nextNodeIndex;
      }
    });

    await _updateSelectedNode(nextNodeIndex);
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;

    if (_debugShowBreakTimeOnEveryNextLevel ||
        BreakTimePolicy.shouldShowAfterPassedLevel(result.completedNodeIndex)) {
      await showBreakTimePopup(context);
      if (!mounted) return;
    }

    await _showNextLevelDialog(nextNodeIndex);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final sw = size.width;
    final sh = size.height;
    final planets = _gradePlanets[widget.grade] ?? _gradePlanets['PUNLA']!;
    final accent = _subjectColors[widget.subject] ?? const Color(0xFF4FC3F7);
    final barH = sh * 0.09;

    final earthC = Offset(sw * kEarthCX, sh * kEarthCY);
    final marsC = Offset(sw * kMarsCX, sh * kMarsCY);
    final neptuneC = Offset(sw * kNeptuneCX, sh * kNeptuneCY);
    final earthR = sw * kEarthR;
    final marsR = sw * kMarsR;
    final neptuneR = sw * kNeptuneR;

    final pathPts = <Offset>[
      Offset(sw * kP1X, sh * kP1Y),
      Offset(sw * kP2X, sh * kP2Y),
      Offset(sw * kP3X, sh * kP3Y),
      Offset(sw * kP4X, sh * kP4Y),
      Offset(sw * kP5X, sh * kP5Y),
      Offset(sw * kP6X, sh * kP6Y),
      Offset(sw * kP7X, sh * kP7Y),
      Offset(sw * kP8X, sh * kP8Y),
      Offset(sw * kP9X, sh * kP9Y),
      Offset(sw * kP10X, sh * kP10Y),
      Offset(sw * kP11X, sh * kP11Y),
      Offset(sw * kP12X, sh * kP12Y),
      Offset(sw * kP13X, sh * kP13Y),
      Offset(sw * kP14X, sh * kP14Y),
    ];

    const r = Color(0xFFE53935);
    const g = Color(0xFF43A047);
    const o = Color(0xFFFF8C00);

    final nodes = <_Node>[
      _Node(sw * kN1X, sh * kN1Y, r),
      _Node(sw * kN2X, sh * kN2Y, o),
      _Node(sw * kN3X, sh * kN3Y, g),
      _Node(sw * kN4X, sh * kN4Y, r),
      _Node(sw * kN5X, sh * kN5Y, o),
      _Node(sw * kN6X, sh * kN6Y, g),
      _Node(sw * kN7X, sh * kN7Y, r),
      _Node(sw * kN8X, sh * kN8Y, o),
      _Node(sw * kN9X, sh * kN9Y, g),
    ];

    final isComingSoonWorld = widget.grade.toUpperCase() == 'COMING';
    final isPlayDisabled =
        isComingSoonWorld || !_categoryHasContent || _checkingCategoryContent;

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
            ValueListenableBuilder<String>(
              valueListenable: selectedThemeNotifier,
              builder: (context, theme, _) {
                final bgAsset =
                    themeBackgrounds[theme] ?? themeBackgrounds['space']!;
                return Image.asset(
                  bgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFF0D1B2E)),
                );
              },
            ),

            CustomPaint(
              size: size,
              painter: _PathPainter(points: pathPts),
            ),

            ...nodes.map(
              (n) => Positioned(
                left: n.x - 15,
                top: n.y - 9,
                child: _NodeChip(color: n.color),
              ),
            ),

            _planetWidget(planets[2], neptuneC, neptuneR),
            _planetWidget(planets[1], marsC, marsR),
            _planetWidget(planets[0], earthC, earthR),
            AnimatedBuilder(
              animation: Listenable.merge([_nodeSlideCtrl, _gojoAnim]),
              builder: (_, child) {
                final size = MediaQuery.of(context).size;
                final sw = size.width;
                final sh = size.height;

                final nodes = [
                  Offset(sw * kN1X, sh * kN1Y),
                  Offset(sw * kN2X, sh * kN2Y),
                  Offset(sw * kN3X, sh * kN3Y),
                  Offset(sw * kN4X, sh * kN4Y),
                  Offset(sw * kN5X, sh * kN5Y),
                  Offset(sw * kN6X, sh * kN6Y),
                  Offset(sw * kN7X, sh * kN7Y),
                  Offset(sw * kN8X, sh * kN8Y),
                  Offset(sw * kN9X, sh * kN9Y),
                ];

                final travelNodes = _nodeTravelOrder
                    .map((i) => nodes[i])
                    .toList();

                final selected = travelNodes[_selectedNodeIndex];

                final pos = _nodeSlideCtrl.isAnimating
                    ? _nodeSlideAnim.value
                    : selected;

                final characterSize = sw * kGojoSize;

                return Positioned(
                  left: pos.dx - (characterSize / 2),
                  top: pos.dy - (characterSize / 2) + _gojoAnim.value,
                  child: child!,
                );
              },
              child: Image.asset(
                'assets/sisa_oyo/sisa_node.gif',
                width: MediaQuery.of(context).size.width * kGojoSize,
                height: MediaQuery.of(context).size.width * kGojoSize,
                fit: BoxFit.contain,
              ),
            ),

            Positioned(
              bottom: barH + sh * kLabelBottom,
              left: sw * kLabelLeft,
              right: sw * kLabelRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.grade,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'SuperCartoon',
                        fontSize: 18,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      widget.subject,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SuperCartoon',
                        fontSize: 16,
                        color: accent,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _islandAnim,
              builder: (_, child) => Positioned(
                left: sw * kIslandX,
                top: sh * kIslandY + _islandAnim.value,
                child: child!,
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: selectedThemeNotifier,
                builder: (context, theme, child) => SvgPicture.asset(
                  _gradeAsset(_gradeIndexFromName(widget.grade), theme),
                  width: sw * kIslandSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: barH,
                color: const Color(0xFF0A0A18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _TapIcon(
                      onTap: () => Navigator.of(context).pop(),
                      child: SvgPicture.asset(
                        'assets/icons/back.svg',
                        width: kBackSize,
                        height: kBackSize,
                      ),
                    ),

                    IgnorePointer(
                      ignoring: isPlayDisabled,
                      child: Opacity(
                        opacity: isPlayDisabled ? 0.35 : 1,
                        child: _TapIcon(
                          onTap: _launchQuizForSelectedLevel,
                          child: SvgPicture.asset(
                            'assets/icons/play.svg',
                            width: kPlaySize,
                            height: kPlaySize,
                          ),
                        ),
                      ),
                    ),

                    _TapIcon(
                      onTap: _goToSettings,
                      child: SvgPicture.asset(
                        'assets/icons/setting.svg',
                        width: kSettingsSize,
                        height: kSettingsSize,
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

  Widget _planetWidget(String img, Offset center, double r) {
    return Positioned(
      left: center.dx - r,
      top: center.dy - r,
      child: Image.asset(img, width: r * 2, height: r * 2, fit: BoxFit.contain),
    );
  }
}

class _Node {
  final double x, y;
  final Color color;
  const _Node(this.x, this.y, this.color);
}

class _NodeChip extends StatelessWidget {
  final Color color;
  const _NodeChip({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

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

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final c = points[i];
      final n = points[i + 1];
      path.quadraticBezierTo(c.dx, c.dy, (c.dx + n.dx) / 2, (c.dy + n.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);

    const dash = 13.0, gap = 9.0;
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(
          m.extractPath(d, (d + dash).clamp(0.0, m.length)),
          paint,
        );
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter o) => false;
}

class _TapIcon extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapIcon({required this.child, required this.onTap});
  @override
  State<_TapIcon> createState() => _TapIconState();
}

class _TapIconState extends State<_TapIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _s = Tween<double>(
      begin: 1.0,
      end: 0.80,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _c.forward(),
    onTapUp: (_) {
      _c.reverse();
      widget.onTap();
    },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}
