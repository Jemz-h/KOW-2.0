import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/menu_button.dart';
import '../widgets/mock_background.dart';
import '../widgets/coming_soon_popup.dart';
import '../navigation/route_transitions.dart';
import 'tutorial_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

/// Main menu screen showing the title and primary navigation buttons.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        backgroundAsset: 'assets/images/bg_spc_w:cloud.png',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenW = constraints.maxWidth;
            final screenH = constraints.maxHeight;

            final isTablet = screenW >= 700;
            final contentMaxW = isTablet ? 560.0 : screenW;
            final contentW = math.min(screenW, contentMaxW);

            final scale = math.min(contentW / 412, screenH / 917);

            final designW = 412 * scale;
            final designH = 917 * scale;

            double sx(double px) => px * scale;
            double sy(double px) => px * scale;

            return SafeArea(
              child: Center(
                child: SizedBox(
                  width: designW,
                  height: designH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: sx(20), top: sy(20),
                        width: sx(372), height: sy(110),
                        child: LogoRow(top: 0, width: sx(372)),
                      ),
                      Positioned(
                        left: sx(10), right: sx(10), top: sy(145),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'KARUNUNGAN ON\nWHEELS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SuperCartoon', fontSize: sx(55),
                              fontWeight: FontWeight.w900, height: 1.0,
                              color: Colors.white,
                              shadows: const [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(3, 3))],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: sx(20), right: sx(20), top: sy(290),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '"ENHANCING FUNCTIONAL LITERACY THROUGH\nLOCALLY DEVELOPED INSTRUCTIONAL MATERIALS"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SuperCartoon', fontSize: sx(16),
                              fontWeight: FontWeight.w800, height: 1.3,
                              color: const Color(0xFFFFE34D),
                              shadows: const [Shadow(blurRadius: 4, color: Colors.black38, offset: Offset(1, 1))],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: sx(80), right: sx(80), top: sy(370), height: sy(280),
                        child: Image.asset('assets/images/sisa.png', fit: BoxFit.contain),
                      ),
                      Positioned(
                        left: sx(50), right: sx(50), top: sy(670),
                        child: Column(
                          children: [
                            MenuButton(label: 'START', onTap: () => showComingSoonPopup(context)),
                            SizedBox(height: sy(8)),
                            MenuButton(label: 'TUTORIAL', onTap: () => pushFade(context, const TutorialScreen())),
                            SizedBox(height: sy(8)),
                            MenuButton(label: 'SETTINGS', onTap: () => pushFade(context, const SettingsScreen())),
                            SizedBox(height: sy(8)),
                            MenuButton(label: 'ABOUT', onTap: () => pushFade(context, const AboutScreen())),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
