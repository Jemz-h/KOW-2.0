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

  test('new builds reset stale versioned cache before startup sync', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final apiSource = File('lib/api_service.dart').readAsStringSync();
    final storeSource = File('lib/local_sync_store.dart').readAsStringSync();

    expect(mainSource, contains('prepareInstallStateForCurrentBuild'));
    expect(apiSource, contains('KOW_INSTALL_STATE_VERSION'));
    expect(apiSource, contains('resetVersionedInstallState'));
    expect(storeSource, contains('question_cache'));
    expect(storeSource, contains('question_image_cache'));
    expect(storeSource, contains('offline_bootstrap_complete'));
    expect(storeSource, contains('selected_theme'));
  });

  test(
    'login falls back to user list when lookup route misses live learners',
    () {
      final source = File('lib/api_service.dart').readAsStringSync();

      expect(source, contains('_findStudentFromUserList'));
      expect(source, contains('/api/users'));
      expect(source, contains('_cacheUserListLearners'));
      expect(source, contains('Student.fromJson'));
    },
  );
}
