import 'package:flutter/material.dart';

class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.pressedTextColor,
    this.hoverColor,
    this.pressedColor,
    this.onTap,
    this.gradientColors,
    this.pressedGradientColors,
    this.gradientCenter = Alignment.center,
    this.gradientRadius = 1.0,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final Color? pressedTextColor;
  final Color? hoverColor;
  final Color? pressedColor;
  final VoidCallback? onTap;
  final List<Color>? gradientColors;
  final List<Color>? pressedGradientColors;
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

  Color _pressedColor(Color c) => Color.lerp(c, Colors.black, 0.25)!;
  Color _hoverColor(Color c) => Color.lerp(c, Colors.white, 0.08)!;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? const Color(0xFFE5E5E5);
    final activeGradientColors =
        _isPressed && widget.pressedGradientColors != null
        ? widget.pressedGradientColors
        : widget.gradientColors;

    final gradient = activeGradientColors != null
        ? RadialGradient(
            colors: activeGradientColors.map((color) {
              if (_isPressed && widget.pressedGradientColors == null) {
                return _pressedColor(color);
              }
              if (_isHovered) return _hoverColor(color);
              return color;
            }).toList(),
            center: widget.gradientCenter,
            radius: widget.gradientRadius,
          )
        : null;

    final flatColor = _isPressed
        ? (widget.pressedColor ?? _pressedColor(baseColor))
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
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: gradient == null ? flatColor : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isPressed ? 0.18 : 0.35,
                  ),
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
                color: _isPressed
                    ? (widget.pressedTextColor ??
                          widget.textColor ??
                          Colors.black)
                    : (widget.textColor ?? Colors.black),
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
