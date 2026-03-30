import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'local_sync_store.dart';
import 'student_model.dart';

/// Thin HTTP client for the KOW Node.js / Oracle backend.
class ApiService {
  ApiService._();

  static final _client = http.Client();
  static const _base   = ApiConfig.baseUrl;
  static const _requestTimeout = Duration(seconds: 12);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
  };

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
      await _registerRemote(
        firstName: firstName,
        lastName: lastName,
        nickname: nickname,
        birthday: birthday,
        sex: sex,
        area: area,
      );
      await syncPending();
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
    }
  }

  /// Login with nickname + birthday (birthday is the password).
  /// Returns the authenticated [Student].
  static Future<Student> login({
    required String nickname,
    required String birthday,
  }) async {
    await syncPending();

    try {
      final res = await _sendWithTimeout(
        _client.post(
          Uri.parse('$_base/api/auth/login'),
          headers: _headers,
          body: jsonEncode({'nickname': nickname, 'birthday': birthday}),
        ),
      );
      _checkStatus(res);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final student = Student.fromJson(body['student'] as Map<String, dynamic>);

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
        return offlineStudent;
      }

      throw const ApiException(
        401,
        'Offline login failed: account not found on this device.',
      );
    }
  }

  static Future<void> syncPending() async {
    try {
      await LocalSyncStore.instance.syncPendingRegistrations(
        registerRemote: _registerRemote,
      );
    } catch (_) {
      // Best-effort sync only.
    }
  }

  // ── Quiz ──────────────────────────────────────────────────────────────

  /// Fetch quiz questions for a grade / subject / difficulty.
  static Future<List<Map<String, dynamic>>> getQuestions({
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
    return List<Map<String, dynamic>>.from(body['questions'] as List);
  }

  /// Submit a quiz score.
  static Future<void> submitScore({
    required int    studentId,
    required String grade,
    required String subject,
    required String difficulty,
    required int    score,
    required int    total,
  }) async {
    final res = await _sendWithTimeout(
      _client.post(
        Uri.parse('$_base/api/quiz/score'),
        headers: _headers,
        body: jsonEncode({
          'studentId':  studentId,
          'grade':      grade,
          'subject':    subject,
          'difficulty': difficulty,
          'score':      score,
          'total':      total,
        }),
      ),
    );
    _checkStatus(res);
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

  // ── Helpers ───────────────────────────────────────────────────────────

  static Future<http.Response> _sendWithTimeout(
    Future<http.Response> request,
  ) async {
    try {
      return await request.timeout(_requestTimeout);
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

  static Future<void> _registerRemote({
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    final res = await _sendWithTimeout(
      _client.post(
        Uri.parse('$_base/api/auth/register'),
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
    );
    _checkStatus(res);
  }

  static void _checkStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    dynamic body;
    try {
      body = jsonDecode(res.body);
    } catch (_) {
      body = null;
    }

    final message =
        body is Map<String, dynamic>
            ? (body['error'] as String?)
            : null;

    throw ApiException(
      res.statusCode,
      message ?? 'Unexpected server error (${res.statusCode}).',
    );
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
