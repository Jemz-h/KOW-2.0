import 'package:flutter/material.dart';

const _kDuration = Duration(milliseconds: 280);

/// Push with smooth fade + subtle lift
void pushFade(BuildContext context, Widget page) {
  Navigator.of(context).push(_buildRoute(page));
}

/// Replace with same transition
void pushFadeReplacement(BuildContext context, Widget page) {
  Navigator.of(context).pushReplacement(_buildRoute(page));
}

/// Shared optimized route
PageRouteBuilder _buildRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: _kDuration,
    reverseTransitionDuration: _kDuration,
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Incoming animation (new page)
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      final slideIn = Tween<Offset>(
        begin: const Offset(0, 0.06), // slightly less = smoother
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      // Outgoing animation (old page)
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOut,
      );

      return FadeTransition(
        opacity: fadeIn,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: ReverseAnimation(fadeOut), // smooth exit
            child: child,
          ),
        ),
      );
    },
  );
}