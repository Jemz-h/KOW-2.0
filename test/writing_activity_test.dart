import 'package:flutter_test/flutter_test.dart';
import 'package:kow/writing_activity.dart';

void main() {
  test('writing activity exposes two learner-friendly outcomes', () {
    expect(writingActivityChoices, hasLength(2));
    expect(writingActivityChoices[0].label, 'I wrote it');
    expect(writingActivityChoices[0].isSuccessful, isTrue);
    expect(writingActivityChoices[1].label, 'I need more practice');
    expect(writingActivityChoices[1].isSuccessful, isFalse);
  });

  test('writing activity converts outcomes into one-item score records', () {
    expect(scoreForWritingChoice(0), (score: 1, total: 1));
    expect(scoreForWritingChoice(1), (score: 0, total: 1));
  });
}
