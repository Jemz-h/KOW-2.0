import 'package:flutter/material.dart';

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

  final List<Color>? gradientColors;
  final Alignment gradientCenter;
  final double gradientRadius;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  late final AnimationController _scaleCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _scaleCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    _scaleCtrl.reverse();
    widget.onTap?.call();
  }

  void _onCancel() {
    setState(() => _isPressed = false);
    _scaleCtrl.reverse();
  }

  /// Smoothly darkens colors
  Color _pressedColor(Color c) => Color.lerp(c, Colors.black, 0.25)!;
  Color _hoverColor(Color c) => Color.lerp(c, Colors.white, 0.08)!;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? const Color(0xFFE5E5E5);

    final gradient = widget.gradientColors != null
        ? RadialGradient(
            colors: widget.gradientColors!.map((c) {
              if (_isPressed) return _pressedColor(c);   // 🔥 FULL button darkens
              if (_isHovered) return _hoverColor(c);
              return c;
            }).toList(),
            center: widget.gradientCenter,
            radius: widget.gradientRadius,
          )
        : null;

    final flatColor = _isPressed
        ? _pressedColor(baseColor)
        : (_isHovered && widget.hoverColor != null
            ? widget.hoverColor!
            : baseColor);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onCancel,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160), // 🔥 smoother
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: gradient == null ? flatColor : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_isPressed ? 0.18 : 0.35),
                  blurRadius: _isPressed ? 3 : 8,
                  offset: Offset(0, _isPressed ? 2 : 5),
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
        ),
      ),
    );
  }
}