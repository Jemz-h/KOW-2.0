import 'package:flutter/material.dart';

import '../navigation/route_transitions.dart';
import '../widgets/mock_background.dart';
import 'welcome_back_screen.dart';

/// Landing screen that opens the welcome back flow.
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => pushFade(context, const WelcomeBackScreen()),
      child: MockBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return Stack(
              children: [
                LogoRow(top: h * 0.04, width: w),
                Positioned(
                  top: h * 0.18,
                  left: 20,
                  right: 20,
                  child: Text(
                    'KARUNUNGAN\nON WHEELS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: w * 0.12,
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
                ),
                Positioned(
                  top: h * 0.42,
                  left: 30,
                  right: 30,
                  child: Text(
                    '“ENHANCING FUNCTIONAL LITERACY THROUGH LOCALLY\nDEVELOPED INSTRUCTIONAL MATERIALS”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: w * 0.032,
                      color: const Color(0xFFFFE34D),
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: h * 0.05,
                  left: w * 0.08,
                  child: Image.asset(
                    'assets/images/oyo.png',
                    height: h * 0.28,
                  ),
                ),
                Positioned(
                  bottom: h * 0.02,
                  right: w * 0.14,
                  child: Image.asset(
                    'assets/images/sisa.png',
                    height: h * 0.22,
                  ),
                ),
                Positioned(
                  bottom: h * 0.03,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Tap anywhere to start',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: w * 0.04,
                      color: Colors.white70,
                      shadows: const [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black45,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
