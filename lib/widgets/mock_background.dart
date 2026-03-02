import 'package:flutter/material.dart';

/// Chalkboard background wrapper used across all screens.
class MockBackground extends StatelessWidget {
  const MockBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/bg_kow(Classroom).png', fit: BoxFit.cover),
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
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/lg_sauyo.png', height: width * 0.12),
          SizedBox(width: width * 0.03),
          Image.asset('assets/images/lg_qcu.png', height: width * 0.12),
          SizedBox(width: width * 0.03),
          Image.asset('assets/images/lg_bctpoc.png', height: width * 0.12),
        ],
      ),
    );
  }
}
