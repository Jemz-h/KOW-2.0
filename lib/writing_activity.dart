class WritingActivityChoice {
  const WritingActivityChoice({
    required this.label,
    required this.isSuccessful,
  });

  final String label;
  final bool isSuccessful;
}

const writingActivityChoices = <WritingActivityChoice>[
  WritingActivityChoice(label: 'I wrote it', isSuccessful: true),
  WritingActivityChoice(label: 'I need more practice', isSuccessful: false),
];

bool isWritingSubject(String subject) {
  final normalized = subject.trim().toUpperCase();
  return normalized == 'WRITING' || normalized == 'HANDWRITING';
}

({int score, int total}) scoreForWritingChoice(int choiceIndex) {
  final isSuccessful =
      choiceIndex >= 0 &&
      choiceIndex < writingActivityChoices.length &&
      writingActivityChoices[choiceIndex].isSuccessful;
  return (score: isSuccessful ? 1 : 0, total: 1);
}

String writingActivityPrompt({
  required String grade,
  required String difficulty,
  required int nodeIndex,
}) {
  final levelNumber = nodeIndex + 1;
  return 'Use your printed $grade writing sheet for Level $levelNumber. '
      'Trace or write the assigned line, then choose how it went.';
}

String writingActivitySubPrompt() {
  return 'After writing on paper, pick one:';
}
