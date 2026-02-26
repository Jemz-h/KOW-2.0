import 'package:flutter/material.dart';

/// Chalkboard background wrapper used across all screens.
class MockBackground extends StatelessWidget {
  const MockBackground({
    super.key,
    required this.child,
    this.backgroundAsset = 'assets/images/bg_spc_phone.png',
    this.fit = BoxFit.cover,
  });

  final Widget child;
  final String backgroundAsset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundAsset,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/bg_spc_phone.png',
                fit: BoxFit.cover,
              );
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
