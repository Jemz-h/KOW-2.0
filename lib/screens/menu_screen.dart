import 'package:flutter/material.dart';

import '../widgets/menu_button.dart';
import '../widgets/mock_background.dart';
import '../navigation/route_transitions.dart';
import 'tutorial_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';

/// Main menu screen showing the title and primary navigation buttons.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MockBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            children: [
              LogoRow(top: h * 0.04, width: w),
              Positioned(
                top: h * 0.17,
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
                top: h * 0.39,
                left: 30,
                right: 30,
                child: Text(
                  '“ENHANCING FUNCTIONAL LITERACY THROUGH LOCALLY\nDEVELOPED INSTRUCTIONAL MATERIALS”',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.028,
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
                top: h * 0.47,
                left: w * 0.34,
                child: Image.asset(
                  'assets/images/sisa.png',
                  height: h * 0.18,
                ),
              ),
              Positioned(
                bottom: h * 0.12,
                left: w * 0.18,
                right: w * 0.18,
                child: Column(
                  children: [
                    MenuButton(
                      label: 'START',
                      hoverColor: Colors.yellow.shade700,
                      onTap: () => pushFade(context, const TutorialScreen()),
                    ),
                    const SizedBox(height: 8),
                    MenuButton(
                      label: 'TUTORIAL',
                      hoverColor: Colors.blue.shade700,
                      onTap: () => pushFade(context, const TutorialScreen()),
                    ),
                    const SizedBox(height: 8),
                    MenuButton(
                      label: 'SETTING',
                      hoverColor: Colors.green.shade700,
                      onTap: () => pushFade(context, const SettingsScreen()),
                    ),
                    const SizedBox(height: 8),
                    MenuButton(
                      label: 'ABOUT',
                      hoverColor: Colors.purple.shade700,
                      onTap: () => pushFade(context, const AboutScreen()),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
