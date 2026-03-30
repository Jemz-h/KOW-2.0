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
                  final instructionSize = (screenW * 0.082).clamp(21.0, 28.0);
                  final readLabelSize = (screenW * 0.052).clamp(15.0, 19.0);

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        // ── Main dark card containing the tutorial content ──
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            clipBehavior: Clip.antiAlias,
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
                            child: LayoutBuilder(
                              builder: (context, cardConstraints) {
                                final scale = (cardConstraints.maxHeight / 760)
                                    .clamp(0.76, 1.0);
                                final titleSize = 38.0 * scale;
                                final paragraphSize = instructionSize * scale;
                                final micSize = (screenW * 0.25).clamp(
                                  90.0,
                                  124.0,
                                );

                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.topCenter,
                                  child: SizedBox(
                                    width: cardConstraints.maxWidth,
                                    child: Column(
                                      children: [
                                        SizedBox(height: 8 * scale),

                                        // ── "TUTORIAL" title ──
                                        Text(
                                          'TUTORIAL',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'SuperCartoon',
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 6,
                                                color: Colors.black54,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 24 * scale),

                                        // ── First instruction paragraph ──
                                        Text(
                                          'CHOOSE THE CORRECT ANSWER FOR EACH QUESTION BY CLICKING ON THE OPTION YOU THINK IS CORRECT.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'SuperCartoon',
                                            fontSize: paragraphSize,
                                            fontWeight: FontWeight.w800,
                                            height: 1.32,
                                            color: const Color(0xFFFFE34D),
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 3,
                                                color: Colors.black38,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 24 * scale),

                                        // ── Second instruction paragraph ──
                                        Text(
                                          'EACH QUESTION IS WORTH 1 POINT, AND TO ADVANCE TO THE NEXT DIFFICULTY LEVEL, YOU MUST SCORE AT LEAST 7 OUT OF 10.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'SuperCartoon',
                                            fontSize: paragraphSize,
                                            fontWeight: FontWeight.w800,
                                            height: 1.32,
                                            color: const Color(0xFFFFE34D),
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 3,
                                                color: Colors.black38,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          height:
                                              ((screenW * 0.18).clamp(
                                                34.0,
                                                76.0,
                                              )) *
                                              scale,
                                        ),

                                        // ── Clickable microphone / megaphone icon (1.svg) ──
                                        Material(
                                          color: Colors.transparent,
                                          child: InkResponse(
                                            onTap: () {
                                              ScaffoldMessenger.of(context)
                                                ..hideCurrentSnackBar()
                                                ..showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Read-aloud coming soon',
                                                    ),
                                                    duration: Duration(
                                                      milliseconds: 900,
                                                    ),
                                                  ),
                                                );
                                            },
                                            radius: micSize * 0.7,
                                            child: SvgPicture.asset(
                                              'assets/icons/megaphone.svg',
                                              width: micSize * scale,
                                              height: micSize * scale,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12 * scale),

                                        // ── "PRESS TO READ THE QUESTION" label ──
                                        Text(
                                          'PRESS TO READ\nTHE QUESTION',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'SuperCartoon',
                                            fontSize: readLabelSize * scale,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                            color: const Color(0xFFFFE34D),
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 2,
                                                color: Colors.black38,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 5 * scale),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Back arrow button at the bottom-left ──
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: SvgPicture.asset(
                              'assets/icons/back.svg',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
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
