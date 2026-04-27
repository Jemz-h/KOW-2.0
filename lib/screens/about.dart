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
                    padding: EdgeInsets.symmetric(
                      horizontal: screenW * 0.06,
                      vertical: 28,
                    ).copyWith(
                      left: (screenW * 0.01).clamp(12, 24),
                      right: (screenW * 0.01).clamp(12, 24),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(106, 0, 0, 0),
                              borderRadius: BorderRadius.circular(36),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(0, 0, 0, 0),
                                borderRadius: BorderRadius.circular(36),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(36),
                                child: Listener(
                                  onPointerDown: (_) =>
                                      setState(() => _userScrolling = true),
                                  onPointerUp: (_) =>
                                      setState(() => _userScrolling = false),
                                  onPointerCancel: (_) =>
                                      setState(() => _userScrolling = false),
                                  child: ShaderMask(
                                    shaderCallback: (Rect rect) {
                                      return LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: const [
                                          Colors.transparent,
                                          Colors.black,
                                          Colors.black,
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.1, 0.9, 1.0],
                                      ).createShader(rect);
                                    },
                                    blendMode: BlendMode.dstIn,
                                    child: SingleChildScrollView(
                                      controller: _scrollController,
                                      physics:
                                          const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 28,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 8),

                                            Image.asset(
                                              'assets/misc/kow.png',
                                              fit: BoxFit.contain,
                                            ),
                                            const SizedBox(height: 16),

                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                _buildLogo(
                                                    'assets/misc/sauyo.png'),
                                                const SizedBox(width: 8),
                                                _buildLogo(
                                                    'assets/misc/bctpoc.png'),
                                                const SizedBox(width: 8),
                                                _buildLogo(
                                                    'assets/misc/qcu.png'),
                                              ],
                                            ),
                                            const SizedBox(height: 24),

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
                                            const SizedBox(height: 80),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child:
                                  SvgPicture.asset('assets/icons/back.svg'),
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