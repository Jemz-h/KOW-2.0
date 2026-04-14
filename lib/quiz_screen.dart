import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'api_service.dart';
import 'grade_select/level_map.dart';

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║  LAYOUT & SIZE CONSTANTS                                                ║
// ║  Every value is a fraction of screen width (sw) or height (sh).        ║
// ║  INCREASE → bigger / further down / more space                         ║
// ║  DECREASE → smaller / further up / less space                          ║
// ╚══════════════════════════════════════════════════════════════════════════╝

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ SCREEN OUTER PADDING                                                    │
// └─────────────────────────────────────────────────────────────────────────┘
const double kScreenPadH = 0.090;
const double kScreenPadV = 0.000;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ HEADER BAR — ALL difficulties → #B6D5F0                                │
// │  EASY → green  AVERAGE → orange  HARD → red                           │
// └─────────────────────────────────────────────────────────────────────────┘
const double kHeaderH            = 0.063;
const double kHeaderRadius       = 0.00;
const double kHeaderExitSize     = 0.102;
const double kHeaderExitPadL     = 0.030;
const double kHeaderTitleFs      = 0.070;
const double kHeaderTitleOffsetX = 0.050;
const double kHeaderTitleLS      = 2.0;
const double kHeaderScoreFs      = 0.028;
const double kHeaderScorePadH    = 0.030;
const double kHeaderScorePadV    = 0.020;
const double kHeaderScoreMarR    = 0.020;
const double kHeaderScoreRad     = 0.040;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ QUESTION BOX — EASY                                                     │
// └─────────────────────────────────────────────────────────────────────────┘
const double kCardW      = 0.9;
const double kCardMinH   = 0.000;
const double kCardPadH   = 0.000;
const double kCardPadT   = 0.000;
const double kCardPadB   = 0.000;
const double kCardRadius = 0.050;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ QUESTION BOX — AVERAGE / HARD                                           │
// │  kCardAvgMinH → INCREASE to make card taller                           │
// └─────────────────────────────────────────────────────────────────────────┘
const double kCardAvgW      = 0.9;
const double kCardAvgMinH   = 0.280;
const double kCardAvgPadH   = 0.000;
const double kCardAvgPadT   = 0.000;
const double kCardAvgPadB   = 0.000;
const double kCardAvgRadius = 0.050;

const double kGapHeaderCard = 0.036;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ GREY PILL BAR ("QUESTION 1" row)                                        │
// └─────────────────────────────────────────────────────────────────────────┘
const double kPillMarL      = 0.010;
const double kPillMarR      = 0.010;
const double kPillMarT      = 0.002;
const double kPillPadH      = 0.040;
const double kPillPadV      = 0.008;
const double kPillRadius    = 0.050;
const double kPillLabelFs   = 0.042;
const double kMegaphoneSize = 0.099;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ IMAGE (Easy only)                                                       │
// └─────────────────────────────────────────────────────────────────────────┘
const double kImageSize = 0.550;
const double kImagePadT = 0.000;
const double kImagePadB = 0.000;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ DEFINITION TEXT (Average / Hard)                                        │
// └─────────────────────────────────────────────────────────────────────────┘
const double kDefPadH      = 0.060;
const double kDefPadT      = 0.036;
const double kDefFs        = 0.056;
const double kWordTypeFs   = 0.038;
const double kWordTypePadT = 0.006;
const double kWordTypePadB = 0.012;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ OUTSIDE PROMPT                                                          │
// └─────────────────────────────────────────────────────────────────────────┘
const double kGapCardPrompt = 0.016;
const double kPromptOutFs   = 0.044;
const double kPromptOutPadH = 0.020;
const double kGapPromptBtns = 0.012;
const double kGapCardBtns   = 0.016;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ ANSWER BUTTONS                                                          │
// └─────────────────────────────────────────────────────────────────────────┘
const double kBtnH       = 0.078;
const double kBtnRadius  = 0.030;
const double kBtnFs      = 0.058;
const double kBtnGapB    = 0.010;
const double kBtnBorderW = 1.5;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ SKIP BUTTON                                                             │
// └─────────────────────────────────────────────────────────────────────────┘
const double kSkipGapT       = 0.010;
const double kSkipPadH       = 0.050;
const double kSkipPadV       = 0.008;
const double kSkipRadius     = 0.060;
const double kSkipFs         = 0.040;
const double kSkipsLabelGapT = 0.007;
const double kSkipsLabelFs   = 0.026;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ IN-QUIZ RESULT CARD (Correct / Nice Try)                                │
// └─────────────────────────────────────────────────────────────────────────┘
const double kResultW         = 0.900;
const double kResultMinH      = 0.350;
const double kResultPadH      = 0.060;
const double kResultPadV      = 0.022;
const double kResultRadius    = 0.050;
const double kResultTitleFs   = 0.092;
const double kResultTitleLS   = 1.5;
const double kResultBodyFs    = 0.070;
const double kResultBodyGapT  = 0.002;
const double kFunFactLabelFs  = 0.092;
const double kFunFactLabelLS  = 1.5;
const double kFunFactGapT     = 0.020;
const double kFunFactBodyFs   = 0.070;
const double kFunFactBodyGapT = 0.002;
const double kContinuePadH    = 0.045;
const double kContinuePadV    = 0.005;
const double kContinueRadius  = 0.080;
const double kContinueFs      = 0.055;
const double kContinueGapT    = 0.036;
const double kContinueBorderW = 0.5;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ LEVEL COMPLETE POP-UP                                                   │
// │                                                                         │
// │ Card layout (matches design):                                           │
// │   • Dark gradient card (#0E0A43 → #2A87B0)                            │
// │   • Title "LEVEL COMPLETE!" gold outlined                               │
// │   • Grade "PERFECT!" / "GREAT!" / "GOOD JOB!" below                   │
// │   • "YOU SCORED  5/5" text row                                          │
// │   • Characters (owl left, chick right) + medal centered = same row     │
// │   • "REWARD" label below medal                                          │
// │   • 4 gradient buttons with SVG icons                                  │
// │                                                                         │
// │ kPopCardW        → card width (fraction of sw)   INCREASE → wider      │
// │ kPopCardRadius   → corner roundness                                     │
// │ kPopCardPadH     → inner horizontal padding                            │
// │ kPopCardPadVTop  → inner top padding                                   │
// │ kPopCardPadVBot  → inner bottom padding                                │
// │                                                                         │
// │ kPopTitleFs      → "LEVEL COMPLETE!" font size                         │
// │ kPopTitleLS      → letter spacing                                       │
// │ kPopGradeFs      → grade label font size                               │
// │ kPopGradeLS      → grade letter spacing                                │
// │ kPopGapTitleGrade → gap between title and grade                        │
// │                                                                         │
// │ kPopScoreLabelFs → "YOU SCORED" font size                              │
// │ kPopScoreNumFs   → "5/5" font size                                     │
// │ kPopGapGradeScore → gap between grade and score                        │
// │                                                                         │
// │ kPopMedalSize    → medal width & height  INCREASE → bigger             │
// │ kPopCharSize     → oyo / sisa size        INCREASE → bigger chars      │
// │ kPopCharRowGapT  → gap above char+medal row                            │
// │ kPopRewardFs     → "REWARD" label size                                 │
// │                                                                         │
// │ kPopBtnH         → button height                                       │
// │ kPopBtnRadius    → button corner roundness                             │
// │ kPopBtnFs        → label font size                                     │
// │ kPopBtnLS        → label letter spacing                                │
// │ kPopBtnIconSz    → SVG icon size                                       │
// │ kPopBtnGapIcon   → icon-to-label gap                                   │
// │ kPopBtnGapB      → gap between buttons                                 │
// │ kPopGapRewardBtns → gap between REWARD and first button                │
// │                                                                         │
// │ kPopSlideMs      → slide-in duration ms                                │
// └─────────────────────────────────────────────────────────────────────────┘

// ── POPUP CARD SHELL ─────────────────────────────────────────────────────────
const double kPopCardW       = 0.90;
const double kPopCardRadius  = 0.055;
const double kPopCardPadH    = 0.044;
const double kPopCardPadVTop = 0.022;
const double kPopCardPadVBot = 0.030;

// ── INNER GRADIENT BOX (dark #0E0A43→#2A87B0) ──────────────────────────────
const double kPopInnerPadH   = 0.000;
const double kPopInnerPadV   = 0.039;
const double kPopInnerRadius = 0.040;

// ── TITLE & GRADE ───────────────────────────────────────────────────────────
const double kPopTitleFs   = 0.056;
const double kPopTitleLS   = 1.5;
const double kPopGradeFs   = 0.046;
const double kPopGradeLS   = 2.5;
const double kPopGapTG     = 0.004;

// ── SCORE ───────────────────────────────────────────────────────────────────
const double kPopScoreLabelFs = 0.052;
const double kPopScoreLabelLS = 1.5;
const double kPopScoreNumFs   = 0.068;
const double kPopGapGS        = 0.010;

// ── CHARACTERS + MEDAL — SIZE & POSITION ────────────────────────────────────
//
// Each element (owl, medal, chick) has its own LEFT and RIGHT coordinate.
// They sit inside a Stack, so you can move them freely without affecting others.
//
// LEFT  = distance from the left edge of the inner box  → INCREASE moves RIGHT
// RIGHT = distance from the right edge of the inner box → INCREASE moves LEFT
//
// kPopCharStackH  ↕ height of the stack area — INCREASE if chars get clipped

const double kPopCharStackH = 0.320;

// OWL
const double kPopOwlW = 0.080;
const double kPopOwlH = 0.370;
const double kPopOwlL = 0.000;
const double kPopOwlR = 0.510;

// MEDAL
const double kPopMedalW = 0.000;
const double kPopMedalH = 0.300;
const double kPopMedalL = 0.000;
const double kPopMedalR = 0.000;

// CHICK
const double kPopChickW = 0.250;
const double kPopChickH = 0.300;
const double kPopChickL = 0.510;
const double kPopChickR = 0.010;

// REWARD
const double kPopRewardFs = 0.038;
const double kPopRewardLS = 3.0;

const double kPopGapSM = 0.006;

// ── POPUP CARD POSITION ──────────────────────────────────────────────────────
const double kPopCardAlignX = 0.0;
const double kPopCardAlignY = 0.0;
const double kPopCardOffX   = 0.0;
const double kPopCardOffY   = 0.0;

// ── BUTTONS ─────────────────────────────────────────────────────────────────
const double kPopBtnH            = 0.070;
const double kPopBtnRadius       = 0.028;
const double kPopBtnFs           = 0.056;
const double kPopBtnLS           = 1.5;
const double kPopBtnIconSz       = 0.095;
const double kPopBtnGapIcon      = 0.018;
const double kPopBtnGapB         = 0.010;
const double kPopGapMB           = 0.020;
// NEXT LEVEL icon position
const double kPopBtnNextIconL    = 0.030;
const double kPopBtnNextIconR    = 0.190;
// RESTART LEVEL icon position
const double kPopBtnRestartIconL = 0.030;
const double kPopBtnRestartIconR = 0.090;
// RETURN TO MAP icon position
const double kPopBtnMapIconL     = 0.030;
const double kPopBtnMapIconR     = 0.070;
// RETURN TO HOME icon position
const double kPopBtnHomeIconL    = 0.035;
const double kPopBtnHomeIconR    = 0.050;

// ── ANIMATION ───────────────────────────────────────────────────────────────
const int kPopSlideMs = 420;

// ┌─────────────────────────────────────────────────────────────────────────┐
// │ ICON / TAP ANIMATION                                                    │
// └─────────────────────────────────────────────────────────────────────────┘
const Duration kTapPressDur   = Duration(milliseconds: 90);
const double   kTapPressScale = 0.76;

// ════════════════════════════════════════════════════════════════════════════
// QUIZ DATA  —  5 questions per difficulty
// ════════════════════════════════════════════════════════════════════════════

class QuizQuestion {
  final String questionNumber;
  final String? imagePath;
  final String? prompt;
  final String? wordType;
  final String? subPrompt;
  final List<String> choices;
  final int correctIndex;
  final String funFact;

  const QuizQuestion({
    required this.questionNumber,
    this.imagePath,
    this.prompt,
    this.wordType,
    this.subPrompt,
    required this.choices,
    required this.correctIndex,
    required this.funFact,
  });
}

// ── EASY: 5 image questions ───────────────────────────────────────────────
final List<QuizQuestion> kEasyQuestions = [
  QuizQuestion(
    questionNumber: 'QUESTION 1',
    imagePath: '', // <- IMAGE FOR QUESTION
    prompt: "What's in the picture?",
    choices: ['', '', '', ''],
    correctIndex: 1, //<- CORRECT BUTTON INDICATOR
    funFact: '', // <= FUNFACT POP
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 2',
    imagePath: '',
    prompt: "What's in the picture?",
    choices: ['', '', '', ''],
    correctIndex: 1,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 3',
    imagePath: '',
    prompt: "What's in the picture?",
    choices: ['', '', '', ''],
    correctIndex: 2,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 4',
    imagePath: '',
    prompt: "What's in the picture?",
    choices: ['', '', '', ''],
    correctIndex: 1,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 5',
    imagePath: '',
    prompt: "What's in the picture?",
    choices: ['', '', '', ''],
    correctIndex: 3,
    funFact: '',
  ),
];

// ── AVERAGE: 5 definition questions ──────────────────────────────────────
final List<QuizQuestion> kAverageQuestions = [
  QuizQuestion(
    questionNumber: 'QUESTION 1',
    prompt: '', //<- TEXT QUESTION
    wordType: '', //,- TYPE OF WORD
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 0,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 2',
    prompt: '',
    wordType: '',
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 2,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 3',
    prompt: '',
    wordType: '',
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 2,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 4',
    prompt: '',
    wordType: '',
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 1,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 5',
    prompt: '',
    wordType: '',
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 2,
    funFact: '',
  ),
];

// ── HARD: 5 questions ─────────────────────────────────────────────────────
final List<QuizQuestion> kHardQuestions = [
  QuizQuestion(
    questionNumber: 'QUESTION 1',
    prompt: '',
    wordType: '',
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 1,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 2',
    prompt: '',
    wordType: '',
    subPrompt: 'What part of speech is\nbeing described?',
    choices: ['', '', '', ''],
    correctIndex: 2,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 3',
    prompt: '',
    wordType: '',
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 3,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 4',
    prompt: '',
    wordType: '',
    subPrompt: 'What literary device is\nbeing described?',
    choices: ['', '', '', ''],
    correctIndex: 1,
    funFact: '',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 5',
    prompt: '',
    wordType: '',
    subPrompt: 'What is the word described\nin the statement?',
    choices: ['', '', '', ''],
    correctIndex: 2,
    funFact: '',
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// ENTRY POINT
// Change difficulty: 'EASY' | 'AVERAGE' | 'HARD'
// ════════════════════════════════════════════════════════════════════════════
void main() => runApp(const QuizApp());

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const QuizScreen(difficulty: 'EASY'),
      );
}

// ════════════════════════════════════════════════════════════════════════════
// QUIZ SCREEN
// ════════════════════════════════════════════════════════════════════════════

class QuizScreen extends StatefulWidget {
  final String difficulty;
  // ── grade / subject / gradeImg are passed in from LevelMapScreen ─────────
  // so the RETURN TO MAP button can go back to the exact same map state
  final String grade;
  final String subject;
  final String gradeImg;

  const QuizScreen({
    super.key,
    required this.difficulty,
    this.grade    = 'PUNLA',
    this.subject  = 'READING',
    this.gradeImg = 'assets/grade_select/moon.png',
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {

  int  _qi            = 0;
  int  _score         = 0;
  int  _skipsLeft     = 3;
  int? _selectedIdx;
  bool _showResult    = false;
  bool _showDonePopup = false;
  bool _isSubmittingScore = false;
  bool _hasQuestionInteraction = false;
  List<QuizQuestion>? _remoteQuestions;
  String? _quizErrorMessage;
  late final DateTime _sessionStartedAt;

  late final AnimationController _fadeCtrl;

  // ── _qs returns API questions when available, otherwise local fallback ────
  List<QuizQuestion> get _qs {
    if (_remoteQuestions != null && _remoteQuestions!.isNotEmpty) {
      return _remoteQuestions!;
    }

    return _fallbackQuestions;
  }

  List<QuizQuestion> get _fallbackQuestions {
    switch (widget.difficulty) {
      case 'AVERAGE': return kAverageQuestions;
      case 'HARD':    return kHardQuestions;   // ← HARD now has its own 5 questions
      default:        return kEasyQuestions;
    }
  }

  QuizQuestion get _q   => _qs[_qi];
  bool get _isEasy      => widget.difficulty == 'EASY';
  bool get _isCorrect   => _selectedIdx == _q.correctIndex;
  String get _scoreText => 'Score: $_score/${_qs.length}';

  Color get _headerColor => const Color(0xFFB6D5F0);

  Color get _titleColor {
    switch (widget.difficulty) {
      case 'AVERAGE': return const Color.fromARGB(255, 228, 150, 60);
      case 'HARD':    return const Color.fromARGB(255, 204, 60, 58);
      default:        return const Color(0xFF22BB22);
    }
  }

  String? get _outsidePrompt {
    if (_isEasy) return _q.prompt;
    return _q.subPrompt;
  }

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    ApiService.beginLearningSession();
    _sessionStartedAt = DateTime.now();
    _loadQuestions();
  }

  @override
  void dispose() {
    ApiService.endLearningSession();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final rows = await ApiService.getQuestions(
        grade: widget.grade,
        subject: widget.subject,
        difficulty: widget.difficulty,
      );

      if (!mounted) return;

      // Keep quiz progression stable if user already started interacting.
      if (_hasQuestionInteraction || _qi > 0 || _showResult) {
        return;
      }

      if (rows.isEmpty) {
        setState(() {
          _quizErrorMessage = 'There are no questions available for this grade and subject yet. Please try another selection.';
          _remoteQuestions = const [];
        });
        return;
      }

      // Shuffle questions to prevent repetition
      final shuffledRows = List.from(rows);
      shuffledRows.shuffle();

      setState(() {
        _quizErrorMessage = null;
        _remoteQuestions = List.generate(shuffledRows.length, (index) {
          final row = shuffledRows[index];
          final choices = List<String>.from(row['choices'] as List<dynamic>);

          return QuizQuestion(
            questionNumber: 'QUESTION ${index + 1}',
            imagePath: null,
            prompt: (row['prompt'] as String?) ?? '',
            wordType: null,
            subPrompt: (row['prompt'] as String?) ?? '',
            choices: choices,
            correctIndex: (row['correctIndex'] as num?)?.toInt() ?? 0,
            funFact: (row['funFact'] as String?) ?? '',
          );
        });
      });
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 404) {
        setState(() {
          _quizErrorMessage = 'There are no questions available for this grade and subject yet. Please try another selection.';
          _remoteQuestions = const [];
        });
        return;
      }

      rethrow;
    } catch (_) {
      // Keep local fallback questions without interrupting gameplay.
    }
  }

  Future<void> _submitFinalScore() async {
    if (_isSubmittingScore) {
      return;
    }

    final studentId = ApiService.currentStudentId;
    if (studentId == null || studentId <= 0) {
      return;
    }

    _isSubmittingScore = true;
    try {
      final playedAt = DateTime.now().toIso8601String();
      await ApiService.submitScore(
        studentId: studentId,
        grade: widget.grade,
        subject: widget.subject,
        difficulty: widget.difficulty,
        score: _score,
        total: _qs.length,
        playedAt: playedAt,
      );

      final maxScore = _qs.isNotEmpty ? _qs.length : 1;
      final passed = (_score / maxScore) >= 0.7;
      final diffId = switch (widget.difficulty) {
        'EASY' => 1,
        'AVERAGE' => 2,
        'HARD' => 3,
        _ => null,
      };

      final timeSpentSeconds = DateTime.now().difference(_sessionStartedAt).inSeconds;

      await ApiService.saveProgress(
        studentId: studentId,
        grade: widget.grade,
        subject: widget.subject,
        highestDiffPassed: passed ? diffId : null,
        totalTimePlayed: timeSpentSeconds < 0 ? 0 : timeSpentSeconds,
        lastPlayedAt: playedAt,
      );
    } catch (_) {
      // Keep gameplay uninterrupted if score sync fails.
    } finally {
      _isSubmittingScore = false;
    }
  }

  // ── Game logic ────────────────────────────────────────────────────────────
  void _onAnswer(int idx) {
    if (_selectedIdx != null) return;
    setState(() {
      _hasQuestionInteraction = true;
      _selectedIdx = idx;
      if (idx == _q.correctIndex) _score++;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _showResult = true);
      _fadeCtrl.forward(from: 0);
    });
  }

  void _onSkip() {
    if (_skipsLeft <= 0 || _selectedIdx != null) return;
    setState(() {
      _hasQuestionInteraction = true;
      _skipsLeft--;
    });
    _advance();
  }

  void _onContinue() => _advance();

  // ── _advance: triggers Level Complete popup when last question is done ────
  // Works identically for EASY, AVERAGE, and HARD
  void _advance() {
    final next = _qi + 1;
    if (next < _qs.length) {
      setState(() {
        _qi          = next;
        _selectedIdx = null;
        _showResult  = false;
      });
      _fadeCtrl.reset();
    } else {
      _submitFinalScore();
      setState(() => _showDonePopup = true);  // ← popup fires for all difficulties
    }
  }

  // ── Button colors ─────────────────────────────────────────────────────────
  Color _btnBg(int idx) {
    if (_selectedIdx == null) return Colors.white;
    if (idx == _q.correctIndex) return const Color.fromARGB(255, 155, 231, 150);
    if (idx == _selectedIdx)    return const Color.fromARGB(255, 238, 187, 135);
    return Colors.white;
  }
  Color _btnText(int idx) {
    if (_selectedIdx == null)   return const Color(0xFF1A2340);
    if (idx == _q.correctIndex) return const Color(0xFF1A2340);
    if (idx == _selectedIdx)    return const Color(0xFF1A2340);
    return const Color(0xFF1A2340).withValues(alpha: 0.30);
  }
  Color _btnBorder(int idx) {
    if (_selectedIdx == null)   return const Color(0xFFDDDDDD);
    if (idx == _q.correctIndex) return const Color(0xFFA8E6A3);
    if (idx == _selectedIdx)    return const Color(0xFFFFD0A0);
    return const Color(0xFFDDDDDD);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    if (_quizErrorMessage != null) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/themes/bg_spc_w_cloud.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    Container(color: const Color(0xFF0D1B2E))),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.08),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.06,
                      vertical: sh * 0.04,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(sw * 0.05),
                      boxShadow: const [BoxShadow(
                        color: Colors.black26,
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      )],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_empty_rounded,
                            size: 64, color: Color(0xFF2A87B0)),
                        SizedBox(height: sh * 0.02),
                        const Text(
                          'No Questions Available',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                        SizedBox(height: sh * 0.015),
                        Text(
                          _quizErrorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: 18,
                            color: Color(0xFF444466),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: sh * 0.03),
                        ElevatedButton(
                          onPressed: () => Navigator.maybePop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A87B0),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.08,
                              vertical: sh * 0.015,
                            ),
                          ),
                          child: const Text('Go Back'),
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
    }

    final double cardW      = _isEasy ? kCardW      : kCardAvgW;
    final double cardMinH   = _isEasy ? kCardMinH   : kCardAvgMinH;
    final double cardPadH   = _isEasy ? kCardPadH   : kCardAvgPadH;
    final double cardPadT   = _isEasy ? kCardPadT   : kCardAvgPadT;
    final double cardPadB   = _isEasy ? kCardPadB   : kCardAvgPadB;
    final double cardRadius = _isEasy ? kCardRadius : kCardAvgRadius;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          Image.asset('assets/themes/bg_spc_w_cloud.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: const Color(0xFF0D1B2E))),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── HEADER ─────────────────────────────────────────────────
                Container(
                  height: sh * kHeaderH,
                  decoration: BoxDecoration(
                    color: _headerColor,
                    borderRadius: BorderRadius.circular(sw * kHeaderRadius),
                    boxShadow: [BoxShadow(
                        color: _headerColor.withValues(alpha: 0.50),
                        blurRadius: 6, offset: const Offset(0, 3))],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw * kHeaderExitPadL),
                    child: Row(children: [
                      _TapIcon(
                        onTap: () => Navigator.maybePop(context),
                        child: SvgPicture.asset('assets/icons/x.svg',
                          width: sw * kHeaderExitSize, height: sw * kHeaderExitSize,
                          errorBuilder: (_, _, _) => Icon(Icons.close,
                              color: Colors.white, size: sw * kHeaderExitSize)),
                      ),
                      Expanded(
                        child: Transform.translate(
                          offset: Offset(sw * kHeaderTitleOffsetX, 0),
                          child: Center(
                            child: Text(widget.difficulty,
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: sw * kHeaderTitleFs,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.normal,
                                color: _titleColor,
                                letterSpacing: kHeaderTitleLS,
                                shadows: const [Shadow(color: Colors.black26,
                                    blurRadius: 2, offset: Offset(1, 1))],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: sw * kHeaderScoreMarR),
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * kHeaderScorePadH,
                            vertical:   sw * kHeaderScorePadV),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2AABCC),
                          borderRadius: BorderRadius.circular(sw * kHeaderScoreRad),
                        ),
                        child: Text(_scoreText, style: TextStyle(
                          fontFamily: 'SuperCartoon', fontSize: sw * kHeaderScoreFs,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ]),
                  ),
                ),

                // ── CONTENT ───────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * kScreenPadH, vertical: sh * kScreenPadV),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        SizedBox(height: sh * kGapHeaderCard),

                        // Question card
                        Container(
                          width: sw * cardW,
                          constraints: BoxConstraints(minHeight: sh * cardMinH),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(sw * cardRadius),
                            boxShadow: const [BoxShadow(
                                color: Colors.black26, blurRadius: 10,
                                offset: Offset(0, 4))],
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                sw * cardPadH, sh * cardPadT,
                                sw * cardPadH, sh * cardPadB),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [

                                // Grey pill
                                Container(
                                  margin: EdgeInsets.fromLTRB(
                                      sw * kPillMarL, sh * kPillMarT,
                                      sw * kPillMarR, 0),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: sw * kPillPadH,
                                      vertical:   sh * kPillPadV),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(sw * kPillRadius),
                                  ),
                                  child: Stack(alignment: Alignment.center, children: [
                                    Center(child: Text(_q.questionNumber,
                                      style: TextStyle(fontFamily: 'SuperCartoon',
                                          fontSize: sw * kPillLabelFs,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF333344)))),
                                    Positioned(right: 0,
                                      child: _TapIcon(onTap: () {},
                                        child: SvgPicture.asset(
                                          'assets/icons/megaphone.svg',
                                          width: sw * kMegaphoneSize,
                                          height: sw * kMegaphoneSize,
                                          errorBuilder: (_, _, _) => Icon(
                                              Icons.volume_up,
                                              color: const Color(0xFF555566),
                                              size: sw * kMegaphoneSize)))),
                                  ]),
                                ),

                                if (_isEasy && _q.imagePath != null) ...[
                                  SizedBox(height: sh * kImagePadT),
                                  Image.asset(_q.imagePath!,
                                    width: sw * kImageSize, height: sw * kImageSize,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => Icon(Icons.image,
                                        color: Colors.grey, size: sw * kImageSize * 0.75)),
                                  SizedBox(height: sh * kImagePadB),
                                ],

                                if (!_isEasy && _q.prompt != null) ...[
                                  SizedBox(height: sh * kDefPadT),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: sw * kDefPadH),
                                    child: Text(_q.prompt!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontFamily: 'SuperCartoon',
                                          fontSize: sw * kDefFs, fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1A2340), height: 1.4)),
                                  ),
                                ],

                                if (!_isEasy && _q.wordType != null) ...[
                                  SizedBox(height: sh * kWordTypePadT),
                                  Text(_q.wordType!, style: TextStyle(
                                      fontFamily: 'SuperCartoon', fontSize: sw * kWordTypeFs,
                                      color: const Color(0xFF888888),
                                      fontStyle: FontStyle.normal)),
                                  SizedBox(height: sh * kWordTypePadB),
                                ],

                              ],
                            ),
                          ),
                        ),

                        // Outside prompt
                        if (_outsidePrompt != null && !_showResult) ...[
                          SizedBox(height: sh * kGapCardPrompt),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: sw * kPromptOutPadH),
                            child: Text(_outsidePrompt!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'SuperCartoon',
                                  fontSize: sw * kPromptOutFs, fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [Shadow(color: Colors.black38,
                                      blurRadius: 3, offset: Offset(1, 1))])),
                          ),
                          SizedBox(height: sh * kGapPromptBtns),
                        ] else
                          SizedBox(height: sh * kGapCardBtns),

                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            child: _showResult
                                ? _buildResultCard(sw, sh)
                                : _buildButtonsSection(sw, sh),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── LEVEL COMPLETE OVERLAY ─────────────────────────────────────
          // Fires for EASY, AVERAGE, and HARD — same popup for all
          if (_showDonePopup)
            _LevelCompletePopup(
              score:      _score,
              total:      _qs.length,
              difficulty: widget.difficulty,
              onNext: () {
                // EASY → AVERAGE → HARD → (stays on HARD, no further levels)
                final String nextDifficulty;
                if (widget.difficulty == 'EASY') {
                  nextDifficulty = 'AVERAGE';
                } else if (widget.difficulty == 'AVERAGE') {
                  nextDifficulty = 'HARD';
                }else{
                  nextDifficulty = 'HARD';
                }                                     

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizScreen(
                      difficulty: nextDifficulty,
                      grade: widget.grade,
                      subject: widget.subject,
                      gradeImg: widget.gradeImg,
                    ),
                  ),
                );
              },
              onRestart: () {
                setState(() {
                  _qi            = 0;
                  _score         = 0;
                  _skipsLeft     = 3;
                  _selectedIdx   = null;
                  _showResult    = false;
                  _showDonePopup = false;
                });
                _fadeCtrl.reset();
              },
              // ── RETURN TO MAP ──────────────────────────────────────────
              // Navigates back to LevelMapScreen passing the same grade,
              // subject and gradeImg that launched this quiz.
              onReturnMap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelMapScreen(
                      grade:    widget.grade,
                      subject:  widget.subject,
                      gradeImg: widget.gradeImg,
                    ),
                  ),
                );
              },
              onHome: () {
                // Add your own home navigation here
              },
            ),

        ],
      ),
    );
  }

  // ── Buttons section ───────────────────────────────────────────────────────
  Widget _buildButtonsSection(double sw, double sh) {
    return Column(
      key: const ValueKey('buttons'),
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ...List.generate(_q.choices.length, (idx) => Padding(
          padding: EdgeInsets.only(bottom: sh * kBtnGapB),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260), curve: Curves.easeOut,
            width: double.infinity, height: sh * kBtnH,
            decoration: BoxDecoration(
              color: _btnBg(idx),
              borderRadius: BorderRadius.circular(sw * kBtnRadius),
              border: Border.all(color: _btnBorder(idx), width: kBtnBorderW),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Material(color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(sw * kBtnRadius),
                onTap: _selectedIdx == null ? () => _onAnswer(idx) : null,
                child: Center(child: Text(_q.choices[idx], style: TextStyle(
                  fontFamily: 'SuperCartoon', fontSize: sw * kBtnFs,
                  fontWeight: FontWeight.bold, color: _btnText(idx)))),
              )),
          ),
        )),
        SizedBox(height: sh * kSkipGapT),
        Center(child: _SkipButton(
          skipsLeft: _skipsLeft, disabled: _selectedIdx != null,
          padH: sw * kSkipPadH, padV: sh * kSkipPadV,
          radius: sw * kSkipRadius, fontSize: sw * kSkipFs, onTap: _onSkip,
        )),
        SizedBox(height: sh * kSkipsLabelGapT),
        Center(child: Text('Available Skips: $_skipsLeft', style: TextStyle(
          fontFamily: 'SuperCartoon', fontSize: sw * kSkipsLabelFs,
          color: Colors.white70))),
      ],
    );
  }

  // ── In-quiz result card ───────────────────────────────────────────────────
  Widget _buildResultCard(double sw, double sh) {
    final correctWord = _q.choices[_q.correctIndex];
    final resultColor = _isCorrect
        ? const Color(0xFF66CC66) : const Color(0xFFBB77EE);
    const funFactColor = Color(0xFF44CCEE);

    Widget outlinedTitle(String t, Color fill, double fs, double ls) {
      const oc = Colors.black; const ow = 1.0;
      final base = TextStyle(fontFamily: 'SuperCartoon', fontSize: fs,
          fontWeight: FontWeight.bold, fontStyle: FontStyle.normal, letterSpacing: ls);
      return Stack(alignment: Alignment.center, children: [
        Text(t, textAlign: TextAlign.center, style: base.copyWith(color: oc, shadows: [
          Shadow(color: oc, blurRadius: 0, offset: const Offset(-ow, -ow)),
          Shadow(color: oc, blurRadius: 0, offset: const Offset( ow, -ow)),
          Shadow(color: oc, blurRadius: 0, offset: const Offset(-ow,  ow)),
          Shadow(color: oc, blurRadius: 0, offset: const Offset( ow,  ow)),
          Shadow(color: oc, blurRadius: 0, offset: const Offset( ow,  0)),
          Shadow(color: oc, blurRadius: 0, offset: const Offset(-ow,  0)),
          Shadow(color: oc, blurRadius: 0, offset: const Offset( 0,   ow)),
          Shadow(color: oc, blurRadius: 0, offset: const Offset( 0,  -ow)),
        ])),
        Text(t, textAlign: TextAlign.center, style: base.copyWith(color: fill)),
      ]);
    }

    return Container(
      key: const ValueKey('result'),
      width: sw * kResultW,
      constraints: BoxConstraints(minHeight: sh * kResultMinH),
      decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(sw * kResultRadius),
          boxShadow: const [BoxShadow(color: Colors.black26,
              blurRadius: 10, offset: Offset(0, 4))]),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(sw * kResultPadH, sh * kResultPadV,
            sw * kResultPadH, sh * kResultPadV),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          outlinedTitle(_isCorrect ? 'Correct!' : 'Nice Try!',
              resultColor, sw * kResultTitleFs, kResultTitleLS),
          SizedBox(height: sh * kResultBodyGapT),
          RichText(textAlign: TextAlign.center, text: TextSpan(
            style: TextStyle(fontFamily: 'SuperCartoon', fontSize: sw * kResultBodyFs,
                fontWeight: FontWeight.bold, color: const Color(0xFF1A2340), height: 1.5),
            children: _isEasy
                ? [const TextSpan(text: ''), //<- text for correct pop up eg. the image shown below is
                   TextSpan(text: correctWord, style: TextStyle(color: resultColor)),
                   const TextSpan(text: '.')] //<- highlighted answer
                : [const TextSpan(text: ''), // for nice try
                   TextSpan(text: correctWord, style: TextStyle(color: resultColor)),
                   const TextSpan(text: '.')], // same here
          )),
          SizedBox(height: sh * kFunFactGapT),
          outlinedTitle('Fun Fact!', funFactColor, sw * kFunFactLabelFs, kFunFactLabelLS),
          SizedBox(height: sh * kFunFactBodyGapT),
          Text(_q.funFact, textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'SuperCartoon', fontSize: sw * kFunFactBodyFs,
                fontWeight: FontWeight.bold, color: const Color(0xFF1A2340), height: 1.45)),
          SizedBox(height: sh * kContinueGapT),
          _ContinueButton(padH: sw * kContinuePadH, padV: sh * kContinuePadV,
              radius: sw * kContinueRadius, fontSize: sw * kContinueFs,
              borderWidth: kContinueBorderW, onTap: _onContinue),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LEVEL COMPLETE POP-UP
// ════════════════════════════════════════════════════════════════════════════

class _LevelCompletePopup extends StatefulWidget {
  final int score, total;
  final String difficulty;
  final VoidCallback onNext, onRestart, onReturnMap, onHome;

  const _LevelCompletePopup({
    required this.score, required this.total, required this.difficulty,
    required this.onNext, required this.onRestart,
    required this.onReturnMap, required this.onHome,
  });

  @override
  State<_LevelCompletePopup> createState() => _LevelCompletePopupState();
}

class _LevelCompletePopupState extends State<_LevelCompletePopup>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: kPopSlideMs),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _medal {
    if (widget.score == widget.total) return 'assets/icons/gold.svg';
    if (widget.score >= 3)            return 'assets/icons/silver.svg';
    return 'assets/icons/bronze.svg';
  }

  Color get _medalColor {
    if (widget.score == widget.total) return const Color(0xFFFFD700);
    if (widget.score >= 3)            return const Color(0xFFB8C8D8);
    return const Color(0xFFCD7F32);
  }

  String get _gradeLabel {
    if (widget.score == widget.total) return 'PERFECT!';
    if (widget.score >= 3)            return 'GREAT!';
    return 'GOOD JOB!';
  }

  Widget _outlined(String text, Color fill, double fs, double ls) {
    const oc = Colors.black; const ow = 1.5;
    final base = TextStyle(fontFamily: 'SuperCartoon', fontSize: fs,
        fontWeight: FontWeight.bold, fontStyle: FontStyle.normal, letterSpacing: ls);
    return Stack(alignment: Alignment.center, children: [
      Text(text, textAlign: TextAlign.center, style: base.copyWith(color: oc, shadows: [
        Shadow(color: oc, blurRadius: 0, offset: const Offset(-ow, -ow)),
        Shadow(color: oc, blurRadius: 0, offset: const Offset( ow, -ow)),
        Shadow(color: oc, blurRadius: 0, offset: const Offset(-ow,  ow)),
        Shadow(color: oc, blurRadius: 0, offset: const Offset( ow,  ow)),
        Shadow(color: oc, blurRadius: 0, offset: const Offset( ow,  0)),
        Shadow(color: oc, blurRadius: 0, offset: const Offset(-ow,  0)),
        Shadow(color: oc, blurRadius: 0, offset: const Offset( 0,   ow)),
        Shadow(color: oc, blurRadius: 0, offset: const Offset( 0,  -ow)),
      ])),
      Text(text, textAlign: TextAlign.center, style: base.copyWith(color: fill)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Positioned.fill(
      child: Stack(children: [

        Positioned.fill(
          child: Image.asset('assets/themes/bg_spc_w_cloud.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(color: const Color(0xFF0A1528))),
        ),

        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.52)),
        ),

        Align(
          alignment: Alignment(kPopCardAlignX, kPopCardAlignY),
          child: Transform.translate(
            offset: Offset(sw * kPopCardOffX, sh * kPopCardOffY),
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: sw * kPopCardW,
                  constraints: BoxConstraints(maxHeight: sh * 0.92),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 156, 224, 252),
                    borderRadius: BorderRadius.circular(sw * kPopCardRadius),
                    boxShadow: const [BoxShadow(
                        color: Colors.black54, blurRadius: 30,
                        offset: Offset(0, 8))],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      sw * kPopCardPadH,
                      sh * kPopCardPadVTop,
                      sw * kPopCardPadH,
                      sh * kPopCardPadVBot,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: sw * kPopInnerPadH,
                        vertical:   sh * kPopInnerPadV,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end:   Alignment.bottomRight,
                          stops: [0.26, 0.74],
                          colors: [Color.fromARGB(255, 70, 86, 129), Color.fromARGB(255, 64, 77, 110)],
                        ),
                        borderRadius: BorderRadius.circular(sw * kPopInnerRadius),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          _outlined('LEVEL COMPLETE!',
                              const Color(0xFFFFFF00),
                              sw * kPopTitleFs, kPopTitleLS),

                          SizedBox(height: sh * kPopGapTG),

                          _outlined(_gradeLabel,
                              _medalColor,
                              sw * kPopGradeFs, kPopGradeLS),

                          SizedBox(height: sh * kPopGapGS),

                          Text('YOU SCORED', style: TextStyle(
                            fontFamily:    'SuperCartoon',
                            fontSize:      sw * kPopScoreLabelFs,
                            fontWeight:    FontWeight.bold,
                            color:         Colors.white,
                            letterSpacing: kPopScoreLabelLS,
                          )),

                          Text('${widget.score}/${widget.total}',
                            style: TextStyle(
                              fontFamily: 'SuperCartoon',
                              fontSize:   sw * kPopScoreNumFs,
                              fontWeight: FontWeight.bold,
                              color:      Colors.white,
                            )),

                          SizedBox(height: sh * kPopGapSM),

                          SizedBox(
                            width:  double.infinity,
                            height: sw * kPopCharStackH,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [

                                // OWL — oyo.png
                                Positioned(
                                  left:   sw * kPopOwlL,
                                  right:  sw * kPopOwlR,
                                  bottom: 0,
                                  child: Image.asset(
                                    'assets/sisa_oyo/oyo.png',
                                    width:  sw * kPopOwlW,
                                    height: sw * kPopOwlH,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => SizedBox(
                                        width: sw * kPopOwlW, height: sw * kPopOwlH),
                                  ),
                                ),

                                // MEDAL + REWARD label
                                Positioned(
                                  left:   sw * kPopMedalL,
                                  right:  sw * kPopMedalR,
                                  bottom: 0,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        _medal,
                                        width:  sw * kPopMedalW,
                                        height: sw * kPopMedalH,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) =>
                                            Icon(Icons.star_rounded,
                                                color: _medalColor,
                                                size: sw * kPopMedalW),
                                      ),
                                      Text('REWARD', style: TextStyle(
                                        fontFamily:    'SuperCartoon',
                                        fontSize:      sw * kPopRewardFs,
                                        fontWeight:    FontWeight.bold,
                                        color:         Colors.white70,
                                        letterSpacing: kPopRewardLS,
                                      )),
                                    ],
                                  ),
                                ),

                                // CHICK — sisa.png
                                Positioned(
                                  left:   sw * kPopChickL,
                                  right:  sw * kPopChickR,
                                  bottom: 0,
                                  child: Image.asset(
                                    'assets/sisa_oyo/sisa.png',
                                    width:  sw * kPopChickW,
                                    height: sw * kPopChickH,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, _, _) => SizedBox(
                                        width: sw * kPopChickW, height: sw * kPopChickH),
                                  ),
                                ),

                              ],
                            ),
                          ),

                        ],
                      ),
                    ),

                    SizedBox(height: sh * kPopGapMB),

                    _PopButton(
                      label:        'NEXT LEVEL',
                      iconPath:     'assets/icons/nextbtn.svg',
                      fallbackIcon: Icons.arrow_forward_rounded,
                      iconLeft:     kPopBtnNextIconL,
                      iconRight:    kPopBtnNextIconR,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                        stops: [0.26, 0.74],
                        colors: [Color(0xFF0E0A43), Color(0xFF2A87B0)],
                      ),
                      sw: sw, sh: sh, onTap: widget.onNext,
                    ),

                    SizedBox(height: sh * kPopBtnGapB),

                    _PopButton(
                      label:        'RESTART LEVEL',
                      iconPath:     'assets/icons/restart.svg',
                      fallbackIcon: Icons.refresh_rounded,
                      iconLeft:     kPopBtnRestartIconL,
                      iconRight:    kPopBtnRestartIconR,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                        stops: [0.26, 0.74],
                        colors: [Color(0xFF28043A), Color(0xFF945BC9)],
                      ),
                      sw: sw, sh: sh, onTap: widget.onRestart,
                    ),

                    SizedBox(height: sh * kPopBtnGapB),

                    _PopButton(
                      label:        'RETURN TO MAP',
                      iconPath:     'assets/icons/returnbtn.svg',
                      fallbackIcon: Icons.arrow_back_rounded,
                      iconLeft:     kPopBtnMapIconL,
                      iconRight:    kPopBtnMapIconR,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                        stops: [0.26, 0.74],
                        colors: [Color(0xFF282E2D), Color(0xFF747D80)],
                      ),
                      sw: sw, sh: sh, onTap: widget.onReturnMap,
                    ),

                    SizedBox(height: sh * kPopBtnGapB),

                    _PopButton(
                      label:        'RETURN TO HOME',
                      iconPath:     'assets/icons/home.svg',
                      fallbackIcon: Icons.home_rounded,
                      iconLeft:     kPopBtnHomeIconL,
                      iconRight:    kPopBtnHomeIconR,
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft, end: Alignment.centerRight,
                        stops: [0.26, 0.74],
                        colors: [Color(0xFF8D291D), Color(0xFFC9817A)],
                      ),
                      sw: sw, sh: sh, onTap: widget.onHome,
                    ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _PopButton
// ════════════════════════════════════════════════════════════════════════════

class _PopButton extends StatefulWidget {
  final String         label;
  final String         iconPath;
  final IconData       fallbackIcon;
  final double         iconLeft;
  final double         iconRight;
  final LinearGradient gradient;
  final double         sw, sh;
  final VoidCallback   onTap;

  const _PopButton({
    required this.label,
    required this.iconPath,
    required this.fallbackIcon,
    required this.iconLeft,
    required this.iconRight,
    required this.gradient,
    required this.sw,
    required this.sh,
    required this.onTap,
  });

  @override
  State<_PopButton> createState() => _PopButtonState();
}

class _PopButtonState extends State<_PopButton>
    with SingleTickerProviderStateMixin {

  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: kTapPressDur);
    _scale = Tween<double>(begin: 1.0, end: kTapPressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final sh = widget.sh;
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: ()  { _ctrl.reverse(); },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width:  double.infinity,
            height: sh * kPopBtnH,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(sw * kPopBtnRadius),
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.30),
                  blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left:  sw * widget.iconLeft,
                    right: sw * widget.iconRight,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                            Colors.white, BlendMode.srcIn),
                        child: SvgPicture.asset(
                          widget.iconPath,
                          width:  sw * kPopBtnIconSz,
                          height: sw * kPopBtnIconSz,
                          errorBuilder: (_, _, _) => Icon(
                              widget.fallbackIcon,
                              color: Colors.white,
                              size:  sw * kPopBtnIconSz),
                        ),
                      ),

                      SizedBox(width: sw * kPopBtnGapIcon),

                      Text(widget.label, style: TextStyle(
                        fontFamily:    'SuperCartoon',
                        fontSize:      sw * kPopBtnFs,
                        fontWeight:    FontWeight.bold,
                        color:         Colors.white,
                        letterSpacing: kPopBtnLS,
                        shadows: const [Shadow(color: Colors.black26,
                            blurRadius: 2, offset: Offset(1, 1))],
                      )),

                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _SkipButton
// ════════════════════════════════════════════════════════════════════════════

class _SkipButton extends StatefulWidget {
  final int skipsLeft; final bool disabled;
  final double padH, padV, radius, fontSize;
  final VoidCallback onTap;
  const _SkipButton({
    required this.skipsLeft, required this.disabled,
    required this.padH, required this.padV,
    required this.radius, required this.fontSize, required this.onTap,
  });
  @override State<_SkipButton> createState() => _SkipButtonState();
}

class _SkipButtonState extends State<_SkipButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: kTapPressDur);
    _scale = Tween<double>(begin: 1.0, end: kTapPressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _color = ColorTween(
      begin: const Color(0xFFB6D5F0),
      end: const Color(0xFF8BBFE8),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  bool get _canSkip => widget.skipsLeft > 0 && !widget.disabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) { if (_canSkip) _ctrl.forward(); },
    onTapUp:     (_) { if (_canSkip) { _ctrl.reverse(); widget.onTap(); } },
    onTapCancel: ()  { _ctrl.reverse(); },
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Transform.scale(
        scale: _canSkip ? _scale.value : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: widget.padH, vertical: widget.padV),
          decoration: BoxDecoration(
            color: _canSkip
                ? (_color.value ?? const Color(0xFFB6D5F0))
                : const Color(0xFF888888),
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text('Skip Question ▶', style: TextStyle(
            fontFamily: 'SuperCartoon', fontSize: widget.fontSize,
            fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 26, 35, 64))),
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// _ContinueButton
// ════════════════════════════════════════════════════════════════════════════

class _ContinueButton extends StatefulWidget {
  final double padH, padV, radius, fontSize, borderWidth;
  final VoidCallback onTap;
  const _ContinueButton({
    required this.padH, required this.padV, required this.radius,
    required this.fontSize, required this.borderWidth, required this.onTap,
  });
  @override State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: kTapPressDur);
    _scale = Tween<double>(begin: 1.0, end: kTapPressScale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _color = ColorTween(
      begin: const Color.fromARGB(255, 117, 240, 117),
      end: const Color.fromARGB(255, 147, 199, 147),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _ctrl.forward(),
    onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: ()  { _ctrl.reverse(); },
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Transform.scale(
        scale: _scale.value,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: widget.padH, vertical: widget.padV),
          decoration: BoxDecoration(
            color: _color.value ?? Colors.white,
            border: Border.all(color: Colors.black, width: widget.borderWidth),
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text('Continue', style: TextStyle(
            fontFamily: 'SuperCartoon', fontSize: widget.fontSize,
            fontWeight: FontWeight.bold, color: Colors.black, letterSpacing: 1)),
        ),
      ),
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// _TapIcon
// ════════════════════════════════════════════════════════════════════════════

class _TapIcon extends StatefulWidget {
  final Widget child; final VoidCallback onTap;
  const _TapIcon({required this.child, required this.onTap});
  @override State<_TapIcon> createState() => _TapIconState();
}

class _TapIconState extends State<_TapIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: kTapPressDur);
    _s = Tween<double>(begin: 1.0, end: kTapPressScale).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: ()  => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}