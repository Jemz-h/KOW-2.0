import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ════════════════════════════════════════════════════
// QUIZ DATA
// ════════════════════════════════════════════════════

class QuizQuestion {
  final String questionNumber;
  final String? imagePath;     // Easy — image shown
  final String? prompt;        // Easy: "WHAT'S IN THE PICTURE?" / Average: definition
  final String? wordType;      // Average only: "- ADJECTIVE -"
  final String? subPrompt;     // Average only
  final List<String> choices;  // exactly 4
  final int correctIndex;      // 0–3
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

final List<QuizQuestion> kEasyQuestions = [
  QuizQuestion(
    questionNumber: 'QUESTION 1',
    imagePath: 'assets/images/grade.select/gs.sun.png',
    prompt: "WHAT'S IN THE PICTURE?",
    choices: ['MOON', 'DOG', 'SUN', 'CAT'],
    correctIndex: 2,
    funFact: 'THE SUN IS THE CENTER\nOF OUR SOLAR SYSTEM.',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 2',
    imagePath: 'assets/images/grade.select/gs.moon.png',
    prompt: "WHAT'S IN THE PICTURE?",
    choices: ['SUN', 'MOON', 'STAR', 'CAT'],
    correctIndex: 1,
    funFact: 'THE MOON ORBITS THE\nEARTH EVERY 27 DAYS.',
  ),
];

final List<QuizQuestion> kAverageQuestions = [
  QuizQuestion(
    questionNumber: 'QUESTION 1',
    prompt: 'FEELING OR SHOWING\nPLEASURE OR\nCONTENTMENT.',
    wordType: '- ADJECTIVE -',
    subPrompt: 'WHAT IS THE WORD DESCRIBED IN THE STATEMENT?',
    choices: ['HAPPY', 'SURPRISE', 'SAD', 'SLEEPY'],
    correctIndex: 0,
    funFact: 'AN ADJECTIVE IS A\nDESCRIBING OR\nMODIFYING A WORD.',
  ),
  QuizQuestion(
    questionNumber: 'QUESTION 2',
    prompt: 'MOVING THROUGH THE\nAIR WITH WINGS.',
    wordType: '- VERB -',
    subPrompt: 'WHAT IS THE WORD DESCRIBED IN THE STATEMENT?',
    choices: ['RUN', 'SWIM', 'FLY', 'JUMP'],
    correctIndex: 2,
    funFact: 'A VERB IS AN\nACTION OR STATE\nOF BEING WORD.',
  ),
];

// ════════════════════════════════════════════════════
// ENTRY POINT — flutter run -t lib/quiz_screen.dart
// ════════════════════════════════════════════════════

void main() => runApp(const QuizApp());

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const QuizScreen(difficulty: 'EASY'), // ← 'EASY' or 'AVERAGE'
      );
}

// ════════════════════════════════════════════════════
// QUIZ SCREEN
// ════════════════════════════════════════════════════

class QuizScreen extends StatefulWidget {
  final String difficulty;
  const QuizScreen({super.key, required this.difficulty});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {

  int  _qi         = 0;
  int  _score      = 0;
  int  _skipsLeft  = 3;
  int? _selectedIdx;          // null = unanswered
  bool _showResult = false;   // show result section instead of buttons

  // Fade animation — buttons → result swap inside the card
  late final AnimationController _fadeCtrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
  late final Animation<double> _fadeIn =
      Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn));

  List<QuizQuestion> get _qs =>
      widget.difficulty == 'EASY' ? kEasyQuestions : kAverageQuestions;
  QuizQuestion get _q   => _qs[_qi];
  bool get _isEasy      => widget.difficulty == 'EASY';
  bool get _isCorrect   => _selectedIdx == _q.correctIndex;
  String get _scoreText => 'Score $_score/${_qs.length}';

  Color get _accent {
    switch (widget.difficulty) {
      case 'AVERAGE': return const Color(0xFFFFAA33);
      case 'HARD':    return const Color(0xFFE53935);
      default:        return const Color(0xFF5BC8F5); // EASY
    }
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  // ── User taps an answer button ───────────────────────────────
  void _onAnswer(int idx) {
    if (_selectedIdx != null) return;
    setState(() {
      _selectedIdx = idx;
      if (idx == _q.correctIndex) _score++;
    });
    // Short pause so button color is visible, then fade in result
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _showResult = true);
      _fadeCtrl.forward(from: 0);
    });
  }

  // ── Skip ─────────────────────────────────────────────────────
  void _onSkip() {
    if (_skipsLeft <= 0 || _selectedIdx != null) return;
    setState(() => _skipsLeft--);
    _advance();
  }

  // ── Continue after result ────────────────────────────────────
  void _onContinue() {
    _advance();
  }

  // ── Next question or finish ──────────────────────────────────
  void _advance() {
    final next = _qi + 1;
    if (next < _qs.length) {
      setState(() {
        _qi = next;
        _selectedIdx = null;
        _showResult  = false;
      });
      _fadeCtrl.reset();
    } else {
      _showDone();
    }
  }

  void _showDone() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('QUIZ DONE!',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'SuperCartoon', fontSize: 24,
                color: Color(0xFF1A2340))),
        content: Text('YOUR SCORE\n$_score / ${_qs.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'SuperCartoon', fontSize: 20,
                color: Color(0xFF1A2340), height: 1.6)),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.maybePop(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text('CONTINUE',
                  style: TextStyle(fontFamily: 'SuperCartoon', fontSize: 16,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Button colors ─────────────────────────────────────────────
  Color _btnBg(int idx) {
    if (_selectedIdx == null) return Colors.white;
    if (idx == _q.correctIndex) return const Color(0xFF4CAF50);  // green
    if (idx == _selectedIdx)    return const Color(0xFFFF8C00);  // orange
    return Colors.white;
  }

  Color _btnText(int idx) {
    if (_selectedIdx == null)   return const Color(0xFF1A2340);
    if (idx == _q.correctIndex) return Colors.white;
    if (idx == _selectedIdx)    return Colors.white;
    return const Color(0xFF1A2340).withValues(alpha: 0.30);
  }

  Color _btnBorder(int idx) {
    if (_selectedIdx == null)   return const Color(0xFFDDDDDD);
    if (idx == _q.correctIndex) return const Color(0xFF4CAF50);
    if (idx == _selectedIdx)    return const Color(0xFFFF8C00);
    return const Color(0xFFDDDDDD);
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          // ── Space background ─────────────────────────────────
          Image.asset(
            'assets/images/bg_spc.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF0D1525)),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sh * 0.010),
              child: Column(
                children: [

                  // ══════════════════════════════════════════════
                  // HEADER — colored pill bar
                  // ══════════════════════════════════════════════
                  Container(
                    height: sh * 0.065,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(sw * 0.05),
                      boxShadow: [BoxShadow(
                        color: _accent.withValues(alpha: 0.4),
                        blurRadius: 8, offset: const Offset(0, 3),
                      )],
                    ),
                    child: Row(
                      children: [
                        // Exit left
                        Padding(
                          padding: EdgeInsets.only(left: sw * 0.03),
                          child: _TapIcon(
                            onTap: () => Navigator.maybePop(context),
                            child: SvgPicture.asset('assets/images/exit.svg',
                                width: sw * 0.068, height: sw * 0.068,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.close, color: Colors.white,
                                    size: sw * 0.060)),
                          ),
                        ),
                        // Difficulty center
                        Expanded(
                          child: Center(
                            child: Text(widget.difficulty,
                                style: TextStyle(
                                  fontFamily: 'SuperCartoon',
                                  fontSize: sw * 0.050,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                  shadows: const [Shadow(
                                      color: Colors.black38, blurRadius: 3,
                                      offset: Offset(1, 2))],
                                )),
                          ),
                        ),
                        // Score pill top-right
                        Container(
                          margin: EdgeInsets.only(right: sw * 0.020),
                          padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.024, vertical: sw * 0.008),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.26),
                            borderRadius: BorderRadius.circular(sw * 0.05),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                                width: 1.2),
                          ),
                          child: Text(_scoreText,
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: sw * 0.025,
                                color: Colors.white,
                              )),
                        ),
                        // Megaphone right
                        Padding(
                          padding: EdgeInsets.only(right: sw * 0.03),
                          child: _TapIcon(
                            onTap: () {},
                            child: SvgPicture.asset('assets/images/megaphone.svg',
                                width: sw * 0.062, height: sw * 0.062,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.volume_up, color: Colors.white,
                                    size: sw * 0.055)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sh * 0.014),

                  // ══════════════════════════════════════════════
                  // THE ONE WHITE CARD — contains everything
                  // Upper section: question info (always visible)
                  // Lower section: buttons OR result (swapped in place)
                  // ══════════════════════════════════════════════
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(sw * 0.055),
                        boxShadow: const [BoxShadow(
                            color: Colors.black38, blurRadius: 12,
                            offset: Offset(0, 5))],
                      ),
                      child: Column(
                        children: [

                          // ── UPPER: question number + X ────────
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                sw * 0.05, sh * 0.015, sw * 0.04, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_q.questionNumber,
                                    style: TextStyle(
                                      fontFamily: 'SuperCartoon',
                                      fontSize: sw * 0.034,
                                      color: const Color(0xFF555577),
                                      letterSpacing: 1,
                                    )),
                                _TapIcon(
                                  onTap: () => Navigator.maybePop(context),
                                  child: SvgPicture.asset(
                                      'assets/images/exit.svg',
                                      width: sw * 0.058, height: sw * 0.058,
                                      errorBuilder: (_, __, ___) => Icon(
                                          Icons.close, color: Colors.grey,
                                          size: sw * 0.052)),
                                ),
                              ],
                            ),
                          ),

                          // ── UPPER: image (Easy only) ──────────
                          if (_isEasy && _q.imagePath != null) ...[
                            SizedBox(height: sh * 0.008),
                            Image.asset(_q.imagePath!,
                                width: sw * 0.36, height: sw * 0.36,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.wb_sunny,
                                    color: Colors.amber, size: sw * 0.28)),
                          ],

                          // ── UPPER: prompt ─────────────────────
                          if (_q.prompt != null) ...[
                            SizedBox(height: _isEasy ? sh * 0.006 : sh * 0.016),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: sw * 0.07),
                              child: Text(_q.prompt!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'SuperCartoon',
                                    fontSize: _isEasy ? sw * 0.038 : sw * 0.036,
                                    color: const Color(0xFF1A2340),
                                    height: 1.35,
                                  )),
                            ),
                          ],

                          // ── UPPER: word type (Average) ─────────
                          if (!_isEasy && _q.wordType != null) ...[
                            SizedBox(height: sh * 0.006),
                            Text(_q.wordType!,
                                style: TextStyle(
                                  fontFamily: 'SuperCartoon',
                                  fontSize: sw * 0.028,
                                  color: const Color(0xFF999999),
                                  letterSpacing: 1,
                                )),
                          ],

                          // ── UPPER: sub-prompt (Average) ────────
                          if (!_isEasy && _q.subPrompt != null) ...[
                            SizedBox(height: sh * 0.010),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
                              child: Text(_q.subPrompt!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'SuperCartoon',
                                    fontSize: sw * 0.028,
                                    color: const Color(0xFF555577),
                                    height: 1.3,
                                  )),
                            ),
                          ],

                          // ── DIVIDER between upper and lower ───
                          // This is the visual "cut" in the reference
                          SizedBox(height: sh * 0.012),
                          Divider(
                              color: const Color(0xFFEEEEEE),
                              thickness: 1.2,
                              indent: sw * 0.04,
                              endIndent: sw * 0.04),
                          SizedBox(height: sh * 0.008),

                          // ── LOWER: buttons OR result ───────────
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 280),
                              switchInCurve: Curves.easeIn,
                              switchOutCurve: Curves.easeOut,
                              child: _showResult
                                  ? _buildResultSection(sw, sh)
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
          ),

        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // LOWER SECTION A: Answer buttons + skip
  // ════════════════════════════════════════════════════
  Widget _buildButtonsSection(double sw, double sh) {
    return Column(
      key: const ValueKey('buttons'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        // 4 answer buttons
        ...List.generate(_q.choices.length, (idx) {
          return Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.05, vertical: sh * 0.005),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              width: double.infinity,
              height: sh * 0.054,
              decoration: BoxDecoration(
                color: _btnBg(idx),
                borderRadius: BorderRadius.circular(sw * 0.025),
                border: Border.all(color: _btnBorder(idx), width: 1.5),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 3, offset: const Offset(0, 2),
                )],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(sw * 0.025),
                  onTap: _selectedIdx == null ? () => _onAnswer(idx) : null,
                  child: Center(
                    child: Text(_q.choices[idx],
                        style: TextStyle(
                          fontFamily: 'SuperCartoon',
                          fontSize: sw * 0.034,
                          color: _btnText(idx),
                          letterSpacing: 1,
                        )),
                  ),
                ),
              ),
            ),
          );
        }),

        SizedBox(height: sh * 0.010),

        // Skip button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.05),
          child: GestureDetector(
            onTap: _onSkip,
            child: Container(
              width: double.infinity,
              height: sh * 0.046,
              decoration: BoxDecoration(
                color: _skipsLeft > 0 && _selectedIdx == null
                    ? const Color(0xFF1E2A4A)
                    : const Color(0xFFBBBBBB),
                borderRadius: BorderRadius.circular(sw * 0.025),
              ),
              child: Center(
                child: Text('SKIP QUESTION ▶',
                    style: TextStyle(
                      fontFamily: 'SuperCartoon',
                      fontSize: sw * 0.028,
                      color: Colors.white,
                      letterSpacing: 1,
                    )),
              ),
            ),
          ),
        ),

        SizedBox(height: sh * 0.006),

        // Available skips
        Text('AVAILABLE SKIPS: $_skipsLeft',
            style: TextStyle(
              fontFamily: 'SuperCartoon',
              fontSize: sw * 0.025,
              color: const Color(0xFF999999),
              letterSpacing: 1,
            )),

        SizedBox(height: sh * 0.012),

      ],
    );
  }

  // ════════════════════════════════════════════════════
  // LOWER SECTION B: Result — fades in place of buttons
  // Same card, same position, no navigation, no popup
  // ════════════════════════════════════════════════════
  Widget _buildResultSection(double sw, double sh) {
    final correctWord = _q.choices[_q.correctIndex].toLowerCase();
    final resultColor = _isCorrect
        ? const Color(0xFF2ECC71)   // green
        : const Color(0xFF9B59B6);  // purple

    return SingleChildScrollView(
      key: const ValueKey('result'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            SizedBox(height: sh * 0.010),

            // CORRECT! / NICE TRY!
            Text(
              _isCorrect ? 'CORRECT!' : 'NICE TRY!',
              style: TextStyle(
                fontFamily: 'SuperCartoon',
                fontSize: sw * 0.068,
                color: resultColor,
                letterSpacing: 2,
                shadows: [Shadow(
                    color: resultColor.withValues(alpha: 0.35),
                    blurRadius: 8)],
              ),
            ),

            SizedBox(height: sh * 0.008),

            // Answer line with colored word
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: sw * 0.030,
                  color: const Color(0xFF1A2340),
                  height: 1.5,
                ),
                children: _isEasy
                    ? [
                        const TextSpan(text: 'THE IMAGE SHOWN\nABOVE IS THE '),
                        TextSpan(text: correctWord,
                            style: TextStyle(color: resultColor,
                                fontFamily: 'SuperCartoon',
                                fontSize: sw * 0.030)),
                        const TextSpan(text: '.'),
                      ]
                    : [
                        const TextSpan(text: 'THE ANSWER\nIS '),
                        TextSpan(text: correctWord,
                            style: TextStyle(color: resultColor,
                                fontFamily: 'SuperCartoon',
                                fontSize: sw * 0.030)),
                        const TextSpan(text: '.'),
                      ],
              ),
            ),

            SizedBox(height: sh * 0.016),

            // FUN FACT!
            Text('FUN FACT!',
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: sw * 0.048,
                  color: const Color(0xFFFFAA00),
                  letterSpacing: 2,
                  shadows: const [Shadow(color: Colors.black26, blurRadius: 3)],
                )),

            SizedBox(height: sh * 0.006),

            // Fun fact body
            Text(_q.funFact,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: sw * 0.030,
                  color: const Color(0xFF1A2340),
                  height: 1.4,
                )),

            SizedBox(height: sh * 0.022),

            // CONTINUE button
            GestureDetector(
              onTap: _onContinue,
              child: Container(
                width: sw * 0.50,
                height: sh * 0.054,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  borderRadius: BorderRadius.circular(sw * 0.07),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.45),
                    blurRadius: 10, offset: const Offset(0, 4),
                  )],
                ),
                child: Center(
                  child: Text('CONTINUE',
                      style: TextStyle(
                        fontFamily: 'SuperCartoon',
                        fontSize: sw * 0.036,
                        color: Colors.white,
                        letterSpacing: 2,
                      )),
                ),
              ),
            ),

            SizedBox(height: sh * 0.014),

          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// TAP ICON — press-scale animation
// ════════════════════════════════════════════════════

class _TapIcon extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _TapIcon({required this.child, required this.onTap});
  @override State<_TapIcon> createState() => _TapIconState();
}

class _TapIconState extends State<_TapIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 100));
  late final Animation<double> _s = Tween<double>(begin: 1.0, end: 0.80)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _c.forward(),
    onTapUp:     (_) { _c.reverse(); widget.onTap(); },
    onTapCancel: () => _c.reverse(),
    child: ScaleTransition(scale: _s, child: widget.child),
  );
}