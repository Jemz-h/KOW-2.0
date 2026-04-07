import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'api_config.dart';
import 'local_sync_store.dart';
import 'student_model.dart';

/// Thin HTTP client for the KOW Node.js / Oracle backend.
class ApiService {
  ApiService._();

  static final _client = http.Client();
  static const _base   = ApiConfig.baseUrl;
  static const _requestTimeout = Duration(seconds: 12);
  static const _interactiveAuthTimeout = Duration(seconds: 5);
  static const _maxRetryAttempts = 3;
  static const _retryBaseDelay = Duration(milliseconds: 450);
  static final _uuid = Uuid();
  static int? _currentStudentId;
  static String? _currentNickname;
  static String? _currentBirthday;
  static String? _deviceUuid;
  static String? _deviceToken;
  static String? _lastContentVersionTag;
  static bool _hasDeferredContentRefresh = false;
  static int _activeLearningSessions = 0;
  static Timer? _contentPoller;
  static final Map<String, List<Map<String, dynamic>>> _questionCache = {};

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    if (_deviceToken != null) 'Authorization': 'Bearer $_deviceToken',
  };

  static int? get currentStudentId => _currentStudentId;

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

  /// Register a new student. Returns the created student's nickname on success.
  static Future<void> register({
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    try {
      final studentId = await _registerRemote(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );
      _currentStudentId = studentId;
      _currentNickname = nickname;
      _currentBirthday = birthday;

      if (studentId != null) {
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
      }

      startContentVersionPolling();
      unawaited(syncPending());
    } on ApiException catch (e) {
      if (!_isConnectivityException(e)) {
        rethrow;
      }

      await LocalSyncStore.instance.queueOfflineRegistration(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );

      _currentNickname = nickname;
      _currentBirthday = birthday;
    }
  }

  /// Login with nickname + birthday (birthday is the password).
  /// Returns the authenticated [Student].
  static Future<Student> login({
    required String nickname,
    required String birthday,
  }) async {
    // Keep login path responsive; warm background auth/sync concurrently.
    unawaited(_tryEnsureDeviceAuth());
    unawaited(syncPending());

    try {
      final res = await _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/auth/login'),
          headers: _headers,
          body: jsonEncode({'nickname': nickname, 'birthday': birthday}),
        ),
        timeout: _interactiveAuthTimeout,
      );
      _checkStatus(res);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final student = Student.fromJson(body['student'] as Map<String, dynamic>);
      _currentStudentId = student.studentId;
      _currentNickname = nickname;
      _currentBirthday = birthday;
      startContentVersionPolling();
      unawaited(syncPending());

      await LocalSyncStore.instance.saveSyncedStudent(
        student: student,
        birthday: birthday,
      );

      return student;
    } on ApiException catch (e) {
      if (!_isConnectivityException(e)) {
        rethrow;
      }

      final offlineStudent = await LocalSyncStore.instance.findOfflineStudent(
        nickname: nickname,
        birthday: birthday,
      );

      if (offlineStudent != null) {
        _currentStudentId = offlineStudent.studentId;
        _currentNickname = nickname;
        _currentBirthday = birthday;
        return offlineStudent;
      }

      throw const ApiException(
        401,
        'Offline login failed: account not found on this device.',
      );
    }
  }

  /// Returns best-known current student profile data from local cache.
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
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

    return LocalSyncStore.instance.getMostRecentStudentProfile();
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
    } catch (_) {
      // Best-effort sync only; queue remains for next cycle.
    }
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

    await _tryEnsureDeviceAuth();

    try {
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

      await LocalSyncStore.instance.updateLocalStudentProfile(
        studentId: studentId,
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );

      _currentNickname = nickname;
      _currentBirthday = birthday;
    } on ApiException {
      rethrow;
    }
  }

  // ── Quiz ──────────────────────────────────────────────────────────────

  /// Fetch quiz questions for a grade / subject / difficulty.
  static Future<List<Map<String, dynamic>>> getQuestions({
    required String grade,
    required String subject,
    required String difficulty,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);
    final cacheKey = _questionCacheKey(
      grade: grade,
      subject: normalizedSubject,
      difficulty: difficulty,
    );

    final cached = _questionCache[cacheKey];
    if (cached != null && cached.isNotEmpty) {
      unawaited(
        _refreshQuestionsCache(
          cacheKey: cacheKey,
          grade: grade,
          subject: normalizedSubject,
          difficulty: difficulty,
        ),
      );
      return cached;
    }

    return _refreshQuestionsCache(
      cacheKey: cacheKey,
      grade: grade,
      subject: normalizedSubject,
      difficulty: difficulty,
    );
  }

  static Future<List<Map<String, dynamic>>> _refreshQuestionsCache({
    required String cacheKey,
    required String grade,
    required String subject,
    required String difficulty,
  }) async {

    final uri = Uri.parse('$_base/api/quiz/questions').replace(
      queryParameters: {
        'grade':      grade,
        'subject':    subject,
        'difficulty': difficulty,
      },
    );
    final res = await _sendWithTimeout(_client.get(uri, headers: _headers));
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final parsed = List<Map<String, dynamic>>.from(body['questions'] as List);
    _questionCache[cacheKey] = parsed;
    return parsed;
  }

  static String _questionCacheKey({
    required String grade,
    required String subject,
    required String difficulty,
  }) {
    return '${grade.trim().toUpperCase()}|${subject.trim().toUpperCase()}|${difficulty.trim().toUpperCase()}';
  }

  /// Submit a quiz score.
  static Future<void> submitScore({
    required int    studentId,
    required String grade,
    required String subject,
    required String difficulty,
    required int    score,
    required int    total,
    String? playedAt,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);
    final playedAtValue = playedAt ?? DateTime.now().toIso8601String();

    try {
      await _submitScoreRemote(
        studentId: studentId,
        grade: grade,
        subject: normalizedSubject,
        difficulty: difficulty,
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
        difficulty: difficulty,
        score: score,
        total: total,
        playedAt: playedAtValue,
      );
    }
  }

  /// Fetch all scores for a student.
  static Future<List<Map<String, dynamic>>> getScores(int studentId) async {
    final res = await _sendWithTimeout(
      _client.get(
        Uri.parse('$_base/api/quiz/scores/$studentId'),
        headers: _headers,
      ),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['scores'] as List);
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

    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/quiz/score'),
          headers: _headers,
          body: jsonEncode({
            'studentId':  studentId,
            'grade':      grade,
            'subject':    normalizedSubject,
            'difficulty': difficulty,
            'score':      score,
            'total':      total,
            'played_at':  playedAt,
          }),
        ),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);
  }

  static Future<void> _saveProgressRemote({
    required int studentId,
    required String grade,
    required String subject,
    int? highestDiffPassed,
    required int totalTimePlayed,
    required String lastPlayedAt,
  }) async {
    final normalizedSubject = _normalizeSubject(subject);

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
            : {'sinceVersion': _lastContentVersionTag!}),
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
    Future<http.Response> request,
    {
      Duration? timeout,
    }
  ) async {
    try {
      return await request.timeout(timeout ?? _requestTimeout);
    } on TimeoutException {
      throw ApiException(
        408,
        'Request timed out. Check backend server at $_base.',
      );
    } on http.ClientException {
      throw ApiException(
        503,
        'Cannot reach backend server at $_base.',
      );
    }
  }

  static bool _isConnectivityException(ApiException e) {
    return e.statusCode == 408 || e.statusCode == 503;
  }

  static bool _isRetryableSyncError(Object error) {
    return error is ApiException && _isConnectivityException(error);
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

    final res = await _runWithRetry(
      () => _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/students/register'),
          headers: _headers,
          body: jsonEncode({
            'firstName': firstName,
            'lastName': lastName,
            'nickname': nickname,
            'birthday': birthday,
            'sex': sex,
            ...?(area == null ? null : {'area': area}),
          }),
        ),
      ),
      shouldRetry: _isRetryableSyncError,
    );
    _checkStatus(res);

    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final student = body['student'];
      if (student is Map<String, dynamic>) {
        final idValue = student['studentId'];
        if (idValue is num) return idValue.toInt();
      }

      final userId = body['userId'];
      if (userId is num) return userId.toInt();
    } catch (_) {
      // Return null if response payload does not include an ID.
    }

    return null;
  }

  static Future<void> _ensureDeviceAuth() async {
    if (_deviceToken != null && _deviceToken!.isNotEmpty) {
      return;
    }

    _deviceUuid ??= _uuid.v4();

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
            'device_name': 'KOW Device',
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
        return 'Filipino';
      default:
        return subject;
    }
  }
}

/// Thrown when the server returns a non-2xx status code.
class ApiException implements Exception {
  final int    statusCode;
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
