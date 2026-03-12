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
        stops: [0.0, 1.0],
      );

      Widget sectionBox({required Widget child}) => Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: sectionMargin),
            decoration: BoxDecoration(
              gradient: panelGradient,
              borderRadius: BorderRadius.circular(10 * scale),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: sectionVertPad),
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
              child: Container(
                width: dialogWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBBBBB), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 16, offset: Offset(0, 8))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── STATISTICS title in grey header ──
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

                    // ── WHITE INNER PANEL ──
                    Container(
                      margin: EdgeInsets.fromLTRB(10 * scale, 0, 10 * scale, 12 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
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
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                                ),
                                padding: EdgeInsets.symmetric(vertical: 12 * scale * hFactor),
                                child: Center(
                                  child: Text(
                                    'NICKNAME',
                                    style: strokedText(
                                      fontSize: nicknameFontSize,
                                      color: const Color(0xFFFFA500),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),

                              // TOTAL TIME PLAYED
                              sectionBox(
                                child: Row(
                                  children: [
                                    Image.asset(
                                      'assets/icons/back.svg',
                                      width: 52 * scale * hFactor,
                                      height: 52 * scale * hFactor,
                                      errorBuilder: (c, e, s) => Icon(Icons.hourglass_bottom, size: 52 * scale * hFactor, color: Colors.white),
                                    ),
                                    SizedBox(width: 14 * scale),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Time', style: strokedText(fontSize: bodyFontSize * 1.1, color: Colors.white)),
                                        Text('Played:', style: strokedText(fontSize: bodyFontSize * 1.1, color: Colors.white)),
                                        SizedBox(height: 4 * scale),
                                        Text('0h 0m', style: strokedText(fontSize: bodyFontSize, color: Colors.white70, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // TOKENS EARNED
                              sectionBox(
                                child: Column(
                                  children: [
                                    Text('TOKENS EARNED', style: strokedText(fontSize: sectionTitleFontSize, color: Colors.white, letterSpacing: 1.5)),
                                    SizedBox(height: 10 * scale * hFactor),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // Bronze = 35.svg
                                        _CoinBadge(assetPath: 'assets/icons/bronze.svg', count: 24, size: coinSize, fontSize: coinCountFontSize, strokedText: strokedText),
                                        // Silver = 34.svg
                                        _CoinBadge(assetPath: 'assets/icons/silver.svg', count: 24, size: coinSize, fontSize: coinCountFontSize, strokedText: strokedText),
                                        // Gold = 33.svg
                                        _CoinBadge(assetPath: 'assets/icons/gold.svg', count: 24, size: coinSize, fontSize: coinCountFontSize, strokedText: strokedText),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // COMPLETION
                              sectionBox(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text('COMPLETION', style: strokedText(fontSize: sectionTitleFontSize, color: Colors.white, letterSpacing: 1.5)),
                                    ),
                                    SizedBox(height: 8 * scale * hFactor),
                                    Text('Math Lessons Completed:', style: strokedText(fontSize: bodyFontSize, color: Colors.white, fontWeight: FontWeight.w700)),
                                    SizedBox(height: 4 * scale * hFactor),
                                    Text('Total Levels Passed:', style: strokedText(fontSize: bodyFontSize, color: Colors.white, fontWeight: FontWeight.w700)),
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
            ),
          ),

          // Back button — fixed bottom left of screen
          Positioned(
            bottom: screenHeight * 0.03,
            left: 24,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                'assets/icons/back.svg',
                width: 56 * scale,
                height: 56 * scale,
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({
    required this.assetPath,
    required this.count,
    required this.size,
    required this.fontSize,
    required this.strokedText,
  });

  final String assetPath;
  final int count;
  final double size;
  final double fontSize;
  final TextStyle Function({required double fontSize, required Color color, FontWeight fontWeight, double letterSpacing}) strokedText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 6),
        Text(
          'x$count',
          style: strokedText(fontSize: fontSize, color: Colors.white),
        ),
      ],
    );
  }
}