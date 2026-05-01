import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kow/widgets/break_time.dart';

void main() {
  test('breaktime card keeps the radial green classroom gradient', () {
    expect(kBreakTimeCardGradient, isA<RadialGradient>());
    expect(kBreakTimeCardGradient.center, Alignment.center);
    expect(kBreakTimeCardGradient.radius, 0.9);
    expect(kBreakTimeCardGradient.colors, const [
      Color(0xFF6A9F78),
      Color(0xFF9BC7A4),
    ]);
    expect(kBreakTimeCardGradient.stops, const [0.3, 1.0]);
  });
}
