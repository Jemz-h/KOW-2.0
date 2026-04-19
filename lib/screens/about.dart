import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/mock_background.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  static const double _maxContentWidth = 560;

  late final ScrollController _scrollController;
  bool _userScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  void _startAutoScroll() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _autoScroll();
  }

  void _autoScroll() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      if (_userScrolling) continue;

      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;

      if (current >= max) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted || _userScrolling) continue;
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        await Future.delayed(const Duration(milliseconds: 800));
        continue;
      }

      _scrollController.jumpTo(current + 0.6);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MockBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenW = constraints.maxWidth;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Listener(
                                onPointerDown: (_) =>
                                    setState(() => _userScrolling = true),
                                onPointerUp: (_) =>
                                    setState(() => _userScrolling = false),
                                onPointerCancel: (_) =>
                                    setState(() => _userScrolling = false),
                                child: SingleChildScrollView(
                                  controller: _scrollController,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenW * 0.06,
                                    vertical: 28,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 8),

                                      // KOW logo at the top
                                      Image.asset(
                                        'assets/misc/kow.png',
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 16),

                                      // Institutional logos row
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _buildLogo('assets/misc/sauyo.png'),
                                          const SizedBox(width: 8),
                                          _buildLogo('assets/misc/bctpoc.png'),
                                          const SizedBox(width: 8),
                                          _buildLogo('assets/misc/qcu.png'),
                                        ],
                                      ),
                                      const SizedBox(height: 24),

                                      // About description text
                                      const Text(
                                        "Karunungan on Wheels is an educational game designed to make learning fun and interactive through engaging challenges.\n\nThe game was developed by selected students of SBIT 2E from Quezon City University.\n\nThis project is not possible with the help of our Mentors, Ms. Mary Anne Manandeg and in partnership and guidance of the Barangay Sauyo Barangay Council for the Protection of Children (BCPC).",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'SuperCartoon',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          height: 1.35,
                                          color: Color(0xFFFFE34D),
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

                                      // Extra space so last content scrolls fully into view
                                      const SizedBox(height: 80),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Back button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: SvgPicture.asset('assets/icons/back.svg'),
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