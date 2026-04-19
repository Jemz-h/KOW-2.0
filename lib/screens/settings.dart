import 'package:flutter/material.dart';
import '../widgets/mock_background.dart';
import '../widgets/profile_dialog.dart';
import '../widgets/achievement_dialog.dart';
import '../services/audio.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dialogOpen = false;

  // ── Shared stroked text style ──────────────────────────────────────────────
  static TextStyle _strokedText({
    required double fontSize,
    required Color color,
    double letterSpacing = 1.0,
  }) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: letterSpacing,
        shadows: const [
          Shadow(offset: Offset(-1, -1), color: Colors.black, blurRadius: 1),
          Shadow(offset: Offset(1, -1), color: Colors.black, blurRadius: 1),
          Shadow(offset: Offset(-1, 1), color: Colors.black, blurRadius: 1),
          Shadow(offset: Offset(1, 1), color: Colors.black, blurRadius: 1),
        ],
      );

  // ── Shared slider theme ────────────────────────────────────────────────────
  static SliderThemeData _sliderTheme(BuildContext context) =>
      SliderTheme.of(context).copyWith(
        trackHeight: 22,
        activeTrackColor: const Color(0xFF2FAE2C),
        inactiveTrackColor: const Color(0xFFBFEBC0),
        thumbColor: const Color(0xFF2F6EB5),
        overlayColor: const Color(0xFF2F6EB5).withValues(alpha: 0.12),
        thumbShape: const _PillThumbShape(),
      );

  // ── Audio settings dialog ──────────────────────────────────────────────────
  Future<void> _showAudioSettings(BuildContext context) async {
    setState(() => _dialogOpen = true);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool musicOn = AudioService().musicOn;
        bool sfxOn = AudioService().sfxOn;
        double musicVolume = AudioService().musicVolume;
        double sfxVolume = AudioService().sfxVolume;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final isTablet = screenWidth > 600;
            final dialogWidth = isTablet ? screenWidth * 0.70 : screenWidth * 0.88;
            final scale = isTablet ? 1.5 : 1.0;
            final hFactor = (screenHeight / 750).clamp(0.75, 1.2);
            final iconButtonSize = 100.0 * scale * hFactor;
            final labelFontSize = 18.0 * scale * hFactor;

            // Reusable toggle button
            Widget toggleButton({
              required String label,
              required bool isOn,
              required VoidCallback onTap,
            }) =>
                Column(
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A2A3A),
                            letterSpacing: 1.0)),
                    SizedBox(height: 10 * scale),
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        width: iconButtonSize,
                        height: iconButtonSize,
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.4,
                            colors: [Color(0xFF4861B5), Color(0xFF053C66)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 4))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SvgPicture.asset(
                            isOn ? 'assets/icons/unmute.svg' : 'assets/icons/mute.svg',
                          ),
                        ),
                      ),
                    ),
                  ],
                );

            // Reusable volume slider row
            Widget volumeSlider({
              required String label,
              required double value,
              required void Function(double) onChanged,
            }) =>
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1A2A3A),
                            letterSpacing: 1.0)),
                    SizedBox(height: 8 * scale),
                    Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF8BBAD8),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: SliderTheme(
                        data: _sliderTheme(context),
                        child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
                      ),
                    ),
                  ],
                );

            return PopScope(
              canPop: false,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: dialogWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3C4E6A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2A3A52), width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title row
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale, vertical: 12 * scale),
                          child: Row(
                            children: [
                              const Spacer(),
                              Text('AUDIO SETTINGS',
                                  style: _strokedText(
                                      fontSize: 22.0 * scale,
                                      color: Colors.white,
                                      letterSpacing: 1.5)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: SizedBox(
                                  width: 38 * scale,
                                  height: 38 * scale,
                                  child: SvgPicture.asset('assets/icons/exit.svg'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content panel
                        Container(
                          margin: EdgeInsets.fromLTRB(
                              10 * scale, 0, 10 * scale, 14 * scale),
                          decoration: BoxDecoration(
                              color: const Color(0xFFB6D5F0),
                              borderRadius: BorderRadius.circular(12)),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale, vertical: 16 * scale),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Toggle buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  toggleButton(
                                    label: 'MUSIC',
                                    isOn: musicOn,
                                    onTap: () async {
                                      final val = !musicOn;
                                      await AudioService().setMusicOn(val);
                                      setDialogState(() => musicOn = val);
                                    },
                                  ),
                                  toggleButton(
                                    label: 'SFX',
                                    isOn: sfxOn,
                                    onTap: () async {
                                      final val = !sfxOn;
                                      await AudioService().setSfxOn(val);
                                      setDialogState(() => sfxOn = val);
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.03),

                              // Music volume slider
                              volumeSlider(
                                label: 'MUSIC VOLUME',
                                value: musicVolume,
                                onChanged: (v) async {
                                  await AudioService().setMusicVolume(v);
                                  setDialogState(() {
                                    musicVolume = v;
                                    // Auto mute/unmute based on slider position
                                    if (v > 0 && !musicOn) {
                                      AudioService().setMusicOn(true);
                                      musicOn = true;
                                    } else if (v == 0 && musicOn) {
                                      AudioService().setMusicOn(false);
                                      musicOn = false;
                                    }
                                  });
                                },
                              ),
                              SizedBox(height: screenHeight * 0.025),

                              // SFX volume slider
                              volumeSlider(
                                label: 'SFX VOLUME',
                                value: sfxVolume,
                                onChanged: (v) async {
                                  await AudioService().setSfxVolume(v);
                                  setDialogState(() {
                                    sfxVolume = v;
                                    if (v > 0 && !sfxOn) {
                                      AudioService().setSfxOn(true);
                                      sfxOn = true;
                                    } else if (v == 0 && sfxOn) {
                                      AudioService().setSfxOn(false);
                                      sfxOn = false;
                                    }
                                  });
                                },
                              ),
                              SizedBox(height: 8 * scale),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) setState(() => _dialogOpen = false);
  }

  // ── Theme settings dialog ──────────────────────────────────────────────────
  Future<void> _showThemeSettings(BuildContext context) async {
    setState(() => _dialogOpen = true);

    String selectedTheme = selectedThemeNotifier.value;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            final isTablet = screenWidth > 600;
            final dialogWidth =
                isTablet ? screenWidth * 0.70 : screenWidth * 0.88;
            final scale = isTablet ? 1.5 : 1.0;
            final hFactor = (screenHeight / 750).clamp(0.75, 1.2);
            final cardWidth = (dialogWidth * 0.26).clamp(70.0, 160.0);
            final cardHeight = cardWidth * 2.2;
            final labelFontSize = 14.0 * scale * hFactor;
            final confirmFontSize = 16.0 * scale * hFactor;

            return PopScope(
              canPop: false,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: dialogWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBBBBB), width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 8))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16 * scale, vertical: 14 * scale),
                          child: Row(
                            children: [
                              const Spacer(),
                              Text('CHANGE THEME',
                                  style: _strokedText(
                                      fontSize: 22.0 * scale,
                                      color: Colors.white,
                                      letterSpacing: 2)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: SizedBox(
                                  width: 38 * scale,
                                  height: 38 * scale,
                                  child: SvgPicture.asset('assets/icons/exit.svg'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(
                              10 * scale, 0, 10 * scale, 14 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                            ],
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale, vertical: 16 * scale),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _ThemeCard(
                                    label: 'CLASSROOM',
                                    assetPath: 'assets/settings/classroom_thm.png',
                                    selected: selectedTheme == 'classroom',
                                    onTap: () => setDialogState(() => selectedTheme = 'classroom'),
                                    width: cardWidth, height: cardHeight,
                                    labelFontSize: labelFontSize,
                                  ),
                                  _ThemeCard(
                                    label: 'SAUYO',
                                    assetPath: 'assets/settings/sauyo_thm.png',
                                    selected: selectedTheme == 'sauyo',
                                    onTap: () => setDialogState(() => selectedTheme = 'sauyo'),
                                    width: cardWidth, height: cardHeight,
                                    labelFontSize: labelFontSize,
                                  ),
                                  _ThemeCard(
                                    label: 'SPACE',
                                    assetPath: 'assets/settings/space_thm.png',
                                    selected: selectedTheme == 'space',
                                    onTap: () => setDialogState(() => selectedTheme = 'space'),
                                    width: cardWidth, height: cardHeight,
                                    labelFontSize: labelFontSize,
                                  ),
                                ],
                              ),
                              SizedBox(height: 20 * scale * hFactor),
                              SizedBox(
                                width: dialogWidth * 0.55,
                                height: 48 * scale * hFactor,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const RadialGradient(
                                      center: Alignment.center,
                                      radius: 1.0,
                                      colors: [Color(0xFF79FF9D), Color(0xFF30A65B)],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3))
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(25)),
                                    ),
                                    onPressed: () {
                                      selectedThemeNotifier.value = selectedTheme;
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('CONFIRM',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: confirmFontSize,
                                            letterSpacing: 1.5,
                                            color: Colors.black)),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8 * scale),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (mounted) setState(() => _dialogOpen = false);
  }

  // ── Menu button builder ────────────────────────────────────────────────────
  Widget _buildMenuButton(
    BuildContext context, {
    required Gradient gradient,
    required String label,
    String? iconAsset,
    required VoidCallback onTap,
    bool isSignOut = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final buttonWidth = isSignOut ? screenWidth * 0.60 : screenWidth * 0.88;
    final buttonHeight = isSignOut ? screenHeight * 0.07 : screenHeight * 0.09;
    final iconBoxSize = buttonHeight * 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonWidth,
        height: buttonHeight,
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 5))
          ],
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (iconAsset != null)
              Positioned(
                left: 14,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SizedBox(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    child: iconAsset.endsWith('.svg')
                        ? SvgPicture.asset(iconAsset,
                            width: iconBoxSize,
                            height: iconBoxSize,
                            fit: BoxFit.contain)
                        : Image.asset(iconAsset,
                            width: iconBoxSize,
                            height: iconBoxSize,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(
                                Icons.image_not_supported,
                                color: Colors.white70,
                                size: 26)),
                  ),
                ),
              ),
            Positioned(
              left: iconAsset != null ? iconBoxSize + 24 : 20,
              right: 12,
              child: Text(
                label,
                textAlign: isSignOut ? TextAlign.center : TextAlign.left,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 36.0 : 26.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3.0,
                  shadows: const [
                    Shadow(offset: Offset(-1, -1), color: Colors.black87, blurRadius: 0),
                    Shadow(offset: Offset(1, -1), color: Colors.black87, blurRadius: 0),
                    Shadow(offset: Offset(-1, 1), color: Colors.black87, blurRadius: 0),
                    Shadow(offset: Offset(1, 1), color: Colors.black87, blurRadius: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final scale = isTablet ? 1.5 : 1.0;

    return Scaffold(
      body: MockBackground(
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'SETTINGS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(offset: Offset(-3, -3), color: Colors.black, blurRadius: 0),
                                  Shadow(offset: Offset(3, -3), color: Colors.black, blurRadius: 0),
                                  Shadow(offset: Offset(-3, 3), color: Colors.black, blurRadius: 0),
                                  Shadow(offset: Offset(3, 3), color: Colors.black, blurRadius: 0),
                                  Shadow(offset: Offset(0, 4), color: Colors.black54, blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(child: _buildMenuButton(context, gradient: const RadialGradient(center: Alignment.centerLeft, radius: 1.2, colors: [Color(0xFFFFFFFF), Color(0xFF3C467B)]), label: 'PROFILE',      iconAsset: 'assets/icons/smiley.svg',  onTap: () => showProfileDialog(context))),
                          Center(child: _buildMenuButton(context, gradient: const RadialGradient(center: Alignment.centerLeft, radius: 1.2, colors: [Color(0xFFFFFFFF), Color(0xFFFF9D00)]), label: 'ACHIEVEMENTS', iconAsset: 'assets/icons/gold.svg',    onTap: () => showAchievementDialog(context))),
                          Center(child: _buildMenuButton(context, gradient: const RadialGradient(center: Alignment.centerLeft, radius: 1.2, colors: [Color(0xFFFFFFFF), Color(0xFF571272)]), label: 'AUDIO',        iconAsset: 'assets/icons/unmute.svg',  onTap: () => _showAudioSettings(context))),
                          Center(child: _buildMenuButton(context, gradient: const RadialGradient(center: Alignment.centerLeft, radius: 1.2, colors: [Color(0xFFFFFFFF), Color(0xFFCA22A6)]), label: 'THEMES',       iconAsset: 'assets/icons/brush.svg',   onTap: () => _showThemeSettings(context))),
                          const SizedBox(height: 16),
                          Center(child: _buildMenuButton(context, gradient: const RadialGradient(center: Alignment.center, radius: 1.0, colors: [Color(0xFFED4343), Color(0xFF872626)], stops: [0.53, 1.0]), label: 'SIGN OUT', onTap: () {}, isSignOut: true)),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Bottom-left back button
              Positioned(
                bottom: screenHeight * 0.03,
                left: 24,
                child: Opacity(
                  opacity: _dialogOpen ? 0.0 : 1.0,
                  child: IgnorePointer(
                    ignoring: _dialogOpen,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox(
                        width: 56 * scale,
                        height: 56 * scale,
                        child: SvgPicture.asset('assets/icons/back.svg'),
                      ),
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

// ── Pill thumb shape ───────────────────────────────────────────────────────────
class _PillThumbShape extends SliderComponentShape {
  const _PillThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(28, 44);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final thumbColor = sliderTheme.thumbColor ?? const Color(0xFF2F6EB5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 26, height: 40),
          const Radius.circular(8)),
      Paint()..color = thumbColor,
    );
    final lp = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - 4, center.dy - 9),
        Offset(center.dx - 4, center.dy + 9), lp);
    canvas.drawLine(Offset(center.dx + 4, center.dy - 9),
        Offset(center.dx + 4, center.dy + 9), lp);
  }
}

// ── Theme card ─────────────────────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
    required this.width,
    required this.height,
    required this.labelFontSize,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;
  final double width;
  final double height;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF3DBE64)
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (selected)
                Positioned.fill(
                  child: Center(
                    child: Image.asset(
                      'assets/icons/check.png',
                      width: width * 0.5,
                      height: width * 0.5,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.grey[700],
              shadows: const [
                Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
              ],
            ),
          ),
        ],
      ),
    );
  }
}