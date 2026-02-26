import 'package:flutter/material.dart';

const String kDefaultBackgroundImage = 'assets/images/bg_spc_w:cloud.png';

/// Chalkboard background wrapper used across all screens.
class MockBackground extends StatelessWidget {
  const MockBackground({
    super.key,
    required this.child,
    this.backgroundImage,
    this.fit = BoxFit.cover,
  });

  final Widget child;
  final String? backgroundImage;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final resolvedBackground = backgroundImage ?? kDefaultBackgroundImage;

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            resolvedBackground,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              // Safe fallback: solid color so we never re-trigger a broken asset
              return Container(color: const Color(0xFF2E4A2E));
            },
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: child,
        ),
      ],
    );
  }
}

/// Shared logo row displayed at the top of landing/menu screens.
class LogoRow extends StatelessWidget {
  const LogoRow({super.key, required this.top, required this.width});

  final double top;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/Group_Logos.png',
        height: width * 0.25,
        fit: BoxFit.contain,
      ),
    );
  }
}
