import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../widgets/mock_background.dart';

/// Tutorial screen – displays game instructions and a clickable
/// text-to-speech microphone button inside a dark rounded card.
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  // Maximum content width for tablet / Chrome desktop constraint
  static const double _maxContentWidth = 560;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: SafeArea(
          child: Center(
            // Constrain width for tablet / desktop Chrome
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenW = constraints.maxWidth;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        // ── Top-left "Tutorial" label ──
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tutorial',
                            style: TextStyle(
                              fontFamily: 'SuperCartoon',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4FC3F7), // light blue label
                              shadows: [
                                Shadow(
                                  blurRadius: 3,
                                  color: Colors.black38,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Main dark card containing the tutorial content ──
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenW * 0.08,
                              vertical: 28,
                            ),
                            decoration: BoxDecoration(
                              // Dark gradient background matching screenshot
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF1A1A2E),
                                  Color(0xFF16213E),
                                  Color(0xFF0F3460),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),

                                  // ── "TUTORIAL" title ──
                                  const Text(
                                    'TUTORIAL',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'SuperCartoon',
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 6,
                                          color: Colors.black54,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── First instruction paragraph ──
                                  const Text(
                                    'CHOOSE THE CORRECT ANSWER FOR EACH QUESTION BY CLICKING ON THE OPTION YOU THINK IS CORRECT.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'SuperCartoon',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.35,
                                      color: Color(0xFFFFE34D), // gold/yellow
                                      shadows: [
                                        Shadow(
                                          blurRadius: 3,
                                          color: Colors.black38,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // ── Second instruction paragraph ──
                                  const Text(
                                    'EACH QUESTION IS WORTH 1 POINT, AND TO ADVANCE TO THE NEXT DIFFICULTY LEVEL, YOU MUST SCORE AT LEAST 7 OUT OF 10.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'SuperCartoon',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      height: 1.35,
                                      color: Color(0xFFFFE34D), // gold/yellow
                                      shadows: [
                                        Shadow(
                                          blurRadius: 3,
                                          color: Colors.black38,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // ── Clickable microphone / megaphone icon (1.svg) ──
                                  GestureDetector(
                                    onTap: () {
                                      // TODO: implement text-to-speech / read question aloud
                                    },
                                    child: SvgPicture.asset(
                                      'assets/Icons/KOWICONS/1.svg',
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // ── "PRESS TO READ THE QUESTION" label ──
                                  const Text(
                                    'PRESS TO READ\nTHE QUESTION',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'SuperCartoon',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                      color: Color(0xFFFFE34D), // gold/yellow
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black38,
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Back arrow button at the bottom-left ──
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF3A7BD5), // blue arrow
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
