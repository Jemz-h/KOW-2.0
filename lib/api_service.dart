import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'api_config.dart';
import 'level_progression.dart';
import 'local_sync_store.dart';
import 'seeded_question_store.dart';
import 'student_model.dart';

/// API client.
class ApiService {
  ApiService._();

  static final _client = http.Client();
  static String get _base => ApiConfig.baseUrl;
  static const _requestTimeout = Duration(seconds: 12);
  static const _interactiveAuthTimeout = Duration(seconds: 5);
  static const _installStateVersion = String.fromEnvironment(
    'KOW_INSTALL_STATE_VERSION',
    defaultValue: '0.0.9+9-cache-v3',
  );
  static const _maxRetryAttempts = 3;
  static const _retryBaseDelay = Duration(milliseconds: 450);
  static final _uuid = Uuid();
  static final _deviceInfo = DeviceInfoPlugin();
  static int? _currentStudentId;
  static String? _currentNickname;
  static String? _currentBirthday;
  static String? _deviceUuid;
  static String? _deviceToken;
  static bool _supportsStudentAuthLogin = true;
  static String? _lastContentVersionTag;
  static bool _hasDeferredContentRefresh = false;
  static int _activeLearningSessions = 0;
  static bool _lastLoginWasOffline = false;
  static Timer? _contentPoller;
  static Future<void>? _oracleReconciliationTask;
  static String? _oracleReconciliationIdentity;
  static final Map<String, List<Map<String, dynamic>>> _questionCache = {};
  static const List<String> _bootstrapGrades = ['PUNLA', 'BINHI'];
  static const List<String> _bootstrapSubjects = [
    'MATHEMATICS',
    'SCIENCE',
    'FILIPINO',
    'ENGLISH',
  ];
  static const List<String> _bootstrapDifficulties = [
    'EASY',
    'AVERAGE',
    'HARD',
  ];

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_deviceToken != null) 'Authorization': 'Bearer $_deviceToken',
  };

  static Future<String> _resolveDeviceName() async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final model = androidInfo.model.trim();
      final manufacturer = androidInfo.manufacturer.trim();
      final release = androidInfo.version.release.trim();

      if (manufacturer.isNotEmpty && model.isNotEmpty) {
        final deviceName = '$manufacturer $model';
        return release.isEmpty ? deviceName : '$deviceName (Android $release)';
      }

      if (model.isNotEmpty) {
        return release.isEmpty ? model : '$model (Android $release)';
      }

      return 'KOW Device';
    } catch (_) {
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        final name = iosInfo.name.trim();
        if (name.isNotEmpty) {
          return name;
        }
      } catch (_) {
        // Fallback.
      }

      return 'KOW Device';
    }
  }

  static int? get currentStudentId => _currentStudentId;
  static bool get hasActiveSession {
    final nickname = _currentNickname?.trim();
    return nickname != null && nickname.isNotEmpty;
  }

  static String? get currentBirthday => _currentBirthday;

  static bool get lastLoginWasOffline => _lastLoginWasOffline;

  static Future<void> prepareInstallStateForCurrentBuild() async {
    final storedVersion = await LocalSyncStore.instance
        .getInstallStateVersion();
    if (storedVersion == _installStateVersion) {
      return;
    }

    await LocalSyncStore.instance.resetVersionedInstallState();
    await LocalSyncStore.instance.setInstallStateVersion(_installStateVersion);
    _lastContentVersionTag = null;
    _hasDeferredContentRefresh = false;
    _questionCache.clear();
  }

  static Future<bool> restoreSession() async {
    final session = await LocalSyncStore.instance.getActiveSession();
    if (session == null) {
      return false;
    }

    _currentStudentId = (session['student_id'] as num?)?.toInt();
    _currentNickname = (session['nickname'] as String?)?.trim();
    _currentBirthday = session['birthday'] as String?;

    if (_currentNickname == null || _currentNickname!.isEmpty) {
      return false;
    }

    startContentVersionPolling();
    unawaited(syncPending());
    _scheduleOracleReconciliation(
      nickname: _currentNickname!,
      birthday: _currentBirthday ?? '',
    );
    return true;
  }

  static Future<void> signOut() async {
    stopContentVersionPolling();
    _currentStudentId = null;
    _currentNickname = null;
    _currentBirthday = null;
    _lastContentVersionTag = null;
    _hasDeferredContentRefresh = false;
    _activeLearningSessions = 0;
    _questionCache.clear();
    await LocalSyncStore.instance.clearActiveSession();
  }

  static void beginLearningSession() {
    _activeLearningSessions++;
  }

  static Future<ContentRefreshStatus> endLearningSession() async {
    if (_activeLearningSessions > 0) {
      _activeLearningSessions--;
    }

    if (_activeLearningSessions > 0 || !_hasDeferredContentRefresh) {
      return const ContentRefreshStatus(
        deferred: false,
        upToDate: true,
        hasUpdate: false,
      );
    }

    return _refreshContentVersionState();
  }

  static Future<ContentRefreshStatus> checkContentVersion({
    bool deferIfSessionActive = true,
  }) async {
    await _tryEnsureDeviceAuth();

    if (_deviceToken == null || _deviceToken!.isEmpty) {
      return const ContentRefreshStatus(
        deferred: false,
        upToDate: true,
        hasUpdate: false,
      );
    }

    if (deferIfSessionActive && _activeLearningSessions > 0) {
      _hasDeferredContentRefresh = true;
      return const ContentRefreshStatus(
        deferred: true,
        upToDate: true,
        hasUpdate: false,
      );
    }

    return _refreshContentVersionState();
  }

  static void startContentVersionPolling({
    Duration interval = const Duration(minutes: 2),
  }) {
    _contentPoller?.cancel();
    _contentPoller = Timer.periodic(interval, (_) {
      checkContentVersion();
    });
  }

  static void stopContentVersionPolling() {
    _contentPoller?.cancel();
    _contentPoller = null;
  }

  // ── Auth ──────────────────────────────────────────────────────────────

  /// Register a learner.
  static Future<void> register({
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    final hasOnlineLogin = await LocalSyncStore.instance.hasOnlineLogin();
    final canReach = await canReachServer();
    if (!hasOnlineLogin && !canReach) {
      throw const ApiException(
        503,
        'Please connect to the internet before signing up on this device.',
      );
    }

    if (!canReach && hasOnlineLogin) {
      await LocalSyncStore.instance.queueOfflineRegistration(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );

      _currentStudentId = null;
      _currentNickname = nickname;
      _currentBirthday = birthday;
      await LocalSyncStore.instance.saveActiveSession(
        studentId: null,
        nickname: nickname,
        birthday: birthday,
      );

      unawaited(syncPending());
      return;
    }

    try {
      final studentId = await _registerRemote(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );
      if (studentId == null) {
        throw const ApiException(
          502,
          'Sign-up reached the server but did not return a learner ID. Please try again.',
        );
      }
      _currentStudentId = studentId;
      _currentNickname = nickname;
      _currentBirthday = birthday;
      await LocalSyncStore.instance.saveActiveSession(
        studentId: studentId,
        nickname: nickname,
        birthday: birthday,
      );

      await LocalSyncStore.instance.saveSyncedStudent(
        student: Student(
          studentId: studentId,
          firstName: firstName,
          lastName: lastName,
          nickname: nickname,
          sex: sex,
          area: area,
          totalScore: 0,
        ),
        birthday: birthday,
      );

      await LocalSyncStore.instance.setHasOnlineLogin(true);

      startContentVersionPolling();
      unawaited(syncPending());
    } on ApiException catch (e) {
      if (!_isConnectivityException(e)) {
        rethrow;
      }

      if (!hasOnlineLogin) {
        throw const ApiException(
          503,
          'Please connect to the internet before signing up on this device.',
        );
      }

      await LocalSyncStore.instance.queueOfflineRegistration(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );

      // Local-only registration succeeded while backend is unreachable.
      _currentStudentId = null;
      _currentNickname = nickname;
      _currentBirthday = birthday;
      await LocalSyncStore.instance.saveActiveSession(
        studentId: null,
        nickname: nickname,
        birthday: birthday,
      );

      // Continue as a successful sign-up so the app flow matches online behavior.
      unawaited(syncPending());
      return;
    }
  }

  /// Login with nickname + birthday (birthday is the password).
  /// Returns the authenticated [Student].
  static Future<Student> login({
    required String nickname,
    required String birthday,
  }) async {
    final normalizedNickname = nickname.trim();
    final normalizedBirthday = _normalizeBirthday(birthday);
    _lastLoginWasOffline = false;

    final hasOnlineLogin = await LocalSyncStore.instance.hasOnlineLogin();
    final canReach = await canReachServer(timeout: const Duration(seconds: 4));
    if (!canReach && !hasOnlineLogin) {
      throw const ApiException(
        503,
        'Please connect to the internet before signing in on this device.',
      );
    }

    if (!canReach && hasOnlineLogin) {
      final offlineStudent = await LocalSyncStore.instance.findOfflineStudent(
        nickname: normalizedNickname,
        birthday: normalizedBirthday,
      );

      if (offlineStudent != null) {
        _currentStudentId = offlineStudent.studentId;
        _currentNickname = offlineStudent.nickname;
        _currentBirthday = _normalizeBirthday(normalizedBirthday);
        await LocalSyncStore.instance.saveActiveSession(
          studentId: offlineStudent.studentId,
          nickname: offlineStudent.nickname,
          birthday: _currentBirthday!,
        );
        startContentVersionPolling();
        unawaited(syncPending());
        _lastLoginWasOffline = true;
        return offlineStudent;
      }

      throw const ApiException(
        401,
        'No offline login data found. Connect to the internet to sign in.',
      );
    }

    // Ensure lookup-capable backends receive a device token before login attempts.
    await _tryEnsureDeviceAuth();
    await syncPending();

    // The live KOW backend exposes lookup-based student login, not /api/auth/login.
    _supportsStudentAuthLogin = false;

    ApiException? loginError;

    if (_supportsStudentAuthLogin) {
      try {
        final res = await _sendWithTimeout(
          _client.post(
            Uri.parse('$_base/api/auth/login'),
            headers: _headers,
            body: jsonEncode({
              'nickname': normalizedNickname,
              'birthday': normalizedBirthday,
            }),
          ),
          timeout: _interactiveAuthTimeout,
        );
        _checkStatus(res);
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final student = Student.fromJson(
          body['student'] as Map<String, dynamic>,
        );
        final resolvedBirthday = _normalizeBirthday(
          student.birthday == null || student.birthday!.isEmpty
              ? normalizedBirthday
              : student.birthday!,
        );
        _currentStudentId = student.studentId;
        _currentNickname = student.nickname.isEmpty
            ? normalizedNickname
            : student.nickname;
        _currentBirthday = resolvedBirthday;
        await LocalSyncStore.instance.saveActiveSession(
          studentId: student.studentId,
          nickname: _currentNickname!,
          birthday: resolvedBirthday,
        );
        startContentVersionPolling();
        unawaited(syncPending());

        await LocalSyncStore.instance.saveSyncedStudent(
          student: student,
          birthday: resolvedBirthday,
        );

        await LocalSyncStore.instance.setHasOnlineLogin(true);
        unawaited(getProgress(student.studentId));

        _scheduleOracleReconciliation(
          nickname: _currentNickname!,
          birthday: resolvedBirthday,
        );

        return student;
      } on ApiException catch (e) {
        loginError = e;
        if (e.statusCode == 404) {
          // PM2 kow-backend exposes lookup-based student login only.
          _supportsStudentAuthLogin = false;
        }
      }
    }

    ApiException? lookupError;
    var lookupCompletedOnline = false;
    final shouldAttemptLookupFallback =
        !_supportsStudentAuthLogin ||
        loginError == null ||
        loginError.statusCode == 400 ||
        loginError.statusCode == 404;
    if (shouldAttemptLookupFallback) {
      try {
        final lookupCandidates = _nicknameCandidates(normalizedNickname);
        Map<String, dynamic>? lookupBody;

        for (final candidate in lookupCandidates) {
          final lookupRes = await _sendWithTimeout(
            _client.post(
              Uri.parse('$_base/api/students/lookup'),
              headers: _headers,
              body: jsonEncode({
                'nickname': candidate,
                'birthday': normalizedBirthday,
              }),
            ),
            timeout: _interactiveAuthTimeout,
          );
          _checkStatus(lookupRes);
          lookupCompletedOnline = true;

          final parsed = jsonDecode(lookupRes.body) as Map<String, dynamic>;
          if (parsed['found'] == true) {
            lookupBody = parsed;
            break;
          }
        }

        if (lookupBody != null && lookupBody['found'] == true) {
          final resolvedBirthday = _normalizeBirthday(normalizedBirthday);
          final resolvedStudentId =
              _parseStudentId(lookupBody['stud_id']) ??
              _parseStudentId(lookupBody['student_id']) ??
              _parseStudentId(
                (lookupBody['student'] as Map<String, dynamic>?)?['STUDENT_ID'],
              ) ??
              _parseStudentId(
                (lookupBody['student'] as Map<String, dynamic>?)?['student_id'],
              );
          if (resolvedStudentId == null || resolvedStudentId <= 0) {
            throw const ApiException(
              404,
              'Student lookup did not return a valid ID.',
            );
          }
          final resolvedNickname =
              (lookupBody['nickname'] as String?)?.trim().isNotEmpty == true
              ? (lookupBody['nickname'] as String).trim()
              : normalizedNickname;

          _currentStudentId = resolvedStudentId;
          _currentNickname = resolvedNickname;
          _currentBirthday = resolvedBirthday;

          await LocalSyncStore.instance.saveActiveSession(
            studentId: resolvedStudentId,
            nickname: resolvedNickname,
            birthday: resolvedBirthday,
          );

          startContentVersionPolling();
          unawaited(syncPending());

          final fallbackStudent = Student(
            studentId: resolvedStudentId,
            firstName: (lookupBody['first_name'] as String?) ?? '',
            lastName: (lookupBody['last_name'] as String?) ?? '',
            nickname: resolvedNickname,
            sex: ((lookupBody['sex'] as String?) ?? 'Unknown').trim(),
            area: (lookupBody['area'] as String?)?.isEmpty == true
                ? null
                : lookupBody['area'] as String?,
            birthday: resolvedBirthday,
            totalScore: 0,
          );

          await LocalSyncStore.instance.saveSyncedStudent(
            student: fallbackStudent,
            birthday: resolvedBirthday,
          );

          await LocalSyncStore.instance.setHasOnlineLogin(true);
          unawaited(getProgress(resolvedStudentId));

          _scheduleOracleReconciliation(
            nickname: resolvedNickname,
            birthday: resolvedBirthday,
          );

          return fallbackStudent;
        }
      } on ApiException catch (e) {
        lookupError = e;
        // Continue to local/offline fallback.
      }
    }

    try {
      final userListStudent = await _findStudentFromUserList(
        nickname: normalizedNickname,
        birthday: normalizedBirthday,
      );
      if (userListStudent != null) {
        final resolvedBirthday = _normalizeBirthday(
          userListStudent.birthday ?? normalizedBirthday,
        );
        _currentStudentId = userListStudent.studentId;
        _currentNickname = userListStudent.nickname.isEmpty
            ? normalizedNickname
            : userListStudent.nickname;
        _currentBirthday = resolvedBirthday;

        await LocalSyncStore.instance.saveSyncedStudent(
          student: userListStudent,
          birthday: resolvedBirthday,
        );
        await LocalSyncStore.instance.saveActiveSession(
          studentId: userListStudent.studentId,
          nickname: _currentNickname!,
          birthday: resolvedBirthday,
        );

        startContentVersionPolling();
        unawaited(syncPending());
        _scheduleOracleReconciliation(
          nickname: _currentNickname!,
          birthday: resolvedBirthday,
        );

        return userListStudent;
      }
    } on ApiException catch (e) {
      lookupError ??= e;
    }

    final offlineStudent = await LocalSyncStore.instance.findOfflineStudent(
      nickname: normalizedNickname,
      birthday: normalizedBirthday,
    );

    if (offlineStudent != null) {
      _currentStudentId = offlineStudent.studentId;
      _currentNickname = offlineStudent.nickname;
      _currentBirthday = _normalizeBirthday(normalizedBirthday);
      await LocalSyncStore.instance.saveActiveSession(
        studentId: offlineStudent.studentId,
        nickname: offlineStudent.nickname,
        birthday: _currentBirthday!,
      );
      startContentVersionPolling();
      unawaited(syncPending());
      return offlineStudent;
    }

    if (lookupCompletedOnline) {
      throw const ApiException(
        401,
        'Live login failed: account was not found on the server.',
      );
    }

    if (lookupError != null && !_isConnectivityException(lookupError)) {
      throw lookupError;
    }

    if (loginError != null &&
        !_isConnectivityException(loginError) &&
        loginError.statusCode != 400 &&
        loginError.statusCode != 404) {
      throw loginError;
    }

    throw const ApiException(
      401,
      'Live login failed: account was not found on the server.',
    );
  }

  /// Returns best-known current student profile data from local cache.
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    if (_currentNickname != null && _currentBirthday != null) {
      final byIdentity = await LocalSyncStore.instance
          .getStudentProfileByIdentity(
            nickname: _currentNickname!,
            birthday: _currentBirthday!,
          );
      if (byIdentity != null) {
        final id = byIdentity['student_id'];
        if (id is num) {
          _currentStudentId = id.toInt();
        }
        return byIdentity;
      }
    }

    if (_currentStudentId != null) {
      final byId = await LocalSyncStore.instance.getStudentProfileById(
        _currentStudentId!,
      );
      if (byId != null) {
        return byId;
      }
    }

    if (_currentNickname != null && _currentBirthday != null) {
      final offlineStudent = await LocalSyncStore.instance.findOfflineStudent(
        nickname: _currentNickname!,
        birthday: _currentBirthday!,
      );
      if (offlineStudent != null) {
        _currentStudentId = offlineStudent.studentId;
        return {
          'student_id': offlineStudent.studentId,
          'first_name': offlineStudent.firstName,
          'last_name': offlineStudent.lastName,
          'nickname': offlineStudent.nickname,
          'birthday': _currentBirthday,
          'sex': offlineStudent.sex,
          'area': offlineStudent.area,
        };
      }
    }

    if (_currentNickname == null && _currentBirthday == null) {
      return LocalSyncStore.instance.getMostRecentStudentProfile();
    }

    return null;
  }

  static Future<void> syncPending() async {
    try {
      await _tryEnsureDeviceAuth();

      if (_deviceToken == null || _deviceToken!.isEmpty) {
        return;
      }

      await _runWithRetry(
        () => LocalSyncStore.instance.syncPendingRegistrations(
          registerRemote: _registerRemote,
        ),
        shouldRetry: _isRetryableSyncError,
      );

      await _runWithRetry(
        () => LocalSyncStore.instance.syncPendingScores(
          submitScoreRemote: _submitScoreRemote,
        ),
        shouldRetry: _isRetryableSyncError,
      );

      await _runWithRetry(
        () => LocalSyncStore.instance.syncPendingProgress(
          submitProgressRemote: _saveProgressRemote,
        ),
        shouldRetry: _isRetryableSyncError,
      );

      await _runWithRetry(
        () => LocalSyncStore.instance.syncPendingProfileUpdates(
          updateProfileRemote: _updateProfileRemote,
        ),
        shouldRetry: _isRetryableSyncError,
      );
    } catch (_) {
      // Best-effort sync only; queue remains for next cycle.
    }
  }

  static Future<bool> isOfflineBootstrapComplete() {
    return LocalSyncStore.instance.isOfflineBootstrapComplete();
  }

  static Future<bool> canReachServer({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!await _hasNetworkTransport()) {
      return false;
    }

    try {
      final res = await _client
          .get(Uri.parse('$_base/health'))
          .timeout(timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<void> bootstrapOfflineData() async {
    await _ensureDeviceAuth();
    await syncPending();

    var hasCachedLearners = false;
    var learners = const <Map<String, dynamic>>[];
    try {
      final bootstrapPayload = await _fetchOfflineBootstrap();
      hasCachedLearners = await _cacheOfflineBootstrap(bootstrapPayload);
      learners = _extractLearnersFromBootstrap(bootstrapPayload);
    } on ApiException catch (e) {
      if (!_isLegacyEndpointFallbackError(e)) {
        rethrow;
      }
    }

    if (!hasCachedLearners) {
      final result = await _cacheUserListLearners();
      hasCachedLearners = result.cachedAny;
      learners = result.learners;
    }

    await _cacheLearnerProgressSnapshots(learners);

    var hasPlayableQuestions = false;
    try {
      final remoteResult = await _fetchAllRemoteQuestions();
      if (remoteResult.rows.isNotEmpty) {
        await _cacheQuestionGroups(
          rows: remoteResult.rows,
          contentVersion: remoteResult.versionTag,
        );
        hasPlayableQuestions = true;
      }
    } on ApiException catch (e) {
      if (!_isLegacyEndpointFallbackError(e) && !_isConnectivityException(e)) {
        rethrow;
      }
    }

    if (!hasPlayableQuestions) {
      hasPlayableQuestions = await _cacheBundledSeedQuestions();
    }

    if (!hasPlayableQuestions) {
      throw const ApiException(
        503,
        'No playable question content is available on this device.',
      );
    }

    if (!hasCachedLearners) {
      throw const ApiException(
        503,
        'No learner login cache is available on this device.',
      );
    }

    await LocalSyncStore.instance.setOfflineBootstrapComplete(true);
    await LocalSyncStore.instance.setHasOnlineLogin(true);
    await LocalSyncStore.instance.setAutoSyncListenerEnabled(true);
  }

  static Future<Map<String, dynamic>> _fetchOfflineBootstrap() async {
    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.get(
          Uri.parse('$_base/api/bootstrap/offline'),
          headers: _headers,
        ),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return const <String, dynamic>{};
  }

  static Future<bool> _cacheOfflineBootstrap(
    Map<String, dynamic> payload,
  ) async {
    var cachedLearners = false;
    final learners = payload['learners'];
    if (learners is List) {
      for (final rawLearner in learners) {
        if (rawLearner is! Map) {
          continue;
        }

        final learner = Map<String, dynamic>.from(rawLearner);
        final birthday = _normalizeBirthday(
          _asString(learner['birthday']) ?? '',
        );
        final student = Student.fromJson(learner);

        if (student.studentId <= 0 ||
            student.nickname.trim().isEmpty ||
            birthday.isEmpty) {
          continue;
        }

        await LocalSyncStore.instance.saveSyncedStudent(
          student: student,
          birthday: birthday,
        );
        cachedLearners = true;
      }
    }

    await _cacheProgressRows(_readListMap(payload['progress']));

    return cachedLearners;
  }

  static List<Map<String, dynamic>> _extractLearnersFromBootstrap(
    Map<String, dynamic> payload,
  ) {
    return _readListMap(payload['learners'] ?? payload['students']);
  }

  static Future<_LearnerCacheResult> _cacheUserListLearners() async {
    final learners = await _fetchUserListLearners();
    var cachedAny = false;

    for (final learner in learners) {
      final birthday = _normalizeBirthday(_asString(learner['birthday']) ?? '');
      final student = Student.fromJson(learner);
      if (student.studentId <= 0 ||
          student.nickname.trim().isEmpty ||
          birthday.isEmpty) {
        continue;
      }

      await LocalSyncStore.instance.saveSyncedStudent(
        student: student,
        birthday: birthday,
      );
      cachedAny = true;
    }

    return _LearnerCacheResult(cachedAny: cachedAny, learners: learners);
  }

  static Future<void> _cacheLearnerProgressSnapshots(
    List<Map<String, dynamic>> learners,
  ) async {
    for (final learner in learners) {
      final studentId =
          _parseStudentId(learner['stud_id']) ??
          _parseStudentId(learner['student_id']);
      if (studentId == null || studentId <= 0) {
        continue;
      }

      try {
        await getProgress(studentId);
      } on ApiException catch (e) {
        if (!_isConnectivityException(e) &&
            !_isLegacyEndpointFallbackError(e) &&
            e.statusCode != 401 &&
            e.statusCode != 403) {
          rethrow;
        }
      }
    }
  }

  static Future<Student?> _findStudentFromUserList({
    required String nickname,
    required String birthday,
  }) async {
    final normalizedNickname = nickname.trim().toLowerCase();
    final normalizedBirthday = _normalizeBirthday(birthday);
    final learners = await _fetchUserListLearners();

    for (final learner in learners) {
      final learnerNickname = (_asString(learner['nickname']) ?? '')
          .trim()
          .toLowerCase();
      final learnerBirthday = _normalizeBirthday(
        _asString(learner['birthday']) ?? '',
      );
      if (learnerNickname != normalizedNickname ||
          learnerBirthday != normalizedBirthday) {
        continue;
      }

      final student = Student.fromJson(learner);
      if (student.studentId > 0 && student.nickname.trim().isNotEmpty) {
        return student;
      }
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> _fetchUserListLearners() async {
    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.get(Uri.parse('$_base/api/users'), headers: _headers),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);

    final decoded = jsonDecode(res.body);
    final rawUsers = decoded is Map<String, dynamic>
        ? decoded['users']
        : decoded is List
        ? decoded
        : null;

    if (rawUsers is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawUsers
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _readListMap(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }
    return value
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  /// Update student profile information.
  static Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    int? studentId = _currentStudentId;
    if (studentId == null) {
      final profile = await getCurrentProfile();
      final profileId = profile?['student_id'];
      if (profileId is num) {
        studentId = profileId.toInt();
        _currentStudentId = studentId;
      }
    }

    if (studentId == null) {
      throw const ApiException(401, 'No active student profile found');
    }

    final normalizedBirthday = _normalizeBirthday(birthday);

    await LocalSyncStore.instance.updateLocalStudentProfile(
      studentId: studentId,
      firstName: firstName,
      lastName: lastName,
      nickname: nickname,
      birthday: normalizedBirthday,
      sex: sex,
      area: area,
    );

    _currentNickname = nickname;
    _currentBirthday = normalizedBirthday;
    await LocalSyncStore.instance.saveActiveSession(
      studentId: studentId,
      nickname: nickname,
      birthday: normalizedBirthday,
    );

    try {
      await _tryEnsureDeviceAuth();

      await _updateProfileRemote(
        studentId: studentId,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: normalizedBirthday,
        sex: sex,
        area: area,
      );

      await syncPending();
    } on ApiException catch (e) {
      if (_isConnectivityException(e)) {
        await LocalSyncStore.instance.queueOfflineProfileUpdate(
          studentId: studentId,
          firstName: firstName,
          lastName: lastName,
          nickname: nickname,
          birthday: normalizedBirthday,
          sex: sex,
          area: area,
        );
        return;
      }
      rethrow;
    }
  }

  // ── Quiz ──────────────────────────────────────────────────────────────

  /// Fetch quiz questions for a grade / subject / difficulty.
  static Future<List<Map<String, dynamic>>> getQuestions({
    required String grade,
    required String subject,
    String? difficulty,
  }) async {
    final normalizedDifficulty = _normalizeQuestionDifficulty(difficulty);
    final normalizedSubject = _normalizeSubject(subject);
    final cacheKey = _questionCacheKey(
      grade: grade,
      subject: normalizedSubject,
      difficulty: normalizedDifficulty,
    );

    final cachedRows = await _loadLocalQuestionRows(
      cacheKey: cacheKey,
      grade: grade,
      subject: normalizedSubject,
      difficulty: normalizedDifficulty,
      includeSeed: false,
    );
    if (cachedRows.isNotEmpty) {
      final hydratedRows = await _hydrateQuestionImages(
        cachedRows,
        awaitDownloads: await _hasNetworkTransport(),
      );
      _questionCache[cacheKey] = hydratedRows;
      await LocalSyncStore.instance.saveCachedQuestionRows(
        cacheKey: cacheKey,
        rows: hydratedRows,
        contentVersion: _lastContentVersionTag,
      );
      unawaited(
        _refreshQuestionsCache(
          cacheKey: cacheKey,
          grade: grade,
          subject: normalizedSubject,
          difficulty: normalizedDifficulty,
        ),
      );
      return hydratedRows;
    }

    if (!await _hasNetworkTransport()) {
      final localRows = await _loadLocalQuestionRows(
        cacheKey: cacheKey,
        grade: grade,
        subject: normalizedSubject,
        difficulty: normalizedDifficulty,
      );
      if (localRows.isNotEmpty) {
        return localRows;
      }
    } else if (!await canReachServer(timeout: const Duration(seconds: 2))) {
      final localRows = await _loadLocalQuestionRows(
        cacheKey: cacheKey,
        grade: grade,
        subject: normalizedSubject,
        difficulty: normalizedDifficulty,
      );
      if (localRows.isNotEmpty) {
        return localRows;
      }
      return const <Map<String, dynamic>>[];
    }

    return _refreshQuestionsCache(
      cacheKey: cacheKey,
      grade: grade,
      subject: normalizedSubject,
      difficulty: normalizedDifficulty,
    );
  }

  static Future<List<Map<String, dynamic>>> _loadLocalQuestionRows({
    required String cacheKey,
    required String grade,
    required String subject,
    String? difficulty,
    bool includeSeed = true,
  }) async {
    final previousRows = _questionCache[cacheKey];
    if (previousRows != null && previousRows.isNotEmpty) {
      return previousRows;
    }

    final persistedRows = await LocalSyncStore.instance.getCachedQuestionRows(
      cacheKey,
    );
    if (persistedRows.isNotEmpty) {
      _questionCache[cacheKey] = persistedRows;
      return persistedRows;
    }

    if (!includeSeed) {
      return const <Map<String, dynamic>>[];
    }

    final localRows = await SeededQuestionStore.instance.getQuestions(
      grade: grade,
      subject: subject,
      difficulty: difficulty,
    );
    if (localRows.isNotEmpty) {
      _questionCache[cacheKey] = localRows;
      return localRows;
    }

    return const <Map<String, dynamic>>[];
  }

  static Future<List<Map<String, dynamic>>> _refreshQuestionsCache({
    required String cacheKey,
    required String grade,
    required String subject,
    String? difficulty,
  }) async {
    try {
      final remoteResult = await _fetchRemoteQuestions(
        grade: grade,
        subject: subject,
        difficulty: difficulty,
      );
      _questionCache[cacheKey] = remoteResult.rows;
      await LocalSyncStore.instance.saveCachedQuestionRows(
        cacheKey: cacheKey,
        rows: remoteResult.rows,
        contentVersion: remoteResult.versionTag,
      );
      return remoteResult.rows;
    } catch (_) {
      // Fall back to the last successful remote payload, then bundled seed.
    }

    final localRows = await _loadLocalQuestionRows(
      cacheKey: cacheKey,
      grade: grade,
      subject: subject,
      difficulty: difficulty,
    );
    if (localRows.isNotEmpty) {
      return localRows;
    }

    _questionCache.remove(cacheKey);
    return const <Map<String, dynamic>>[];
  }

  static Future<_RemoteQuestionResult> _fetchRemoteQuestions({
    required String grade,
    required String subject,
    String? difficulty,
  }) async {
    await _tryEnsureDeviceAuth();

    final uri = Uri.parse('$_base/api/content');

    final res = await _runWithRetry(
      () => _sendWithTimeout(_client.get(uri, headers: _headers)),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);

    final decoded = jsonDecode(res.body);
    List<dynamic>? rawQuestions;

    if (decoded is Map<String, dynamic>) {
      final versionTag =
          _asString(decoded['version_tag']) ?? _asString(decoded['versionTag']);
      if (versionTag != null) {
        _lastContentVersionTag = versionTag;
      }

      rawQuestions = _extractQuestionsFromContentPayload(decoded);
    } else if (decoded is List) {
      rawQuestions = decoded;
    }

    if (rawQuestions == null || rawQuestions.isEmpty) {
      return _RemoteQuestionResult(
        rows: const <Map<String, dynamic>>[],
        versionTag: _lastContentVersionTag,
      );
    }

    final gradeLevelId = _gradeLevelIdFor(grade);
    final subjectId = _subjectIdFor(subject);
    final diffId = _difficultyIdFor(difficulty);

    final filteredRows = rawQuestions
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map(_mapContentQuestionToQuizRow)
        .where((row) => row.isNotEmpty)
        .where((row) {
          final rowGradeLevelId = _asInt(row['gradelvl_id']);
          final rowSubjectId = _asInt(row['subject_id']);
          final rowDiffId = _asInt(row['diff_id']);
          final rowGradeLevelName = _asString(row['gradelvl']);
          final rowSubjectName = _asString(row['subject']);
          final rowDifficultyName = _asString(row['difficulty']);

          final resolvedGradeLevelId =
              rowGradeLevelId ?? _safeGradeLevelIdFor(rowGradeLevelName);
          final resolvedSubjectId =
              rowSubjectId ?? _safeSubjectIdFor(rowSubjectName);
          final resolvedDiffId =
              rowDiffId ?? _safeDifficultyIdFor(rowDifficultyName);

          return resolvedGradeLevelId == gradeLevelId &&
              resolvedSubjectId == subjectId &&
              (diffId == null || resolvedDiffId == diffId);
        })
        .toList(growable: false);

    final hydratedRows = await _hydrateQuestionImages(filteredRows);
    return _RemoteQuestionResult(
      rows: hydratedRows,
      versionTag: _lastContentVersionTag,
    );
  }

  static Future<_RemoteQuestionResult> _fetchAllRemoteQuestions() async {
    await _ensureDeviceAuth();

    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.get(Uri.parse('$_base/api/content'), headers: _headers),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      return _RemoteQuestionResult(
        rows: const <Map<String, dynamic>>[],
        versionTag: _lastContentVersionTag,
      );
    }

    final versionTag =
        _asString(decoded['version_tag']) ?? _asString(decoded['versionTag']);
    if (versionTag != null) {
      _lastContentVersionTag = versionTag;
    }

    final rawQuestions = _extractQuestionsFromContentPayload(decoded);
    if (rawQuestions == null || rawQuestions.isEmpty) {
      return _RemoteQuestionResult(
        rows: const <Map<String, dynamic>>[],
        versionTag: _lastContentVersionTag,
      );
    }

    final rows = rawQuestions
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .map(_mapContentQuestionToQuizRow)
        .where((row) => row.isNotEmpty)
        .toList(growable: false);

    return _RemoteQuestionResult(
      rows: await _hydrateQuestionImages(
        rows,
        awaitDownloads: true,
        requireDownloads: true,
      ),
      versionTag: _lastContentVersionTag,
    );
  }

  static Future<void> _cacheQuestionGroups({
    required List<Map<String, dynamic>> rows,
    String? contentVersion,
  }) async {
    _questionCache.clear();

    for (final grade in _bootstrapGrades) {
      for (final subject in _bootstrapSubjects) {
        final allRows = _filterQuestionRows(
          rows: rows,
          grade: grade,
          subject: subject,
        );
        final allKey = _questionCacheKey(grade: grade, subject: subject);
        if (allRows.isNotEmpty) {
          _questionCache[allKey] = allRows;
          await LocalSyncStore.instance.saveCachedQuestionRows(
            cacheKey: allKey,
            rows: allRows,
            contentVersion: contentVersion,
          );
        }

        for (final difficulty in _bootstrapDifficulties) {
          final difficultyRows = _filterQuestionRows(
            rows: rows,
            grade: grade,
            subject: subject,
            difficulty: difficulty,
          );
          final key = _questionCacheKey(
            grade: grade,
            subject: subject,
            difficulty: difficulty,
          );
          if (difficultyRows.isNotEmpty) {
            _questionCache[key] = difficultyRows;
            await LocalSyncStore.instance.saveCachedQuestionRows(
              cacheKey: key,
              rows: difficultyRows,
              contentVersion: contentVersion,
            );
          }
        }
      }
    }
  }

  static Future<bool> _cacheBundledSeedQuestions() async {
    var cachedAny = false;

    for (final grade in _bootstrapGrades) {
      for (final subject in _bootstrapSubjects) {
        for (final difficulty in _bootstrapDifficulties) {
          final rows = await SeededQuestionStore.instance.getQuestions(
            grade: grade,
            subject: subject,
            difficulty: difficulty,
          );
          if (rows.isEmpty) {
            continue;
          }

          final key = _questionCacheKey(
            grade: grade,
            subject: subject,
            difficulty: difficulty,
          );
          _questionCache[key] = rows;
          await LocalSyncStore.instance.saveCachedQuestionRows(
            cacheKey: key,
            rows: rows,
            contentVersion: 'bundled-seed',
          );
          cachedAny = true;
        }

        final allRows = await SeededQuestionStore.instance.getQuestions(
          grade: grade,
          subject: subject,
        );
        if (allRows.isEmpty) {
          continue;
        }

        final allKey = _questionCacheKey(grade: grade, subject: subject);
        _questionCache[allKey] = allRows;
        await LocalSyncStore.instance.saveCachedQuestionRows(
          cacheKey: allKey,
          rows: allRows,
          contentVersion: 'bundled-seed',
        );
        cachedAny = true;
      }
    }

    return cachedAny && await _hasBundledSeedQuestions();
  }

  static Future<bool> _hasBundledSeedQuestions() async {
    for (final grade in _bootstrapGrades) {
      for (final subject in _bootstrapSubjects) {
        final rows = await SeededQuestionStore.instance.getQuestions(
          grade: grade,
          subject: subject,
          difficulty: 'EASY',
        );
        if (rows.isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  static List<Map<String, dynamic>> _filterQuestionRows({
    required List<Map<String, dynamic>> rows,
    required String grade,
    required String subject,
    String? difficulty,
  }) {
    final gradeLevelId = _gradeLevelIdFor(grade);
    final subjectId = _subjectIdFor(subject);
    final diffId = _difficultyIdFor(difficulty);

    return rows
        .where((row) {
          final rowGradeLevelId =
              _asInt(row['gradelvl_id']) ??
              _safeGradeLevelIdFor(_asString(row['gradelvl']));
          final rowSubjectId =
              _asInt(row['subject_id']) ??
              _safeSubjectIdFor(_asString(row['subject']));
          final rowDiffId =
              _asInt(row['diff_id']) ??
              _safeDifficultyIdFor(_asString(row['difficulty']));

          return rowGradeLevelId == gradeLevelId &&
              rowSubjectId == subjectId &&
              (diffId == null || rowDiffId == diffId);
        })
        .toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> _hydrateQuestionImages(
    List<Map<String, dynamic>> rows, {
    bool awaitDownloads = false,
    bool requireDownloads = false,
  }) async {
    if (rows.isEmpty) {
      return rows;
    }

    final hydrated = <Map<String, dynamic>>[];
    for (final row in rows) {
      final copy = Map<String, dynamic>.from(row);
      final questionId = _asInt(copy['id']) ?? _asInt(copy['question_id']);
      final imageUrl =
          _asString(copy['imagePath']) ?? _asString(copy['image_url']);

      if (questionId != null &&
          imageUrl != null &&
          _isNetworkImageUrl(imageUrl)) {
        final cachedBytes = await LocalSyncStore.instance
            .getCachedQuestionImage(questionId: questionId, imageUrl: imageUrl);

        if (cachedBytes != null && cachedBytes.isNotEmpty) {
          copy['imageBlob'] = base64Encode(cachedBytes);
        } else if (awaitDownloads) {
          final downloadedBytes = await _downloadAndCacheQuestionImage(
            questionId: questionId,
            imageUrl: imageUrl,
          );
          if (downloadedBytes != null && downloadedBytes.isNotEmpty) {
            copy['imageBlob'] = base64Encode(downloadedBytes);
          } else if (requireDownloads) {
            throw ApiException(
              503,
              'Question image is not available offline yet: $imageUrl',
            );
          }
        } else {
          unawaited(
            _downloadAndCacheQuestionImage(
              questionId: questionId,
              imageUrl: imageUrl,
            ),
          );
        }
      }

      hydrated.add(copy);
    }

    return hydrated;
  }

  static bool _isNetworkImageUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static Future<Uint8List?> _downloadAndCacheQuestionImage({
    required int questionId,
    required String imageUrl,
  }) async {
    try {
      final res = await _client
          .get(Uri.parse(imageUrl))
          .timeout(_requestTimeout);
      if (res.statusCode < 200 ||
          res.statusCode >= 300 ||
          res.bodyBytes.isEmpty) {
        return null;
      }

      await LocalSyncStore.instance.saveCachedQuestionImage(
        questionId: questionId,
        imageUrl: imageUrl,
        imageBytes: res.bodyBytes,
        mimeType: res.headers['content-type'],
      );
      return res.bodyBytes;
    } catch (_) {
      // Image cache warming is best-effort; gameplay can still use the CDN URL.
      return null;
    }
  }

  static String _questionCacheKey({
    required String grade,
    required String subject,
    String? difficulty,
  }) {
    final difficultyKey = (difficulty != null && difficulty.trim().isNotEmpty)
        ? difficulty.trim().toUpperCase()
        : 'ALL';
    return '${grade.trim().toUpperCase()}|${subject.trim().toUpperCase()}|$difficultyKey';
  }

  /// Submit a quiz score.
  static Future<void> submitScore({
    required int studentId,
    required String grade,
    required String subject,
    required String difficulty,
    required int score,
    required int total,
    String? playedAt,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);
    final normalizedDifficulty = _normalizeDifficultyForServer(difficulty);
    final playedAtValue = playedAt ?? DateTime.now().toIso8601String();

    try {
      await _submitScoreRemote(
        studentId: studentId,
        grade: grade,
        subject: normalizedSubject,
        difficulty: normalizedDifficulty,
        score: score,
        total: total,
        playedAt: playedAtValue,
      );

      // Also attempt to flush any older queued writes.
      await syncPending();
    } on ApiException catch (e) {
      if (!_isConnectivityException(e)) {
        rethrow;
      }

      await LocalSyncStore.instance.queueOfflineScore(
        studentId: studentId,
        grade: grade,
        subject: normalizedSubject,
        difficulty: normalizedDifficulty,
        score: score,
        total: total,
        playedAt: playedAtValue,
      );
    }
  }

  /// Fetch all scores for a student.
  static Future<List<Map<String, dynamic>>> getScores(int studentId) async {
    List<Map<String, dynamic>> remoteRows = const <Map<String, dynamic>>[];

    try {
      final res = await _sendWithTimeout(
        _client.get(
          Uri.parse('$_base/api/quiz/scores/$studentId'),
          headers: _headers,
        ),
      );
      _checkStatus(res);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rows = body['scores'] ?? body['data'] ?? const <dynamic>[];
      if (rows is List) {
        remoteRows = rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList(growable: false);
      }
    } on ApiException catch (e) {
      if (e.statusCode != 404 &&
          e.statusCode != 400 &&
          !_isConnectivityException(e)) {
        rethrow;
      }
    }

    final pending = await LocalSyncStore.instance.getPendingScoresForStudent(
      studentId,
    );
    final pendingRows = pending
        .map((row) {
          final score = (row['score'] as num?)?.toInt() ?? 0;
          final total = (row['total'] as num?)?.toInt() ?? 0;
          final passed = total > 0 && (score / total) >= 0.7;
          return <String, dynamic>{
            'gradelvl': row['grade'],
            'subject': row['subject'],
            'difficulty': row['difficulty'],
            'score': score,
            'max_score': total,
            'passed': passed ? 1 : 0,
            'played_at': row['played_at'],
          };
        })
        .toList(growable: false);

    return <Map<String, dynamic>>[...remoteRows, ...pendingRows];
  }

  /// Fetch all progress rows for a student.
  static Future<List<Map<String, dynamic>>> getProgress(int studentId) async {
    Future<List<Map<String, dynamic>>> fetchPath(String path) async {
      final res = await _sendWithTimeout(
        _client.get(Uri.parse('$_base$path'), headers: _headers),
      );
      _checkStatus(res);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final rows = body['data'] ?? body['progress'] ?? const <dynamic>[];
      if (rows is! List) {
        return const <Map<String, dynamic>>[];
      }
      return rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }

    List<Map<String, dynamic>> remoteRows = const <Map<String, dynamic>>[];

    try {
      remoteRows = await fetchPath('/api/progress/user/$studentId');
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        try {
          remoteRows = await fetchPath('/api/progress/$studentId');
        } on ApiException catch (fallbackError) {
          if (fallbackError.statusCode != 404 &&
              fallbackError.statusCode != 400 &&
              !_isConnectivityException(fallbackError)) {
            rethrow;
          }
        }
      } else if (e.statusCode != 404 &&
          e.statusCode != 400 &&
          !_isConnectivityException(e)) {
        rethrow;
      }
    }

    if (remoteRows.isEmpty) {
      try {
        remoteRows = await _fetchStudentDetailProgress(studentId);
      } on ApiException catch (e) {
        if (e.statusCode != 401 &&
            e.statusCode != 403 &&
            !_isLegacyEndpointFallbackError(e) &&
            !_isConnectivityException(e)) {
          rethrow;
        }
      }
    }

    if (remoteRows.isNotEmpty) {
      await _cacheProgressRows(remoteRows, fallbackStudentId: studentId);
    }

    final pending = await LocalSyncStore.instance.getPendingProgressForStudent(
      studentId,
    );
    final pendingRows = pending
        .map(
          (row) => <String, dynamic>{
            'gradelvl': row['grade'],
            'subject': row['subject'],
            'highest_diff_passed': row['highest_diff_passed'],
            'total_time_played': row['total_time_played'],
            'last_played_at': row['last_played_at'],
          },
        )
        .toList(growable: false);

    return <Map<String, dynamic>>[...remoteRows, ...pendingRows];
  }

  static Future<List<Map<String, dynamic>>> _fetchStudentDetailProgress(
    int studentId,
  ) async {
    for (final path in <String>[
      '/api/users/$studentId/progress',
      '/api/users/$studentId',
    ]) {
      try {
        final res = await _sendWithTimeout(
          _client.get(Uri.parse('$_base$path'), headers: _headers),
        );
        _checkStatus(res);
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final rows = _progressRowsFromDetailPayload(body);
        if (rows.isNotEmpty) {
          return rows;
        }
      } on ApiException catch (e) {
        if (e.statusCode == 404 ||
            e.statusCode == 401 ||
            e.statusCode == 403 ||
            e.statusCode == 400 ||
            _isConnectivityException(e)) {
          continue;
        }
        rethrow;
      }
    }

    return const <Map<String, dynamic>>[];
  }

  static List<Map<String, dynamic>> _progressRowsFromDetailPayload(
    Map<String, dynamic> body,
  ) {
    final directRows = _readListMap(body['progress'] ?? body['data']);
    if (directRows.isNotEmpty) {
      return directRows;
    }

    final profile = body['profile'];
    if (profile is Map<String, dynamic>) {
      final nestedRows = _readListMap(profile['progress']);
      if (nestedRows.isNotEmpty) {
        return nestedRows;
      }
    }

    return const <Map<String, dynamic>>[];
  }

  static Future<void> _cacheProgressRows(
    List<Map<String, dynamic>> progressRows, {
    int? fallbackStudentId,
  }) async {
    for (final progress in progressRows) {
      final studentId =
          _parseStudentId(progress['student_id']) ??
          _parseStudentId(progress['stud_id']) ??
          fallbackStudentId;
      if (studentId == null || studentId <= 0) {
        continue;
      }

      final grade =
          _gradeNameForId(_asInt(progress['gradelvl_id'])) ??
          _asString(progress['gradelvl']) ??
          _asString(progress['grade']) ??
          'PUNLA';
      final subject =
          _subjectNameForId(_asInt(progress['subject_id'])) ??
          _asString(progress['subject']) ??
          'English';
      final highestNodeIndex = _progressNodeIndex(
        progress,
        preferredKeys: const [
          'highest_node_index',
          'current_node_index',
          'highest_level',
          'current_level',
        ],
      );
      final highestDiffPassed =
          _asInt(progress['highest_diff_passed']) ??
          _asInt(progress['HIGHEST_DIFF_PASSED']);
      final fallbackHighestNodeIndex = highestDiffPassed
          ?.clamp(0, LevelProgression.totalNodes - 1)
          .toInt();
      final resolvedHighestNodeIndex =
          highestNodeIndex ?? fallbackHighestNodeIndex ?? 0;
      final currentNodeIndex =
          _progressNodeIndex(
            progress,
            preferredKeys: const [
              'current_node_index',
              'selected_node_index',
              'current_level',
              'level',
            ],
          ) ??
          resolvedHighestNodeIndex;

      await LocalSyncStore.instance.saveLocalLevelProgress(
        studentId: studentId,
        grade: grade,
        subject: subject,
        highestNodeIndex: resolvedHighestNodeIndex,
        currentNodeIndex: currentNodeIndex,
      );
    }
  }

  static int? _progressNodeIndex(
    Map<String, dynamic> row, {
    required List<String> preferredKeys,
  }) {
    for (final key in preferredKeys) {
      final value = _asInt(row[key]) ?? _asInt(row[key.toUpperCase()]);
      if (value == null) {
        continue;
      }
      final isOneBasedLevel = key.toLowerCase().contains('level');
      final nodeIndex = isOneBasedLevel ? value - 1 : value;
      return nodeIndex.clamp(0, LevelProgression.totalNodes - 1).toInt();
    }
    return null;
  }

  /// Save or update learner progress.
  static Future<void> saveProgress({
    required int studentId,
    required String grade,
    required String subject,
    int? highestDiffPassed,
    required int totalTimePlayed,
    String? lastPlayedAt,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);
    final lastPlayedAtValue = lastPlayedAt ?? DateTime.now().toIso8601String();

    try {
      await _saveProgressRemote(
        studentId: studentId,
        grade: grade,
        subject: normalizedSubject,
        highestDiffPassed: highestDiffPassed,
        totalTimePlayed: totalTimePlayed,
        lastPlayedAt: lastPlayedAtValue,
      );

      await syncPending();
    } on ApiException catch (e) {
      if (!_isConnectivityException(e)) {
        rethrow;
      }

      await LocalSyncStore.instance.queueOfflineProgress(
        studentId: studentId,
        grade: grade,
        subject: normalizedSubject,
        highestDiffPassed: highestDiffPassed,
        totalTimePlayed: totalTimePlayed,
        lastPlayedAt: lastPlayedAtValue,
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static Future<void> _submitScoreRemote({
    required int studentId,
    required String grade,
    required String subject,
    required String difficulty,
    required int score,
    required int total,
    required String playedAt,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);
    final normalizedDifficulty = _normalizeDifficultyForServer(difficulty);
    final gradeLevelId = _gradeLevelIdFor(grade);
    final subjectId = _subjectIdFor(normalizedSubject);
    final difficultyId = _difficultyIdFor(normalizedDifficulty);
    final passed = total > 0 && (score / total) >= 0.7 ? 1 : 0;

    try {
      final res = await _runWithRetry(
        () => _sendWithTimeout(
          _client.post(
            Uri.parse('$_base/api/sync'),
            headers: _headers,
            body: jsonEncode({
              'device_id': _deviceUuid,
              'batches': [
                {
                  'stud_id': studentId,
                  'events': [
                    {
                      'stud_id': studentId,
                      'event_type': 'score',
                      'payload': {
                        'subject_id': subjectId,
                        'gradelvl_id': gradeLevelId,
                        'diff_id': difficultyId,
                        'score': score,
                        'max_score': total,
                        'passed': passed,
                        'played_at': playedAt,
                      },
                    },
                  ],
                },
              ],
            }),
          ),
        ),
        shouldRetry: _isRetryableSyncError,
      );
      _checkStatus(res);
      return;
    } on ApiException catch (e) {
      if (!_isLegacyEndpointFallbackError(e)) {
        rethrow;
      }
    }

    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/quiz/score'),
          headers: _headers,
          body: jsonEncode({
            'studentId': studentId,
            'grade': grade,
            'subject': normalizedSubject,
            'difficulty': normalizedDifficulty,
            'score': score,
            'total': total,
            'played_at': playedAt,
          }),
        ),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);
  }

  static Future<void> _updateProfileRemote({
    required int studentId,
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    final res = await _sendWithTimeout(
      _client.put(
        Uri.parse('$_base/api/users/$studentId/profile'),
        headers: _headers,
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'nickname': nickname,
          'birthday': birthday,
          'sex': sex,
          'area': area,
        }),
      ),
    );
    _checkStatus(res);
  }

  static Future<void> _saveProgressRemote({
    required int studentId,
    required String grade,
    required String subject,
    int? highestDiffPassed,
    int? currentNodeIndex,
    required int totalTimePlayed,
    required String lastPlayedAt,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);
    final gradeLevelId = _gradeLevelIdFor(grade);
    final subjectId = _subjectIdFor(normalizedSubject);

    try {
      final res = await _runWithRetry(
        () => _sendWithTimeout(
          _client.post(
            Uri.parse('$_base/api/sync'),
            headers: _headers,
            body: jsonEncode({
              'device_id': _deviceUuid,
              'batches': [
                {
                  'stud_id': studentId,
                  'events': [
                    {
                      'stud_id': studentId,
                      'event_type': 'progress',
                      'payload': {
                        'subject_id': subjectId,
                        'gradelvl_id': gradeLevelId,
                        'highest_diff_passed': highestDiffPassed ?? 0,
                        if (currentNodeIndex != null)
                          'current_node_index': currentNodeIndex,
                        'total_time_played': totalTimePlayed,
                        'last_played_at': lastPlayedAt,
                      },
                    },
                  ],
                },
              ],
            }),
          ),
        ),
        shouldRetry: _isRetryableSyncError,
      );
      _checkStatus(res);
      return;
    } on ApiException catch (e) {
      if (!_isLegacyEndpointFallbackError(e)) {
        rethrow;
      }
    }

    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/progress'),
          headers: _headers,
          body: jsonEncode({
            'studentId': studentId,
            'grade': grade,
            'subject': normalizedSubject,
            'highest_diff_passed': highestDiffPassed,
            if (currentNodeIndex != null)
              'current_node_index': currentNodeIndex,
            'total_time_played': totalTimePlayed,
            'last_played_at': lastPlayedAt,
          }),
        ),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);
  }

  static Future<ContentRefreshStatus> _refreshContentVersionState() async {
    final uri = Uri.parse('$_base/api/content').replace(
      queryParameters: {
        ...?(_lastContentVersionTag == null
            ? null
            : {'version': _lastContentVersionTag!}),
      },
    );

    final res = await _runWithRetry(
      () => _sendWithTimeout(_client.get(uri, headers: _headers)),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final versionTagRaw = body['version_tag'];
    final versionTag = versionTagRaw is String ? versionTagRaw : null;
    final hasUpdate = body['hasUpdate'] == true || body['up_to_date'] == false;
    final upToDate = body['up_to_date'] == true;

    if (versionTag != null && versionTag.isNotEmpty) {
      if (_lastContentVersionTag != null &&
          _lastContentVersionTag != versionTag) {
        _questionCache.clear();
      }
      _lastContentVersionTag = versionTag;
    }

    _hasDeferredContentRefresh = false;

    return ContentRefreshStatus(
      deferred: false,
      upToDate: upToDate,
      hasUpdate: hasUpdate,
      versionTag: versionTag,
    );
  }

  static Future<http.Response> _sendWithTimeout(
    Future<http.Response> request, {
    Duration? timeout,
  }) async {
    try {
      return await request.timeout(timeout ?? _requestTimeout);
    } on TimeoutException {
      throw ApiException(
        408,
        'Request timed out. Check backend server at $_base.',
      );
    } on http.ClientException {
      throw ApiException(503, 'Cannot reach backend server at $_base.');
    }
  }

  static Future<bool> _hasNetworkTransport() async {
    final results = await Connectivity().checkConnectivity();
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }

  static bool _isConnectivityException(ApiException e) {
    return e.statusCode == 408 || e.statusCode == 503;
  }

  static bool _isIgnorableOracleParentKeyError(ApiException e) {
    return e.statusCode == 500 && e.message.contains('ORA-02291');
  }

  static bool _isLegacyEndpointFallbackError(ApiException e) {
    return e.statusCode == 400 || e.statusCode == 404 || e.statusCode == 405;
  }

  static bool _isRetryableSyncError(Object error) {
    return error is ApiException && _isConnectivityException(error);
  }

  static String _normalizeDifficultyForServer(String difficulty) {
    final normalized = difficulty.trim().toUpperCase();
    if (normalized == 'EASY') {
      return 'Easy';
    }
    if (normalized == 'AVERAGE' || normalized == 'MEDIUM') {
      return 'Average';
    }
    if (normalized == 'HARD' ||
        normalized == 'ADVANCED' ||
        normalized == 'DIFFICULT') {
      return 'Hard';
    }
    return 'Average';
  }

  static String? _normalizeQuestionDifficulty(String? difficulty) {
    if (difficulty == null || difficulty.trim().isEmpty) {
      return null;
    }

    final normalized = difficulty.trim().toUpperCase();
    if (normalized == 'HARD' ||
        normalized == 'ADVANCED' ||
        normalized == 'DIFFICULT') {
      return 'Hard';
    }

    if (normalized == 'EASY') {
      return 'Easy';
    }

    if (normalized == 'AVERAGE' || normalized == 'MEDIUM') {
      return 'Average';
    }

    return null;
  }

  static String _normalizeBirthday(String value) {
    final raw = value.trim();
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})[T\s]').firstMatch(raw);
    if (iso != null) {
      final month = int.tryParse(iso.group(2) ?? '');
      final day = int.tryParse(iso.group(3) ?? '');
      if (month == null ||
          day == null ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31) {
        return raw;
      }
      return '${iso.group(1)}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(raw);
    if (ymd != null) {
      final month = int.tryParse(ymd.group(2) ?? '');
      final day = int.tryParse(ymd.group(3) ?? '');
      if (month == null ||
          day == null ||
          month < 1 ||
          month > 12 ||
          day < 1 ||
          day > 31) {
        return raw;
      }
      return '${ymd.group(1)}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
    }

    final mdy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw);
    if (mdy == null) {
      return raw;
    }

    final month = int.tryParse(mdy.group(1) ?? '');
    final day = int.tryParse(mdy.group(2) ?? '');
    if (month == null ||
        day == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return raw;
    }

    return '${mdy.group(3)}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  static List<String> _nicknameCandidates(String nickname) {
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }

    final candidates = <String>{trimmed};
    candidates.add(trimmed.toLowerCase());
    candidates.add(trimmed.toUpperCase());

    if (trimmed.length == 1) {
      candidates.add(trimmed.toUpperCase());
    } else {
      candidates.add(
        '${trimmed[0].toUpperCase()}${trimmed.substring(1).toLowerCase()}',
      );
    }

    return candidates
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  static int? _parseStudentId(dynamic raw) {
    if (raw == null) {
      return null;
    }

    if (raw is num) {
      return raw.toInt();
    }

    final text = '$raw'.trim();
    if (text.isEmpty) {
      return null;
    }

    final direct = int.tryParse(text);
    if (direct != null) {
      return direct;
    }

    final canonical = RegExp(
      r'^STU-(\d+)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (canonical != null) {
      return int.tryParse(canonical.group(1)!);
    }

    final trailingDigits = RegExp(r'(\d+)$').firstMatch(text);
    if (trailingDigits != null) {
      return int.tryParse(trailingDigits.group(1)!);
    }

    return null;
  }

  static Future<int?> _registerRemote({
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    await _ensureDeviceAuth();
    final tmpLocalId = 'TMP-${_uuid.v4()}';
    final normalizedBirthday = _normalizeBirthday(birthday);

    try {
      final res = await _runWithRetry(
        () => _sendWithTimeout(
          _client.post(
            Uri.parse('$_base/api/sync'),
            headers: _headers,
            body: jsonEncode({
              'device_id': _deviceUuid,
              'batches': [
                {
                  'stud_id': tmpLocalId,
                  'events': [
                    {
                      'stud_id': tmpLocalId,
                      'event_type': 'register',
                      'payload': {
                        'tmp_local_id': tmpLocalId,
                        'first_name': firstName,
                        'last_name': lastName,
                        'nickname': nickname.trim(),
                        'birthday': normalizedBirthday,
                        'sex': sex,
                        'sex_id': _sexIdForLabel(sex),
                      },
                    },
                  ],
                },
              ],
            }),
          ),
        ),
        shouldRetry: _isRetryableSyncError,
      );
      _checkStatus(res);

      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final errors = body['errors'];
        if (errors is List && errors.isNotEmpty) {
          throw ApiException(
            400,
            'Live registration failed: ${jsonEncode(errors)}',
          );
        }

        final idMappings = body['id_mappings'];
        if (idMappings is List) {
          for (final mapping in idMappings) {
            if (mapping is! Map) {
              continue;
            }
            final tmpId = (mapping['tmp_id'] as String?)?.trim();
            if (tmpId != tmpLocalId) {
              continue;
            }
            final parsed = _parseStudentId(mapping['real_id']);
            if (parsed != null && parsed > 0) {
              return parsed;
            }
          }
        }
      } on ApiException {
        rethrow;
      } catch (_) {
        // Fall through to lookup if the sync response shape is older than expected.
      }
    } on ApiException catch (e) {
      if (!_isLegacyEndpointFallbackError(e)) {
        rethrow;
      }
    }

    final legacyRes = await _runWithRetry(
      () => _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/students/register'),
          headers: _headers,
          body: jsonEncode({
            'firstName': firstName,
            'lastName': lastName,
            'nickname': nickname.trim(),
            'birthday': normalizedBirthday,
            'sex': sex,
            'sex_id': _sexIdForLabel(sex),
            'area': area,
            'deviceUuid': _deviceUuid,
            'device_uuid': _deviceUuid,
            'tmpLocalId': tmpLocalId,
            'tmp_local_id': tmpLocalId,
          }),
        ),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(legacyRes);

    try {
      final body = jsonDecode(legacyRes.body) as Map<String, dynamic>;
      final student = body['student'];
      if (student is Map) {
        final parsed =
            _parseStudentId(student['studentId']) ??
            _parseStudentId(student['student_id']);
        if (parsed != null && parsed > 0) {
          return parsed;
        }
      }
      final directId =
          _parseStudentId(body['studentId']) ??
          _parseStudentId(body['student_id']) ??
          _parseStudentId(body['stud_id']);
      if (directId != null && directId > 0) {
        return directId;
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      // Fall through to lookup if the legacy response shape is older than expected.
    }

    final lookup = await _lookupRemoteStudent(
      nickname: nickname.trim(),
      birthday: normalizedBirthday,
    );
    final parsedLookupId = _parseStudentId(lookup?['stud_id']);
    if (parsedLookupId != null && parsedLookupId > 0) {
      return parsedLookupId;
    }

    return null;
  }

  static int _sexIdForLabel(String sex) {
    final normalized = sex.trim().toLowerCase();
    if (normalized == 'female' || normalized == 'girl' || normalized == '2') {
      return 2;
    }
    return 1;
  }

  static Future<void> _ensureDeviceAuth() async {
    if (_deviceToken != null && _deviceToken!.isNotEmpty) {
      return;
    }

    _deviceUuid ??= _uuid.v4();
    final deviceName = await _resolveDeviceName();

    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/auth/device/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'device_uuid': _deviceUuid,
            'device_name': deviceName,
          }),
        ),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = body['token'];
    if (token is String && token.isNotEmpty) {
      _deviceToken = token;
    }
  }

  static Future<void> _tryEnsureDeviceAuth() async {
    try {
      await _ensureDeviceAuth();
    } catch (_) {
      // Best-effort device auth; offline flows continue using local data/queue.
    }
  }

  static Future<Map<String, dynamic>?> _lookupRemoteStudent({
    required String nickname,
    required String birthday,
  }) async {
    final normalizedBirthday = _normalizeBirthday(birthday);
    final res = await _sendWithTimeout(
      _client.post(
        Uri.parse('$_base/api/students/lookup'),
        headers: _headers,
        body: jsonEncode({
          'nickname': nickname,
          'birthday': normalizedBirthday,
        }),
      ),
      timeout: _interactiveAuthTimeout,
    );
    _checkStatus(res);

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['found'] != true) {
      return null;
    }

    final nested = body['student'];
    if (nested is Map<String, dynamic>) {
      return nested;
    }

    return body;
  }

  static Future<Map<String, dynamic>?> _resolveLocalProfileForReconciliation({
    required String nickname,
    required String birthday,
  }) async {
    var localProfile = await LocalSyncStore.instance
        .getStudentProfileByIdentity(nickname: nickname, birthday: birthday);

    if (localProfile == null &&
        _currentStudentId != null &&
        _currentStudentId! > 0) {
      localProfile = await LocalSyncStore.instance.getStudentProfileById(
        _currentStudentId!,
      );
    }

    return localProfile;
  }

  static String _normalizedTextValue(dynamic value) {
    return (value == null ? '' : '$value').trim();
  }

  static bool _sameTextValue(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static bool _needsRemoteProfileUpdate({
    required Student remoteStudent,
    required Map<String, dynamic> localProfile,
    required String fallbackNickname,
    required String fallbackBirthday,
  }) {
    final localFirstName = _normalizedTextValue(localProfile['first_name']);
    final localLastName = _normalizedTextValue(localProfile['last_name']);
    final localNickname = _normalizedTextValue(localProfile['nickname']).isEmpty
        ? fallbackNickname
        : _normalizedTextValue(localProfile['nickname']);
    final localBirthday = _normalizeBirthday(
      _normalizedTextValue(localProfile['birthday']).isEmpty
          ? fallbackBirthday
          : _normalizedTextValue(localProfile['birthday']),
    );
    final localSex = _normalizedTextValue(localProfile['sex']);
    final localArea = _normalizedTextValue(localProfile['area']);

    final remoteFirstName = _normalizedTextValue(remoteStudent.firstName);
    final remoteLastName = _normalizedTextValue(remoteStudent.lastName);
    final remoteNickname = _normalizedTextValue(remoteStudent.nickname);
    final remoteBirthday = _normalizeBirthday(
      _normalizedTextValue(remoteStudent.birthday).isEmpty
          ? fallbackBirthday
          : _normalizedTextValue(remoteStudent.birthday),
    );
    final remoteSex = _normalizedTextValue(remoteStudent.sex);
    final remoteArea = _normalizedTextValue(remoteStudent.area);

    if (localFirstName.isEmpty || localLastName.isEmpty) {
      return false;
    }

    return !_sameTextValue(localFirstName, remoteFirstName) ||
        !_sameTextValue(localLastName, remoteLastName) ||
        !_sameTextValue(localNickname, remoteNickname) ||
        !_sameTextValue(localBirthday, remoteBirthday) ||
        (localSex.isNotEmpty && !_sameTextValue(localSex, remoteSex)) ||
        !_sameTextValue(localArea, remoteArea);
  }

  static Future<void> _applyRemoteProfileUpdateFromLocal({
    required int remoteStudentId,
    required Map<String, dynamic> localProfile,
    required String fallbackNickname,
    required String fallbackBirthday,
  }) async {
    final firstName = _normalizedTextValue(localProfile['first_name']);
    final lastName = _normalizedTextValue(localProfile['last_name']);
    final nickname = _normalizedTextValue(localProfile['nickname']).isEmpty
        ? fallbackNickname
        : _normalizedTextValue(localProfile['nickname']);
    final birthday = _normalizeBirthday(
      _normalizedTextValue(localProfile['birthday']).isEmpty
          ? fallbackBirthday
          : _normalizedTextValue(localProfile['birthday']),
    );
    final sex = _normalizedTextValue(localProfile['sex']).isEmpty
        ? 'Unknown'
        : _normalizedTextValue(localProfile['sex']);
    final area = _normalizedTextValue(localProfile['area']);

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        nickname.isEmpty ||
        birthday.isEmpty) {
      return;
    }

    final res = await _sendWithTimeout(
      _client.put(
        Uri.parse('$_base/api/users/$remoteStudentId/profile'),
        headers: _headers,
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'nickname': nickname,
          'birthday': birthday,
          'sex': sex,
          if (area.isNotEmpty) 'area': area,
        }),
      ),
    );
    _checkStatus(res);
  }

  static Future<void> _registerRemoteFromLocalProfileWithFallback({
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    try {
      await _registerRemote(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );
      return;
    } on ApiException catch (e) {
      if (_isConnectivityException(e)) {
        rethrow;
      }

      if (!_isIgnorableOracleParentKeyError(e)) {
        rethrow;
      }
    }

    // Retry with safer defaults in case legacy Oracle lookups reject
    // area/sex references in partially migrated databases.
    await _registerRemote(
      firstName: firstName,
      lastName: lastName,
      nickname: nickname,
      birthday: birthday,
      sex: 'Unknown',
      area: null,
    );
  }

  static Future<void> _ensureStudentExistsAndSyncedWithOracle({
    required String nickname,
    required String birthday,
  }) async {
    final normalizedNickname = nickname.trim();
    final normalizedBirthday = _normalizeBirthday(birthday);
    if (normalizedNickname.isEmpty || normalizedBirthday.isEmpty) {
      return;
    }

    await _tryEnsureDeviceAuth();
    if (_deviceToken == null || _deviceToken!.isEmpty) {
      return;
    }

    Map<String, dynamic>? remoteRow;
    try {
      remoteRow = await _lookupRemoteStudent(
        nickname: normalizedNickname,
        birthday: normalizedBirthday,
      );
    } on ApiException catch (e) {
      if (_isConnectivityException(e)) {
        return;
      }
      rethrow;
    }

    final localProfile = await _resolveLocalProfileForReconciliation(
      nickname: normalizedNickname,
      birthday: normalizedBirthday,
    );

    if (remoteRow == null) {
      if (localProfile == null) {
        return;
      }

      final firstName = (localProfile['first_name'] as String?)?.trim() ?? '';
      final lastName = (localProfile['last_name'] as String?)?.trim() ?? '';
      final sex = (localProfile['sex'] as String?)?.trim().isNotEmpty == true
          ? (localProfile['sex'] as String).trim()
          : 'Unknown';
      final area = (localProfile['area'] as String?)?.trim();

      if (firstName.isEmpty || lastName.isEmpty) {
        return;
      }

      try {
        await _registerRemoteFromLocalProfileWithFallback(
          firstName: firstName,
          lastName: lastName,
          nickname: normalizedNickname,
          birthday: normalizedBirthday,
          sex: sex,
          area: area,
        );
      } on ApiException catch (e) {
        if (_isConnectivityException(e) ||
            _isIgnorableOracleParentKeyError(e)) {
          return;
        }
        rethrow;
      }

      remoteRow = await _lookupRemoteStudent(
        nickname: normalizedNickname,
        birthday: normalizedBirthday,
      );
      if (remoteRow == null) {
        return;
      }
    }

    final syncedStudent = Student.fromJson(remoteRow);
    if (syncedStudent.studentId <= 0) {
      return;
    }

    if (localProfile != null &&
        _needsRemoteProfileUpdate(
          remoteStudent: syncedStudent,
          localProfile: localProfile,
          fallbackNickname: normalizedNickname,
          fallbackBirthday: normalizedBirthday,
        )) {
      try {
        await _applyRemoteProfileUpdateFromLocal(
          remoteStudentId: syncedStudent.studentId,
          localProfile: localProfile,
          fallbackNickname: normalizedNickname,
          fallbackBirthday: normalizedBirthday,
        );

        final refreshedRemote = await _lookupRemoteStudent(
          nickname: normalizedNickname,
          birthday: normalizedBirthday,
        );
        if (refreshedRemote != null) {
          remoteRow = refreshedRemote;
        }
      } on ApiException catch (e) {
        if (!_isConnectivityException(e) &&
            !_isIgnorableOracleParentKeyError(e)) {
          rethrow;
        }
      }
    }

    final mergedRow = remoteRow;
    if (mergedRow == null) {
      return;
    }

    final mergedStudent = Student.fromJson(mergedRow);
    final resolvedBirthday = _normalizeBirthday(
      mergedStudent.birthday == null || mergedStudent.birthday!.isEmpty
          ? normalizedBirthday
          : mergedStudent.birthday!,
    );

    await LocalSyncStore.instance.saveSyncedStudent(
      student: mergedStudent,
      birthday: resolvedBirthday,
    );

    _currentStudentId = mergedStudent.studentId;
    _currentNickname = mergedStudent.nickname.isEmpty
        ? normalizedNickname
        : mergedStudent.nickname;
    _currentBirthday = resolvedBirthday;

    await LocalSyncStore.instance.saveActiveSession(
      studentId: mergedStudent.studentId,
      nickname: _currentNickname!,
      birthday: resolvedBirthday,
    );
  }

  static void _scheduleOracleReconciliation({
    required String nickname,
    required String birthday,
  }) {
    final normalizedNickname = nickname.trim();
    final normalizedBirthday = _normalizeBirthday(birthday);
    if (normalizedNickname.isEmpty || normalizedBirthday.isEmpty) {
      return;
    }

    final identityKey = '$normalizedNickname|$normalizedBirthday';
    if (_oracleReconciliationTask != null &&
        _oracleReconciliationIdentity == identityKey) {
      return;
    }

    _oracleReconciliationIdentity = identityKey;
    _oracleReconciliationTask = Future<void>.delayed(Duration.zero, () async {
      try {
        await _ensureStudentExistsAndSyncedWithOracle(
          nickname: normalizedNickname,
          birthday: normalizedBirthday,
        );
      } catch (_) {
        // Reconciliation is best-effort only.
      } finally {
        if (_oracleReconciliationIdentity == identityKey) {
          _oracleReconciliationIdentity = null;
          _oracleReconciliationTask = null;
        }
      }
    });
  }

  static Future<T> _runWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = _maxRetryAttempts,
    bool Function(Object error)? shouldRetry,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;

        final isRetryable = shouldRetry?.call(error) ?? false;
        if (!isRetryable || attempt == maxAttempts) {
          rethrow;
        }

        final backoffFactor = 1 << (attempt - 1);
        await Future<void>.delayed(_retryBaseDelay * backoffFactor);
      }
    }

    throw lastError ?? StateError('Retry failed without captured error.');
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = null;
    }

    final message = body is Map<String, dynamic>
        ? ((body['error'] as String?) ?? (body['message'] as String?))
        : null;

    throw ApiException(
      res.statusCode,
      message ?? 'Unexpected server error (${res.statusCode}).',
    );
  }

  static String _normalizeSubject(String subject) {
    switch (subject.trim().toUpperCase()) {
      case 'MATH':
        return 'Mathematics';
      case 'SCIENCE':
        return 'Science';
      case 'READING':
        return 'English';
      case 'WRITING':
        return 'Writing';
      case 'ENGLISH':
        return 'English';
      case 'FILIPINO':
        return 'Filipino';
      default:
        return subject.trim();
    }
  }

  static int _gradeLevelIdFor(String grade) {
    switch (grade.trim().toUpperCase()) {
      case 'PUNLA':
        return 1;
      case 'BINHI':
        return 2;
      default:
        throw ApiException(400, 'Unsupported grade for remote content: $grade');
    }
  }

  static String? _gradeNameForId(int? gradeLevelId) {
    switch (gradeLevelId) {
      case 1:
        return 'PUNLA';
      case 2:
        return 'BINHI';
      default:
        return null;
    }
  }

  static int _subjectIdFor(String subject) {
    switch (_normalizeSubject(subject).trim().toUpperCase()) {
      case 'MATHEMATICS':
        return 1;
      case 'SCIENCE':
        return 2;
      case 'FILIPINO':
        return 3;
      case 'ENGLISH':
        return 4;
      case 'WRITING':
        return 5;
      default:
        throw ApiException(
          400,
          'Unsupported subject for remote content: $subject',
        );
    }
  }

  static String? _subjectNameForId(int? subjectId) {
    switch (subjectId) {
      case 1:
        return 'Mathematics';
      case 2:
        return 'Science';
      case 3:
        return 'Filipino';
      case 4:
        return 'English';
      case 5:
        return 'Writing';
      default:
        return null;
    }
  }

  static int? _difficultyIdFor(String? difficulty) {
    final normalized = _normalizeQuestionDifficulty(difficulty);
    switch (normalized?.trim().toUpperCase()) {
      case 'EASY':
        return 1;
      case 'AVERAGE':
        return 2;
      case 'HARD':
        return 3;
      case null:
        return null;
      default:
        throw ApiException(
          400,
          'Unsupported difficulty for remote content: ${difficulty ?? ''}',
        );
    }
  }

  static Map<String, dynamic> _mapContentQuestionToQuizRow(
    Map<String, dynamic> row,
  ) {
    final questionId =
        _asInt(row['question_id']) ??
        _asInt(row['questionId']) ??
        _asInt(row['id']);
    final gradeLevelId =
        _asInt(row['gradelvl_id']) ??
        _asInt(row['gradelevel_id']) ??
        _asInt(row['grade_level_id']);
    final subjectId = _asInt(row['subject_id']) ?? _asInt(row['subjectId']);
    final diffId =
        _asInt(row['diff_id']) ??
        _asInt(row['difficulty_id']) ??
        _asInt(row['difficultyId']);

    final prompt =
        _asString(row['question_txt']) ??
        _asString(row['question_text']) ??
        _asString(row['question']) ??
        _asString(row['prompt']) ??
        '';
    final choices = _extractChoices(row);
    if (prompt.trim().isEmpty || choices.length != 4) {
      return const <String, dynamic>{};
    }

    final imagePath =
        _asString(row['image_url']) ??
        _asString(row['image_path']) ??
        _asString(row['imageUrl']) ??
        _asString(row['imagePath']);
    final imageBlob =
        _asString(row['image_blob']) ??
        _asString(row['imageBlob']) ??
        _asString(row['question_image']) ??
        _asString(row['questionImage']);
    final funFact =
        _asString(row['fun_fact']) ?? _asString(row['funFact']) ?? '';
    final wordType =
        _asString(row['word_type']) ?? _asString(row['wordType']) ?? '';
    final subPrompt =
        _asString(row['sub_prompt']) ?? _asString(row['subPrompt']) ?? '';

    return <String, dynamic>{
      'id': questionId,
      'gradelvl_id': gradeLevelId,
      'subject_id': subjectId,
      'diff_id': diffId,
      'gradelvl':
          _asString(row['gradelvl']) ??
          _asString(row['grade']) ??
          _asString(row['grade_level']),
      'subject': _asString(row['subject']) ?? _asString(row['subject_name']),
      'difficulty':
          _asString(row['difficulty']) ?? _asString(row['difficulty_name']),
      'prompt': prompt,
      'imagePath': imagePath,
      'imageBlob': imageBlob,
      'funFact': funFact,
      'wordType': wordType,
      'subPrompt': subPrompt,
      'choices': choices,
      'choiceImageBlobs': null,
      'choiceImages': null,
      'correctIndex': _correctIndexFor(row),
    };
  }

  static List<dynamic>? _extractQuestionsFromContentPayload(
    Map<String, dynamic> body,
  ) {
    final direct = body['questions'];
    if (direct is List) {
      return direct;
    }

    final data = body['data'];
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final nestedQuestions = data['questions'] ?? data['items'];
      if (nestedQuestions is List) {
        return nestedQuestions;
      }
    }

    final items = body['items'];
    if (items is List) {
      return items;
    }

    return null;
  }

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse('$value');
  }

  static String? _asString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _extractChoices(Map<String, dynamic> row) {
    final fromArray = row['choices'] ?? row['options'];
    if (fromArray is List) {
      final normalized = fromArray
          .map((entry) => (entry == null ? '' : '$entry').trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
      if (normalized.length == 4) {
        return normalized;
      }
    }

    final options = <String>[
      _asString(row['option_a']) ?? _asString(row['optionA']) ?? '',
      _asString(row['option_b']) ?? _asString(row['optionB']) ?? '',
      _asString(row['option_c']) ?? _asString(row['optionC']) ?? '',
      _asString(row['option_d']) ?? _asString(row['optionD']) ?? '',
    ];

    if (options.any((entry) => entry.isEmpty)) {
      return const <String>[];
    }
    return options;
  }

  static int _correctIndexFor(Map<String, dynamic> row) {
    const letterToIndex = <String, int>{'A': 0, 'B': 1, 'C': 2, 'D': 3};

    final indexCandidate =
        _asInt(row['correct_index']) ?? _asInt(row['correctIndex']);
    if (indexCandidate != null && indexCandidate >= 0 && indexCandidate <= 3) {
      return indexCandidate;
    }

    final letterCandidate =
        _asString(row['correct_opt']) ??
        _asString(row['correct_option']) ??
        _asString(row['correctOpt']) ??
        _asString(row['correctOption']) ??
        _asString(row['answer']) ??
        _asString(row['correct_answer']);
    if (letterCandidate != null) {
      final letter = letterCandidate.toUpperCase();
      if (letterToIndex.containsKey(letter)) {
        return letterToIndex[letter]!;
      }
    }

    return 0;
  }

  static int? _safeGradeLevelIdFor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    try {
      return _gradeLevelIdFor(value);
    } catch (_) {
      return null;
    }
  }

  static int? _safeSubjectIdFor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    try {
      return _subjectIdFor(value);
    } catch (_) {
      return null;
    }
  }

  static int? _safeDifficultyIdFor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    try {
      return _difficultyIdFor(value);
    } catch (_) {
      return null;
    }
  }
}

/// Thrown when the server returns a non-2xx status code.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ContentRefreshStatus {
  final bool deferred;
  final bool upToDate;
  final bool hasUpdate;
  final String? versionTag;

  const ContentRefreshStatus({
    required this.deferred,
    required this.upToDate,
    required this.hasUpdate,
    this.versionTag,
  });
}

class _RemoteQuestionResult {
  final List<Map<String, dynamic>> rows;
  final String? versionTag;

  const _RemoteQuestionResult({required this.rows, this.versionTag});
}

class _LearnerCacheResult {
  final bool cachedAny;
  final List<Map<String, dynamic>> learners;

  const _LearnerCacheResult({required this.cachedAny, required this.learners});
}
