class BreakTimePolicy {
  BreakTimePolicy._();

  static const int levelsBetweenBreaks = 3;

  static bool shouldShowAfterPassedLevel(int completedNodeIndex) {
    final completedLevelNumber = completedNodeIndex + 1;
    if (completedLevelNumber <= 0) {
      return false;
    }

    return completedLevelNumber % levelsBetweenBreaks == 0;
  }
}
