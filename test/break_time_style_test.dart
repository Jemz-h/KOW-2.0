import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kow/widgets/break_time.dart';

void main() {
  test('breaktime card keeps the soft white radial glow', () {
    expect(kBreakTimeCardGradient, isA<RadialGradient>());
    expect(kBreakTimeCardGradient.center, const Alignment(0, -0.08));
    expect(kBreakTimeCardGradient.radius, 1.02);
    expect(kBreakTimeCardGradient.colors, const [
      Color(0xFFF8FFF9),
      Color(0xFFE6F7EA),
      Color(0xFF8CB195),
    ]);
    expect(kBreakTimeCardGradient.stops, const [0.0, 0.52, 1.0]);
    expect(kBreakTimeTimerColor, const Color(0xFF80BE99));
    expect(kBreakTimeRestingButtonColor, const Color(0xFF9CB9A1));
    expect(kBreakTimeRestingTextColor, const Color(0xFF5E7E68));
  });
}
