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

  test(
    'currentNodeForLearner resumes from saved current slab when it is unlocked',
    () {
      expect(
        LevelProgression.currentNodeForLearner(
          selectedNodeIndex: 0,
          maxUnlockedNodeIndex: 5,
          savedCurrentNodeIndex: 4,
        ),
        4,
      );
    },
  );

  test(
    'currentNodeForLearner clamps saved current slab to unlocked range',
    () {
      expect(
        LevelProgression.currentNodeForLearner(
          selectedNodeIndex: 0,
          maxUnlockedNodeIndex: 3,
          savedCurrentNodeIndex: 8,
        ),
        3,
      );
    },
  );

  test(
    'maxUnlockedNodeForLearner prefers saved slab progress over difficulty fallback',
    () {
      expect(
        LevelProgression.maxUnlockedNodeForLearner(
          highestDiffPassed: 1,
          savedHighestNodeIndex: 4,
        ),
        4,
      );
    },
  );
}
