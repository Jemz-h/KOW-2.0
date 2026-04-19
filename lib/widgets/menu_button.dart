import 'package:flutter/material.dart';

/// Menu button with radial gradient background and hover animation.
class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.hoverColor,
    this.onTap,
    this.gradientColors,
    this.gradientCenter = Alignment.center,
    this.gradientRadius = 1.0,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final Color? hoverColor;
  final VoidCallback? onTap;

  /// Colors for the radial gradient (center → edge).
  final List<Color>? gradientColors;

  /// Center point of the radial gradient.
  final Alignment gradientCenter;

  /// Radius of the radial gradient.
  final double gradientRadius;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? const Color(0xFFE5E5E5);
    final displayColor =
        _isHovered && widget.hoverColor != null ? widget.hoverColor! : baseColor;

    // Build gradient if colors provided, otherwise fall back to flat color
    final gradient = widget.gradientColors != null
        ? RadialGradient(
            colors: _isHovered
                ? widget.gradientColors!.map((c) => c.withOpacity(0.85)).toList()
                : widget.gradientColors!,
            center: widget.gradientCenter,
            radius: widget.gradientRadius,
          )
        : null;

    return InkWell(
      onTap: widget.onTap,
      onHover: (value) => setState(() => _isHovered = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: gradient == null ? displayColor : null,
          gradient: gradient,
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
            color: widget.textColor ?? const Color.fromARGB(255, 0, 0, 0),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}