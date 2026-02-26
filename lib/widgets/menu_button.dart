import 'package:flutter/material.dart';

/// Menu button that animates its background color on hover.
class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.hoverColor,
    this.onTap,
  });

  /// Button text label.
  final String label;

  /// Base background color (defaults to light gray).
  final Color? color;

  /// Text color for the label.
  final Color? textColor;

  /// Optional hover color for desktop/web hover state.
  final Color? hoverColor;

  /// Tap handler for the menu action.
  final VoidCallback? onTap;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? const Color(0xFFE5E5E5);
    Color displayColor = baseColor;
    
    if (_isPressed) {
      // Darken color when pressed
      displayColor = Color.lerp(baseColor, Colors.black, 0.15)!;
    } else if (_isHovered && widget.hoverColor != null) {
      displayColor = widget.hoverColor!;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: displayColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isPressed
                ? [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SuperCartoon',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: widget.textColor ?? Colors.black,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
