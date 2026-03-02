import 'package:flutter/material.dart';

import '../widgets/mock_background.dart';

/// About screen – displays project information, institutional logos,
/// and a description inside a dark rounded card (matching tutorial design).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
                        // ── Main dark card containing the about content ──
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenW * 0.06,
                              vertical: 28,
                            ),
                            decoration: BoxDecoration(
                              // Dark gradient background matching the design
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

                                  // ── "ABOUT" title ──
                                  const Text(
                                    'ABOUT',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'SuperCartoon',
                                      fontSize: 40,
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
                                  const SizedBox(height: 16),

                                  // ── Institutional logos row ──
                                  Image.asset(
                                    'assets/images/Group_Logos.png',
                                    height: 60,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Fallback: show individual logos in a row
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildLogo('assets/images/lg_sauyo.png'),
                                          const SizedBox(width: 8),
                                          _buildLogo('assets/images/lg_bctpoc.png'),
                                          const SizedBox(width: 8),
                                          _buildLogo('assets/images/lg_qcu.png'),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // ── About description text ──
                                  const Text(
                                    'LOREM IPSUM DOLOR SIT AMET, CONSECTETUR ADIPISCING ELIT, '
                                    'SED DO EIUSMOD TEMPOR INCIDIDUNT UT LABORE ET DOLORE MAGNA ALIQUA. '
                                    'UT ENIM AD MINIM VENIAM, QUIS NOSTRUD EXERCITATION ULLAMCO LABORIS '
                                    'NISI UT ALIQUIP EX EA COMMODO CONSEQUAT. NULLA PROIDENT, SUNT IN CULPA '
                                    'QUI OFFICIA DESERUNT MOLLIT ANIM ID EST LABORUM.',
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
                                  const SizedBox(height: 16),
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

  /// Builds a circular logo image widget (fallback for individual logos).
  static Widget _buildLogo(String assetPath) {
    return ClipOval(
      child: Image.asset(
        assetPath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
    );
  }
}
