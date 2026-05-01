import 'package:flutter_test/flutter_test.dart';
import 'package:kow/break_time_policy.dart';

void main() {
  test('shows breaktime after every third completed level', () {
    expect(BreakTimePolicy.shouldShowAfterPassedLevel(0), isFalse);
    expect(BreakTimePolicy.shouldShowAfterPassedLevel(1), isFalse);
    expect(BreakTimePolicy.shouldShowAfterPassedLevel(2), isTrue);
    expect(BreakTimePolicy.shouldShowAfterPassedLevel(5), isTrue);
  });
}
