import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'first sync downloads learners through the offline bootstrap endpoint',
    () {
      final source = File('lib/api_service.dart').readAsStringSync();

      expect(source, contains('/api/bootstrap/offline'));
      expect(source, contains('saveSyncedStudent'));
      expect(source, contains('saveLocalLevelProgress'));
    },
  );
}
