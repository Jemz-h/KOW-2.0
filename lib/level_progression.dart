class LevelProgression {
  LevelProgression._();

  static const int questionsPerLevel = 5;
  static const int totalNodes = 9;
  static const List<String> nodeDifficultyOrder = ['EASY', 'AVERAGE', 'HARD'];

  static String difficultyForNode(int nodeIndex) {
    return nodeDifficultyOrder[nodeIndex % nodeDifficultyOrder.length];
  }

  static int difficultyLevelIndex({
    required int nodeIndex,
    required String difficulty,
  }) {
    final normalized = difficulty.trim().toUpperCase();
    var levelIndex = 0;

    for (var index = 0; index <= nodeIndex && index < totalNodes; index++) {
      if (difficultyForNode(index) == normalized) {
        if (index == nodeIndex) {
          return levelIndex;
        }
        levelIndex++;
      }
    }

    return 0;
  }

  static List<Map<String, dynamic>> questionsForNode({
    required List<Map<String, dynamic>> rows,
    required int nodeIndex,
    required String difficulty,
  }) {
    if (rows.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final sorted = List<Map<String, dynamic>>.from(rows)
      ..sort((left, right) {
        final leftId = _asInt(left['id']) ?? _asInt(left['question_id']) ?? 0;
        final rightId =
            _asInt(right['id']) ?? _asInt(right['question_id']) ?? 0;
        return leftId.compareTo(rightId);
      });

    final levelIndex = difficultyLevelIndex(
      nodeIndex: nodeIndex,
      difficulty: difficulty,
    );
    final start = levelIndex * questionsPerLevel;
    if (start >= sorted.length) {
      return const <Map<String, dynamic>>[];
    }

    final end = (start + questionsPerLevel).clamp(0, sorted.length).toInt();
    return sorted.sublist(start, end);
  }

  static int? _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }
}
