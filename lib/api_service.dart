import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'student_model.dart';

/// Thin HTTP client for the KOW Node.js / Oracle backend.
class ApiService {
  ApiService._();

  static final _client = http.Client();
  static const _base   = ApiConfig.baseUrl;

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
    final res = await _client.post(
      Uri.parse('$_base/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'firstName': firstName,
        'lastName':  lastName,
        'nickname':  nickname,
        'birthday':  birthday,
        'sex':       sex,
        if (area != null) 'area': area,
      }),
    );
    _checkStatus(res);
  }

  /// Login with nickname + birthday (birthday is the password).
  /// Returns the authenticated [Student].
  static Future<Student> login({
    required String nickname,
    required String birthday,
  }) async {
    final res = await _client.post(
      Uri.parse('$_base/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'nickname': nickname, 'birthday': birthday}),
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return Student.fromJson(body['student'] as Map<String, dynamic>);
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
    final res = await _client.get(uri, headers: _headers);
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
    final res = await _client.post(
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
    );
    _checkStatus(res);
  }

  /// Fetch all scores for a student.
  static Future<List<Map<String, dynamic>>> getScores(int studentId) async {
    final res = await _client.get(
      Uri.parse('$_base/api/quiz/scores/$studentId'),
      headers: _headers,
    );
    _checkStatus(res);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(body['scores'] as List);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  static void _checkStatus(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final body = jsonDecode(res.body);
    throw ApiException(
      res.statusCode,
      (body['error'] as String?) ?? 'Unexpected error',
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
