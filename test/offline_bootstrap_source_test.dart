import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'first sync can complete from bundled seed when backend bootstrap is unavailable',
    () {
      final source = File('lib/api_service.dart').readAsStringSync();

      expect(source, contains('/api/bootstrap/offline'));
      expect(source, contains('_cacheBundledSeedQuestions'));
      expect(source, contains('_hasBundledSeedQuestions'));
      expect(source, contains('saveSyncedStudent'));
      expect(source, contains('saveLocalLevelProgress'));
    },
  );
}
