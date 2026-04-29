import 'package:flutter_test/flutter_test.dart';
import 'package:kow/level_progression.dart';

void main() {
  test(
    'currentNodeForLearner resumes at highest unlocked slab from map start',
    () {
      expect(
        LevelProgression.currentNodeForLearner(
          selectedNodeIndex: 0,
          maxUnlockedNodeIndex: 1,
        ),
        1,
      );
    },
  );

  test(
    'currentNodeForLearner clamps stale selected slab to unlocked range',
    () {
      expect(
        LevelProgression.currentNodeForLearner(
          selectedNodeIndex: 8,
          maxUnlockedNodeIndex: 2,
        ),
        2,
      );
    },
  );
}
