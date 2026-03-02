import 'package:flutter/material.dart';
import '../widgets/mock_background.dart';

/// Settings screen with buttons and an Audio Settings dialog.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _titleShadow = [
    Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
  ];

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      trackHeight: 12,
      activeTrackColor: const Color(0xFF2FAE2C),
      inactiveTrackColor: const Color(0xFFBFEBC0),
      thumbColor: const Color(0xFF2F6EB5),
      overlayColor: const Color(0xFF2F6EB5).withOpacity(0.12),
      thumbShape: const _PillThumbShape(),
    );
  }

  void _showAudioSettings(BuildContext context) {
    bool musicOn = true;
    bool sfxOn = true;
    double musicVolume = 0.8;
    double sfxVolume = 0.8;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title row with close button
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'AUDIO SETTINGS',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.grey[800],
                                  shadows: [Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(child: Icon(Icons.close, color: Colors.white, size: 18)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // ON/OFF buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('MUSIC', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => setState(() => musicOn = !musicOn),
                                child: Container(
                                  width: 96,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: musicOn ? Colors.green[600] : Colors.grey[350],
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: musicOn
                                        ? [BoxShadow(color: Colors.green.shade200.withOpacity(0.6), blurRadius: 6, offset: Offset(0, 3))]
                                        : [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                  ),
                                  child: Center(
                                    child: Text(musicOn ? 'ON' : 'OFF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Column(
                            children: [
                              const Text('SFX', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => setState(() => sfxOn = !sfxOn),
                                child: Container(
                                  width: 96,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sfxOn ? Colors.green[600] : Colors.grey[350],
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: sfxOn
                                        ? [BoxShadow(color: Colors.green.shade200.withOpacity(0.6), blurRadius: 6, offset: Offset(0, 3))]
                                        : [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                  ),
                                  child: Center(
                                    child: Text(sfxOn ? 'ON' : 'OFF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Music volume
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('MUSIC VOLUME', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: SliderTheme(
                          data: _sliderTheme(context),
                          child: Slider(
                            value: musicVolume,
                            min: 0,
                            max: 1,
                            onChanged: musicOn ? (v) => setState(() => musicVolume = v) : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // SFX volume
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('SFX VOLUME', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: SliderTheme(
                          data: _sliderTheme(context),
                          child: Slider(
                            value: sfxVolume,
                            min: 0,
                            max: 1,
                            onChanged: sfxOn ? (v) => setState(() => sfxVolume = v) : null,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _showThemeSettings(BuildContext context) {
    String selectedTheme = 'classroom';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Center(
              child: Container(
                width: 360,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'CHANGE THEME',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                  color: Colors.grey[800],
                                  shadows: const [Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(child: Icon(Icons.close, color: Colors.white, size: 18)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ThemeCard(
                            label: 'CLASSROOM',
                            assetPath: 'assets/images/settings/classroomBg.png',
                            selected: selectedTheme == 'classroom',
                            onTap: () => setState(() => selectedTheme = 'classroom'),
                          ),
                          _ThemeCard(
                            label: 'SAUYO',
                            assetPath: 'assets/images/settings/wellBg.png',
                            selected: selectedTheme == 'sauyo',
                            onTap: () => setState(() => selectedTheme = 'sauyo'),
                          ),
                          _ThemeCard(
                            label: 'SPACE',
                            assetPath: 'assets/images/settings/spaceBg.png',
                            selected: selectedTheme == 'space',
                            onTap: () => setState(() => selectedTheme = 'space'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3DBE64),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required List<Color> gradient,
    required String label,
    String? iconAsset,
    required VoidCallback onTap,
    double height = 60,
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (iconAsset != null)
              Positioned(
                left: 14,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      iconAsset,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                shadows: [Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MockBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'SETTINGS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            shadows: _titleShadow,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons matching the visual style in the attachments
                      _buildMenuButton(
                        context,
                        gradient: const [Color(0xFF2E8B4D), Color(0xFF1F6C3C)],
                        label: 'PROFILE',
                        iconAsset: 'assets/images/settings/student.png',
                        onTap: () {},
                      ),
                      _buildMenuButton(
                        context,
                        gradient: const [Color(0xFFF2B531), Color(0xFFE39A14)],
                        label: 'ACHIEVEMENTS',
                        iconAsset: 'assets/images/settings/medal_gold.png',
                        onTap: () {},
                      ),
                      _buildMenuButton(
                        context,
                        gradient: const [Color(0xFF2C5AC5), Color(0xFF1B2E6E)],
                        label: 'AUDIO',
                        iconAsset: 'assets/images/settings/volume.png',
                        onTap: () => _showAudioSettings(context),
                      ),
                      _buildMenuButton(
                        context,
                        gradient: const [Color(0xFFB43BBF), Color(0xFF7A1A86)],
                        label: 'THEMES',
                        iconAsset: 'assets/images/settings/paintbrush.png',
                        onTap: () => _showThemeSettings(context),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: _buildMenuButton(
                          context,
                          gradient: const [Color(0xFFC63B33), Color(0xFF8F1D1A)],
                          label: 'SIGN OUT',
                          iconAsset: null,
                          onTap: () {},
                          height: 52,
                          width: 220,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PillThumbShape extends SliderComponentShape {
  const _PillThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(20, 32);

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
    final rect = Rect.fromCenter(center: center, width: 18, height: 26);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    final paint = Paint()..color = thumbColor;
    canvas.drawRRect(rrect, paint);

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final x = center.dx;
    final y = center.dy;
    canvas.drawLine(Offset(x - 3, y - 6), Offset(x - 3, y + 6), linePaint);
    canvas.drawLine(Offset(x + 3, y - 6), Offset(x + 3, y + 6), linePaint);
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 84,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: selected ? const Color(0xFF3DBE64) : Colors.transparent, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
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
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              if (selected)
                Positioned.fill(
                  child: Center(
                    child: Image.asset(
                      'assets/images/gender_check.png',
                      width: 44,
                      height: 44,
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
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.grey[700],
              shadows: const [Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
            ),
          ),
        ],
      ),
    );
  }
}
