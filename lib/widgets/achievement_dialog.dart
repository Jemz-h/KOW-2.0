import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void showAchievementDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final isTablet = screenWidth > 600;

      final dialogWidth = isTablet ? screenWidth * 0.70 : screenWidth * 0.88;
      final scale = isTablet ? 1.4 : 1.0;
      final hFactor = (screenHeight / 750).clamp(0.75, 1.2);

      final titleFontSize = 22.0 * scale * hFactor;
      final sectionTitleFontSize = 18.0 * scale * hFactor;
      final bodyFontSize = 13.0 * scale * hFactor;
      final nicknameFontSize = 22.0 * scale * hFactor;
      final coinSize = 62.0 * scale * hFactor;
      final coinCountFontSize = 16.0 * scale * hFactor;
      final sectionVertPad = 12.0 * scale * hFactor;
      final sectionMargin = 6.0 * scale * hFactor;

      TextStyle strokedText({
        required double fontSize,
        required Color color,
        FontWeight fontWeight = FontWeight.w900,
        double letterSpacing = 1.0,
      }) =>
          TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            letterSpacing: letterSpacing,
            shadows: const [
              Shadow(offset: Offset(-1, -1), color: Colors.black, blurRadius: 1),
              Shadow(offset: Offset(1, -1), color: Colors.black, blurRadius: 1),
              Shadow(offset: Offset(-1, 1), color: Colors.black, blurRadius: 1),
              Shadow(offset: Offset(1, 1), color: Colors.black, blurRadius: 1),
            ],
          );

      const panelGradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [Color(0xFF48B5BB), Color(0xFF36888D)],
      );

      Widget sectionBox({required Widget child}) => Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: sectionMargin),
            decoration: BoxDecoration(
              gradient: panelGradient,
              borderRadius: BorderRadius.circular(10 * scale),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: sectionVertPad,
            ),
            child: child,
          );

      return Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.transparent),
          ),

          Center(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Container(
                    width: dialogWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBBBBB), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // ── HEADER ──
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 14 * scale * hFactor),
                          child: Center(
                            child: Text(
                              'STATISTICS',
                              style: strokedText(
                                fontSize: titleFontSize,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),

                        // ── INNER PANEL ──
                        Container(
                          margin: EdgeInsets.fromLTRB(10 * scale, 0, 10 * scale, 12 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 10 * scale,
                            vertical: 10 * scale * hFactor,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: dialogWidth - (10 * scale * 2) - (10 * scale * 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  // NICKNAME
                                  Container(
                                    width: double.infinity,
                                    margin: EdgeInsets.only(bottom: sectionMargin),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3C467B),
                                      borderRadius: BorderRadius.circular(10 * scale),
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 12 * scale * hFactor),
                                    child: Center(
                                      child: Text(
                                        'NICKNAME',
                                        style: strokedText(
                                          fontSize: nicknameFontSize,
                                          color: const Color(0xFFFFA500),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // TOTAL TIME
                                 sectionBox(
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        'assets/icons/back.png', // can be any image (even if missing)
                                        width: 52 * scale * hFactor,
                                        height: 52 * scale * hFactor,
                                        errorBuilder: (c, e, s) => Icon(
                                          Icons.hourglass_bottom,
                                          size: 52 * scale * hFactor,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 14 * scale),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Total Time',
                                              style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                          Text('Played:',
                                              style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                          Text('0h 0m',
                                              style: strokedText(
                                                  fontSize: bodyFontSize, color: Colors.white70)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                  // TOKENS
                                  sectionBox(
                                    child: Column(
                                      children: [
                                        Text('TOKENS EARNED', style: strokedText(fontSize: sectionTitleFontSize, color: Colors.white)),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: const [
                                            _CoinBadge(assetPath: 'assets/icons/bronze.svg', count: 24),
                                            _CoinBadge(assetPath: 'assets/icons/silver.svg', count: 24),
                                            _CoinBadge(assetPath: 'assets/icons/gold.svg', count: 24),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // COMPLETION
                                  sectionBox(
                                    child: Column(
                                      children: [
                                        Text('COMPLETION', style: strokedText(fontSize: sectionTitleFontSize, color: Colors.white)),
                                        Text('Math Lessons Completed:', style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                        Text('Total Levels Passed:', style: strokedText(fontSize: bodyFontSize, color: Colors.white)),
                                      ],
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

                  // ❌ X BUTTON (TOP RIGHT)
                  Positioned(
                    top: 10 * scale,
                    right: 10 * scale,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: SvgPicture.asset(
                        'assets/icons/x.svg',
                        width: 32 * scale,
                        height: 32 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _CoinBadge extends StatelessWidget {
  final String assetPath;
  final int count;

  const _CoinBadge({
    required this.assetPath,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(assetPath, width: 50, height: 50),
        const SizedBox(width: 6),
        Text('x$count', style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
