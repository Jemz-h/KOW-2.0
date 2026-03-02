import 'package:flutter/material.dart';

/// Reusable animated button with kid-friendly press effects.
///
/// Provides a strong but subtle bounce animation on press, suitable for
/// engaging children while maintaining visual polish. Supports optional
/// leading icons, customizable colors, and responsive sizing.
///
/// Example:
/// ```dart
/// KowAnimatedButton(
///   label: 'START',
///   onPressed: () => navigateToNext(),
///   backgroundColor: Color(0xFF5C87E5),
///   textColor: Colors.white,
/// )
/// ```
/// A reusable, animated button widget with a kid-friendly bounce effect.
///
/// This button provides a strong but subtle press animation, shadow changes,
/// and ripple feedback. It is highly customizable and can be used for any
/// call-to-action in the app.
class KowAnimatedButton extends StatefulWidget {
  const KowAnimatedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.backgroundColor = const Color(0xFF5C87E5),
    this.textColor = Colors.white,
    this.width,
    this.height = 56,
    this.borderRadius,
    this.padding,
    this.leadingIcon,
    this.strongEffect = true,
    this.fontSize = 25,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = 1.0,
  });

  /// The text displayed on the button.
  final String label;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button is enabled (default: true).
  final bool enabled;

  /// Background color of the button.
  final Color backgroundColor;

  /// Text color of the button label.
  final Color textColor;

  /// Optional fixed width. If null, uses double.infinity (full width).
  final double? width;

  /// Fixed height of the button (default: 56).
  final double height;

  /// Optional border radius. If null, uses pill shape (height/2).
  final BorderRadius? borderRadius;

  /// Optional custom padding. If null, uses default vertical padding.
  final EdgeInsets? padding;

  /// Optional leading icon widget.
  final Widget? leadingIcon;

  /// Use strong press effect for kids (default: true).
  /// When true, uses more pronounced scale animation.
  final bool strongEffect;

  /// Font size of the button label (default: 25).
  final double fontSize;

  /// Font weight of the button label (default: w800).
  final FontWeight fontWeight;

  /// Letter spacing of the button label (default: 1.0).
  final double letterSpacing;

  @override
  State<KowAnimatedButton> createState() => _KowAnimatedButtonState();
}

/// State class for [KowAnimatedButton]. Handles animation and interaction logic.
class _KowAnimatedButtonState extends State<KowAnimatedButton>
    with SingleTickerProviderStateMixin {
  // Animation controller for the press/bounce effect
  late AnimationController _controller;
  // Animation for scaling the button
  late Animation<double> _scaleAnimation;
  // Tracks if the button is currently pressed
  bool _isPressed = false;
  // Tracks if the button is hovered (for web)
  bool _isHovered = false;

  @override
  @override
  void initState() {
    super.initState();

    // Set up the animation controller for the press effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100), // quick press down
    );

    // Define the scale animation: quick shrink, then bounce back
    _scaleAnimation = TweenSequence<double>([
      // Press down quickly (scale to 0.96 or 0.97)
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: widget.strongEffect ? 0.96 : 0.97,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      // Bounce back to normal size with a springy curve
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.strongEffect ? 0.96 : 0.97,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  @override
  void dispose() {
    // Clean up the animation controller
    _controller.dispose();
    super.dispose();
  }

  // Called when the user presses down on the button
  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.onPressed == null) return;

    setState(() {
      _isPressed = true;
    });

    // Start the press animation
    _controller.forward(from: 0);
  }

  // Called when the user lifts their finger (or mouse) from the button
  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
  }

  // Called if the tap is cancelled (e.g., pointer leaves the button)
  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  // Called when the button is tapped (completed)
  void _handleTap() {
    if (!widget.enabled || widget.onPressed == null) return;
    widget.onPressed!();
  }

  @override
  /// Builds the animated button widget tree.
  @override
  Widget build(BuildContext context) {
    // Use faded colors if disabled
    final effectiveBackgroundColor = widget.enabled
        ? widget.backgroundColor
        : widget.backgroundColor.withValues(alpha: 0.5);

    final effectiveTextColor = widget.enabled
        ? widget.textColor
        : widget.textColor.withValues(alpha: 0.5);

    // Slightly scale up on hover (web only)
    final hoverScale = _isHovered && !_isPressed ? 1.01 : 1.0;

    // Shadow and elevation change when pressed
    final elevation = _isPressed ? 2.0 : 4.0;
    final shadowOpacity = _isPressed ? 0.15 : 0.25;

    return MouseRegion(
      // Handle mouse hover for web
      onEnter: (_) {
        if (widget.enabled && widget.onPressed != null) {
          setState(() {
            _isHovered = true;
          });
        }
      },
      onExit: (_) {
        setState(() {
          _isHovered = false;
        });
      },
      cursor: widget.enabled && widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: hoverScale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            // Handle press and tap events for animation
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                color: effectiveBackgroundColor,
                borderRadius: widget.borderRadius ??
                    BorderRadius.circular(widget.height / 2),
                boxShadow: [
                  // Drop shadow that shrinks on press
                  BoxShadow(
                    color: Colors.black.withValues(alpha: shadowOpacity),
                    blurRadius: elevation * 2,
                    offset: Offset(0, elevation),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  // InkWell for ripple/highlight feedback
                  onTap: widget.enabled ? _handleTap : null,
                  borderRadius: widget.borderRadius ??
                      BorderRadius.circular(widget.height / 2),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Container(
                    padding: widget.padding ??
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Optional leading icon
                        if (widget.leadingIcon != null) ...[
                          widget.leadingIcon!,
                          const SizedBox(width: 8),
                        ],
                        // Button label
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: widget.fontSize,
                            fontWeight: widget.fontWeight,
                            color: effectiveTextColor,
                            letterSpacing: widget.letterSpacing,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
