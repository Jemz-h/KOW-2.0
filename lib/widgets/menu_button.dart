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

  @override
  Widget build(BuildContext context) {
  final baseColor = widget.color ?? const Color(0xFFE5E5E5);
  final displayColor = _isHovered && widget.hoverColor != null ? widget.hoverColor! : baseColor;

    return InkWell(
      onTap: widget.onTap,
      onHover: (value) {
        setState(() {
          _isHovered = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: displayColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
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
            fontSize: 18,
            color: widget.textColor ?? Colors.black,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
