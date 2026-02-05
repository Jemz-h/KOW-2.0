import 'package:flutter/material.dart';
import '../widgets/mock_background.dart';

/// Settings screen with buttons and an Audio Settings dialog.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 14,
                                  activeTrackColor: Colors.green[600],
                                  inactiveTrackColor: Colors.green[100],
                                  thumbColor: Colors.blue[700],
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                                  overlayColor: Colors.blue.withOpacity(0.12),
                                ),
                                child: Slider(
                                  value: musicVolume,
                                  min: 0,
                                  max: 1,
                                  onChanged: musicOn ? (v) => setState(() => musicVolume = v) : null,
                                ),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                              ),
                              child: const Icon(Icons.drag_handle, size: 18, color: Colors.blueGrey),
                            )
                          ],
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 14,
                                  activeTrackColor: Colors.green[600],
                                  inactiveTrackColor: Colors.green[100],
                                  thumbColor: Colors.blue[700],
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                                  overlayColor: Colors.blue.withOpacity(0.12),
                                ),
                                child: Slider(
                                  value: sfxVolume,
                                  min: 0,
                                  max: 1,
                                  onChanged: sfxOn ? (v) => setState(() => sfxVolume = v) : null,
                                ),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
                              ),
                              child: const Icon(Icons.drag_handle, size: 18, color: Colors.blueGrey),
                            )
                          ],
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

  Widget _buildMenuButton(BuildContext context, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 62,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 28),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 4))],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              shadows: [Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 2))],
            ),
          ),
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
                            shadows: [Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons matching the visual style in the attachments
                      _buildMenuButton(context, const Color(0xFF3B8A3C), 'PROFILE', () {}),
                      _buildMenuButton(context, const Color(0xFFF6A623), 'ACHIEVEMENTS', () {}),
                      _buildMenuButton(context, const Color(0xFF1E63B6), 'AUDIO', () => _showAudioSettings(context)),
                      _buildMenuButton(context, const Color(0xFF7B2AAE), 'THEMES', () {}),
                      _buildMenuButton(context, const Color(0xFFCC3333), 'SIGN OUT', () {}),

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
