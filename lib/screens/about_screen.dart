import 'package:flutter/material.dart';
import '../widgets/mock_background.dart';

/// About screen – currently under development.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MockBackground(
        backgroundAsset: 'assets/images/bg_spc_w:cloud.png',
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'ABOUT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SuperCartoon',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black45, offset: Offset(1, 1)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // balance the back button
                  ],
                ),
              ),
              // Coming-soon content
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8F0F7),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'OOPS!',
                          style: TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/images/Bunny_construction.png',
                          height: 130,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/oyo.png',
                            height: 130,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'THAT FEATURE IS\nUNDER DEVELOPMENT.\nSTAY TUNED!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: 160,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFCC44),
                              foregroundColor: const Color(0xFF2D2D2D),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'RETURN',
                              style: TextStyle(
                                fontFamily: 'SuperCartoon',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
    );
  }
}
