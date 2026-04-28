// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';

/// Global theme notifier so any screen can listen to background changes.
final ValueNotifier<String> selectedThemeNotifier = ValueNotifier<String>(
  'space',
);

/// Maps theme keys to their background asset paths.
const Map<String, String> themeBackgrounds = {
  'classroom': 'assets/themes/p.class-def.png',
  'sauyo':
      'assets/themes/s.card.png', // keep as-is (no p.sauyo background exists)
  'space': 'assets/themes/p.space-cloud.png',
};

/// Chalkboard background wrapper used across all screens.
class MockBackground extends StatelessWidget {
  const MockBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedThemeNotifier,
      builder: (context, theme, _) {
        final bgAsset = themeBackgrounds[theme] ?? themeBackgrounds['space']!;
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                bgAsset,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Container(color: const Color(0xFF1A2A3A)),
              ),
            ),
            Material(type: MaterialType.transparency, child: child),
          ],
        );
      },
    );
  }
}

/// Shared logo row displayed at the top of landing/menu screens.
class LogoRow extends StatelessWidget {
  const LogoRow({super.key, this.top = 0, required this.width});

  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, top),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/misc/sauyo.png',
            height: width * 0.12,
            errorBuilder: (_, __, ___) =>
                SizedBox(width: width * 0.12, height: width * 0.12),
          ),
          SizedBox(width: width * 0.03),
          Image.asset(
            'assets/misc/qcu.png',
            height: width * 0.12,
            errorBuilder: (_, __, ___) =>
                SizedBox(width: width * 0.12, height: width * 0.12),
          ),
          SizedBox(width: width * 0.03),
          Image.asset(
            'assets/misc/bctpoc.png',
            height: width * 0.12,
            errorBuilder: (_, __, ___) =>
                SizedBox(width: width * 0.12, height: width * 0.12),
          ),
        ],
      ),
    );
  }
}
