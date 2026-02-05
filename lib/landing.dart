import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Uncomment the comment below to remove the debug ribbon on the upper right
      // debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SuperCartoon',
        useMaterial3: true,
      ),
      home: const LandingFlow(),
    );
  }
}

class LandingFlow extends StatefulWidget {
  const LandingFlow({super.key});

  @override
  State<LandingFlow> createState() => _LandingFlowState();
}

class _LandingFlowState extends State<LandingFlow> {
  bool _showLogin = false;

  void _handleStart() {
    if (_showLogin) {
      return;
    }
    setState(() {
      _showLogin = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 900),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: child,
            ),
          );
        },
        child: _showLogin
            ? const WelcomeBackScreen(key: ValueKey('welcome'))
            : StartScreen(
                key: const ValueKey('start'),
                onStart: _handleStart,
              ),
      ),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bg_spc.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: h * 0.04,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/lg_sauyo.png', height: h * 0.1),
                    SizedBox(width: w * 0.03),
                    Image.asset('assets/images/lg_qcu.png', height: h * 0.1),
                    SizedBox(width: w * 0.03),
                    Image.asset('assets/images/lg_bctpoc.png', height: h * 0.1),
                  ],
                ),
              ),
              Positioned(
                top: h * 0.17,
                left: 20,
                right: 20,
                child: Text(
                  'KARUNUNGAN ON\nWHEELS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.11,
                    letterSpacing: 1,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: h * 0.35,
                left: 20,
                right: 20,
                child: Text(
                  '“ENHANCING FUNCTIONAL LITERACY THROUGH\nLOCALLY DEVELOPED INSTRUCTIONAL MATERIALS”',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: w * 0.035,
                    color: Colors.yellow,
                    letterSpacing: 1,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: h * 0.10,
                left: w * -0.1,
                child: Image.asset(
                  'assets/images/oyo.png',
                  height: h * 0.5,
                ),
              ),
              Positioned(
                bottom: h * 0.12,
                right: w * 0.03,
                child: Image.asset(
                  'assets/images/sisa.png',
                  height: h * 0.35,
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
                    fontSize: w * 0.045,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black,
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
    );
  }
}

class WelcomeBackScreen extends StatelessWidget {
  const WelcomeBackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Container(
          color: const Color(0xFF1A8F8E),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: h * 0.03,
                  left: w * 0.04,
                  child: Text(
                    '2 + 2 =',
                    style: TextStyle(
                      fontSize: w * 0.05,
                      color: Colors.white70,
                    ),
                  ),
                ),
                Positioned(
                  top: h * 0.06,
                  right: w * 0.12,
                  child: Container(
                    width: w * 0.18,
                    height: w * 0.12,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: Colors.white38, width: 2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  bottom: h * 0.05,
                  left: w * 0.05,
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white54,
                    size: w * 0.08,
                  ),
                ),
                Positioned(
                  bottom: h * 0.05,
                  right: w * 0.06,
                  child: Icon(
                    Icons.info,
                    color: Colors.white70,
                    size: w * 0.06,
                  ),
                ),
                Positioned(
                  bottom: h * 0.0,
                  left: -w * 0.05,
                  child: Image.asset(
                    'assets/images/oyo.png',
                    height: h * 0.35,
                  ),
                ),
                Positioned(
                  bottom: h * 0.02,
                  right: w * 0.02,
                  child: Image.asset(
                    'assets/images/sisa.png',
                    height: h * 0.22,
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.08),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'WELCOME\nBACK!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: w * 0.12,
                              color: Colors.white,
                              height: 0.9,
                              shadows: const [
                                Shadow(
                                  blurRadius: 8,
                                  color: Colors.black45,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'LOGIN TO CONTINUE\nYOUR ADVENTURE!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: w * 0.04,
                              color: const Color(0xFFFFE34D),
                              shadows: const [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black38,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: h * 0.03),
                          _ChalkTextField(
                            hintText: 'NICKNAME',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 12),
                          _ChalkDropdown(
                            hintText: 'BIRTHDAY',
                            icon: Icons.cake,
                            items: const ['January', 'February', 'March'],
                          ),
                          const SizedBox(height: 16),
                          _ChalkButton(
                            label: 'START',
                            color: const Color(0xFF5C87E5),
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'NO NICKNAME YET? CLICK THE BUTTON BELOW',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: w * 0.03,
                              color: const Color(0xFFFFE34D),
                              shadows: const [
                                Shadow(
                                  blurRadius: 3,
                                  color: Colors.black38,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ChalkButton(
                            label: 'SIGN UP',
                            color: const Color(0xFFF2F089),
                            textColor: const Color(0xFF2B2B2B),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChalkTextField extends StatelessWidget {
  const _ChalkTextField({required this.hintText, required this.icon});

  final String hintText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        prefixIcon: Icon(icon, color: const Color(0xFF7B7B7B)),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ChalkDropdown extends StatefulWidget {
  const _ChalkDropdown({required this.hintText, required this.icon, required this.items});

  final String hintText;
  final IconData icon;
  final List<String> items;

  @override
  State<_ChalkDropdown> createState() => _ChalkDropdownState();
}

class _ChalkDropdownState extends State<_ChalkDropdown> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selected,
      icon: const Icon(Icons.arrow_drop_down),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: widget.hintText,
        prefixIcon: Icon(widget.icon, color: const Color(0xFF7B7B7B)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      items: widget.items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selected = value;
        });
      },
    );
  }
}

class _ChalkButton extends StatelessWidget {
  const _ChalkButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, letterSpacing: 1),
        ),
      ),
    );
  }
}
