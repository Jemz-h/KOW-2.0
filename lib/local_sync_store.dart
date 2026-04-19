import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'student_model.dart';

typedef RegisterRemoteFn = Future<int?> Function({
  required String firstName,
  required String lastName,
  required String nickname,
  required String birthday,
  required String sex,
  String? area,
});

typedef SubmitScoreRemoteFn = Future<void> Function({
  required int studentId,
  required String grade,
  required String subject,
  required String difficulty,
  required int score,
  required int total,
  required String playedAt,
});

typedef SubmitProgressRemoteFn = Future<void> Function({
  required int studentId,
  required String grade,
  required String subject,
  int? highestDiffPassed,
  required int totalTimePlayed,
  required String lastPlayedAt,
});

typedef UpdateProfileRemoteFn = Future<void> Function({
  required int studentId,
  required String firstName,
  required String lastName,
  required String nickname,
  required String birthday,
  required String sex,
  String? area,
});

class LocalSyncStore {
  LocalSyncStore._();

  static final LocalSyncStore instance = LocalSyncStore._();

  Database? _db;
  final List<Map<String, dynamic>> _webStudentsLocal = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _webPendingRegistrations = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _webPendingScores = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _webPendingProgress = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _webPendingProfileUpdates = <Map<String, dynamic>>[];
  final Map<String, String> _webSettings = <String, String>{};
  Map<String, dynamic>? _webSession;

  bool get _useWebMemoryStore => kIsWeb;

  int _nextWebId(List<Map<String, dynamic>> rows) {
    var maxId = 0;
    for (final row in rows) {
      final id = (row['id'] as num?)?.toInt() ?? 0;
      if (id > maxId) {
        maxId = id;
      }
    }
    return maxId + 1;
  }

  bool _matchesIdentity(Map<String, dynamic> row, String nickname, String birthday) {
    final normalizedBirthday = _normalizeBirthday(birthday);
    final rowNickname = (row['nickname'] as String? ?? '').trim().toLowerCase();
    final rowBirthday = (row['birthday'] as String? ?? '').trim();
    return rowNickname == nickname.trim().toLowerCase() &&
        (rowBirthday == birthday.trim() || rowBirthday == normalizedBirthday);
  }

  Map<String, dynamic>? _pickPreferredRow(
    Iterable<Map<String, dynamic>> rows, {
    bool preferSynced = true,
  }) {
    final list = rows.map(Map<String, dynamic>.from).toList();
    if (list.isEmpty) {
      return null;
    }

    list.sort((a, b) {
      if (preferSynced) {
        final syncedCompare =
            ((b['is_synced'] as num?)?.toInt() ?? 0).compareTo(
              (a['is_synced'] as num?)?.toInt() ?? 0,
            );
        if (syncedCompare != 0) {
          return syncedCompare;
        }
      }

      final createdCompare = (b['created_at'] as String? ?? '').compareTo(
        a['created_at'] as String? ?? '',
      );
      if (createdCompare != 0) {
        return createdCompare;
      }

      return ((b['id'] as num?)?.toInt() ?? 0).compareTo(
        (a['id'] as num?)?.toInt() ?? 0,
      );
    });

    return list.first;
  }

  String _normalizeBirthday(String value) {
    final raw = value.trim();
    final ymd = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(raw);
    if (ymd != null) {
      final month = int.tryParse(ymd.group(2) ?? '');
      final day = int.tryParse(ymd.group(3) ?? '');
      if (month == null || day == null || month < 1 || month > 12 || day < 1 || day > 31) {
        return raw;
      }
      final mm = month.toString().padLeft(2, '0');
      final dd = day.toString().padLeft(2, '0');
      return '${ymd.group(1)}-$mm-$dd';
    }

    final mdy = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(raw);
    if (mdy == null) {
      return raw;
    }

    final month = int.tryParse(mdy.group(1) ?? '');
    final day = int.tryParse(mdy.group(2) ?? '');
    if (month == null || day == null || month < 1 || month > 12 || day < 1 || day > 31) {
      return raw;
    }

    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '${mdy.group(3)}-$mm-$dd';
  }

  String _normalizeLowerText(String value) {
    return value.trim().toLowerCase();
  }

  Future<Database> _database() async {
    if (_db != null) return _db!;

    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'kow_app.db');

    _db = await openDatabase(
      dbPath,
      version: 6,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE students_local (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            nickname TEXT NOT NULL,
            birthday TEXT NOT NULL,
            sex TEXT NOT NULL,
            area TEXT,
            is_synced INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            UNIQUE(nickname, birthday)
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_registrations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            nickname TEXT NOT NULL,
            birthday TEXT NOT NULL,
            sex TEXT NOT NULL,
            area TEXT,
            created_at TEXT NOT NULL,
            UNIQUE(nickname, birthday)
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            grade TEXT NOT NULL,
            subject TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            score INTEGER NOT NULL,
            total INTEGER NOT NULL,
            played_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(student_id, grade, subject, difficulty, score, total, played_at)
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_progress (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            grade TEXT NOT NULL,
            subject TEXT NOT NULL,
            highest_diff_passed INTEGER,
            total_time_played INTEGER NOT NULL,
            last_played_at TEXT NOT NULL,
            created_at TEXT NOT NULL,
            UNIQUE(student_id, grade, subject, total_time_played, last_played_at)
          )
        ''');

        await db.execute('''
          CREATE TABLE app_session (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            student_id INTEGER,
            nickname TEXT,
            birthday TEXT,
            updated_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE pending_profile_updates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER NOT NULL,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            nickname TEXT NOT NULL,
            birthday TEXT NOT NULL,
            sex TEXT NOT NULL,
            area TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_scores (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              student_id INTEGER NOT NULL,
              grade TEXT NOT NULL,
              subject TEXT NOT NULL,
              difficulty TEXT NOT NULL,
              score INTEGER NOT NULL,
              total INTEGER NOT NULL,
              played_at TEXT NOT NULL,
              created_at TEXT NOT NULL,
              UNIQUE(student_id, grade, subject, difficulty, score, total, played_at)
            )
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_progress (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              student_id INTEGER NOT NULL,
              grade TEXT NOT NULL,
              subject TEXT NOT NULL,
              highest_diff_passed INTEGER,
              total_time_played INTEGER NOT NULL,
              last_played_at TEXT NOT NULL,
              created_at TEXT NOT NULL,
              UNIQUE(student_id, grade, subject, total_time_played, last_played_at)
            )
          ''');
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_session (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              student_id INTEGER,
              nickname TEXT,
              birthday TEXT,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_settings (
              key TEXT PRIMARY KEY,
              value TEXT
            )
          ''');
        }

        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_profile_updates (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              student_id INTEGER NOT NULL,
              first_name TEXT NOT NULL,
              last_name TEXT NOT NULL,
              nickname TEXT NOT NULL,
              birthday TEXT NOT NULL,
              sex TEXT NOT NULL,
              area TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
      },
    );

    return _db!;
  }

  Future<void> saveSyncedStudent({
    required Student student,
    required String birthday,
  }) async {
    if (_useWebMemoryStore) {
      final normalizedBirthday = _normalizeBirthday(birthday);
      _webStudentsLocal.removeWhere(
        (row) => _matchesIdentity(row, student.nickname, normalizedBirthday),
      );
      _webStudentsLocal.add({
        'id': _nextWebId(_webStudentsLocal),
        'student_id': student.studentId,
        'first_name': _normalizeLowerText(student.firstName),
        'last_name': _normalizeLowerText(student.lastName),
        'nickname': _normalizeLowerText(student.nickname),
        'birthday': normalizedBirthday,
        'sex': student.sex.trim(),
        'area': student.area == null ? null : _normalizeLowerText(student.area!),
        'is_synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      });
      _webPendingRegistrations.removeWhere(
        (row) => _matchesIdentity(row, student.nickname, normalizedBirthday),
      );
      return;
    }

    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);
    await db.insert(
      'students_local',
      {
        'student_id': student.studentId,
        'first_name': _normalizeLowerText(student.firstName),
        'last_name': _normalizeLowerText(student.lastName),
        'nickname': _normalizeLowerText(student.nickname),
        'birthday': normalizedBirthday,
        'sex': student.sex.trim(),
        'area': student.area == null ? null : _normalizeLowerText(student.area!),
        'is_synced': 1,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.delete(
      'pending_registrations',
      where: 'nickname = ? AND (birthday = ? OR birthday = ?)',
      whereArgs: [student.nickname, birthday, normalizedBirthday],
    );
  }

  Future<void> queueOfflineRegistration({
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    if (_useWebMemoryStore) {
      final normalizedBirthday = _normalizeBirthday(birthday);
      final now = DateTime.now().toIso8601String();
      if (_webStudentsLocal.every(
        (row) => !_matchesIdentity(row, nickname, normalizedBirthday),
      )) {
        _webStudentsLocal.add({
          'id': _nextWebId(_webStudentsLocal),
          'student_id': -DateTime.now().millisecondsSinceEpoch,
          'first_name': _normalizeLowerText(firstName),
          'last_name': _normalizeLowerText(lastName),
          'nickname': _normalizeLowerText(nickname),
          'birthday': normalizedBirthday,
          'sex': sex.trim(),
          'area': area == null ? null : _normalizeLowerText(area),
          'is_synced': 0,
          'created_at': now,
        });
      }

      if (_webPendingRegistrations.every(
        (row) => !_matchesIdentity(row, nickname, normalizedBirthday),
      )) {
        _webPendingRegistrations.add({
          'id': _nextWebId(_webPendingRegistrations),
          'first_name': firstName,
          'last_name': lastName,
          'nickname': nickname,
          'birthday': normalizedBirthday,
          'sex': sex,
          'area': area,
          'created_at': now,
        });
      }
      return;
    }

    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);

    await db.insert(
      'students_local',
      {
        'student_id': -DateTime.now().millisecondsSinceEpoch,
        'first_name': _normalizeLowerText(firstName),
        'last_name': _normalizeLowerText(lastName),
        'nickname': _normalizeLowerText(nickname),
        'birthday': normalizedBirthday,
        'sex': sex.trim(),
        'area': area == null ? null : _normalizeLowerText(area),
        'is_synced': 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.insert(
      'pending_registrations',
      {
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'birthday': normalizedBirthday,
        'sex': sex,
        'area': area,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> queueOfflineScore({
    required int studentId,
    required String grade,
    required String subject,
    required String difficulty,
    required int score,
    required int total,
    String? playedAt,
  }) async {
    if (_useWebMemoryStore) {
      final now = DateTime.now().toIso8601String();
      final playedAtValue = playedAt ?? now;
      final exists = _webPendingScores.any((row) =>
          row['student_id'] == studentId &&
          row['grade'] == grade &&
          row['subject'] == subject &&
          row['difficulty'] == difficulty &&
          row['score'] == score &&
          row['total'] == total &&
          row['played_at'] == playedAtValue);
      if (!exists) {
        _webPendingScores.add({
          'id': _nextWebId(_webPendingScores),
          'student_id': studentId,
          'grade': grade,
          'subject': subject,
          'difficulty': difficulty,
          'score': score,
          'total': total,
          'played_at': playedAtValue,
          'created_at': now,
        });
      }
      return;
    }

    final db = await _database();
    final now = DateTime.now().toIso8601String();
    final playedAtValue = playedAt ?? now;

    await db.insert(
      'pending_scores',
      {
        'student_id': studentId,
        'grade': grade,
        'subject': subject,
        'difficulty': difficulty,
        'score': score,
        'total': total,
        'played_at': playedAtValue,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> queueOfflineProgress({
    required int studentId,
    required String grade,
    required String subject,
    int? highestDiffPassed,
    required int totalTimePlayed,
    String? lastPlayedAt,
  }) async {
    if (_useWebMemoryStore) {
      final now = DateTime.now().toIso8601String();
      final playedAtValue = lastPlayedAt ?? now;
      final exists = _webPendingProgress.any((row) =>
          row['student_id'] == studentId &&
          row['grade'] == grade &&
          row['subject'] == subject &&
          row['total_time_played'] == totalTimePlayed &&
          row['last_played_at'] == playedAtValue);
      if (!exists) {
        _webPendingProgress.add({
          'id': _nextWebId(_webPendingProgress),
          'student_id': studentId,
          'grade': grade,
          'subject': subject,
          'highest_diff_passed': highestDiffPassed,
          'total_time_played': totalTimePlayed,
          'last_played_at': playedAtValue,
          'created_at': now,
        });
      }
      return;
    }

    final db = await _database();
    final now = DateTime.now().toIso8601String();
    final playedAtValue = lastPlayedAt ?? now;

    await db.insert(
      'pending_progress',
      {
        'student_id': studentId,
        'grade': grade,
        'subject': subject,
        'highest_diff_passed': highestDiffPassed,
        'total_time_played': totalTimePlayed,
        'last_played_at': playedAtValue,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<Student?> findOfflineStudent({
    required String nickname,
    required String birthday,
  }) async {
    if (_useWebMemoryStore) {
      final normalizedBirthday = _normalizeBirthday(birthday);
      final row = _pickPreferredRow(
        _webStudentsLocal.where(
          (entry) => _matchesIdentity(entry, nickname, normalizedBirthday),
        ),
      );

      if (row != null) {
        return Student(
          studentId: (row['student_id'] as num?)?.toInt() ?? -1,
          firstName: (row['first_name'] as String?) ?? '',
          lastName: (row['last_name'] as String?) ?? '',
          nickname: (row['nickname'] as String?) ?? nickname,
          sex: (row['sex'] as String?) ?? 'Unknown',
          area: row['area'] as String?,
          totalScore: 0,
        );
      }

      final pendingRow = _pickPreferredRow(
        _webPendingRegistrations.where(
          (entry) => _matchesIdentity(entry, nickname, normalizedBirthday),
        ),
        preferSynced: false,
      );

      if (pendingRow == null) {
        return null;
      }

      return Student(
        studentId: -((pendingRow['id'] as num?)?.toInt() ?? 1),
        firstName: (pendingRow['first_name'] as String?) ?? '',
        lastName: (pendingRow['last_name'] as String?) ?? '',
        nickname: (pendingRow['nickname'] as String?) ?? nickname,
        sex: (pendingRow['sex'] as String?) ?? 'Unknown',
        area: pendingRow['area'] as String?,
        totalScore: 0,
      );
    }

    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);
    final rows = await db.query(
      'students_local',
      where: 'UPPER(nickname) = UPPER(?) AND (birthday = ? OR birthday = ?)',
      whereArgs: [nickname.trim(), birthday.trim(), normalizedBirthday],
      orderBy: 'is_synced DESC, created_at DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      final pendingRows = await db.query(
        'pending_registrations',
        where: 'UPPER(nickname) = UPPER(?) AND (birthday = ? OR birthday = ?)',
        whereArgs: [nickname.trim(), birthday.trim(), normalizedBirthday],
        orderBy: 'created_at DESC, id DESC',
        limit: 1,
      );

      if (pendingRows.isEmpty) return null;
      final row = pendingRows.first;

      return Student(
        studentId: -((row['id'] as num?)?.toInt() ?? 1),
        firstName: (row['first_name'] as String?) ?? '',
        lastName: (row['last_name'] as String?) ?? '',
        nickname: (row['nickname'] as String?) ?? nickname,
        sex: (row['sex'] as String?) ?? 'Unknown',
        area: row['area'] as String?,
        totalScore: 0,
      );
    }

    final row = rows.first;

    return Student(
      studentId: (row['student_id'] as num?)?.toInt() ?? -1,
      firstName: (row['first_name'] as String?) ?? '',
      lastName: (row['last_name'] as String?) ?? '',
      nickname: (row['nickname'] as String?) ?? nickname,
      sex: (row['sex'] as String?) ?? 'Unknown',
      area: row['area'] as String?,
      totalScore: 0,
    );
  }

  Future<Map<String, dynamic>?> getStudentProfileById(int studentId) async {
    if (_useWebMemoryStore) {
      return _pickPreferredRow(
        _webStudentsLocal.where(
          (row) => (row['student_id'] as num?)?.toInt() == studentId,
        ),
      );
    }

    final db = await _database();
    final rows = await db.query(
      'students_local',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'is_synced DESC, created_at DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> getStudentProfileByIdentity({
    required String nickname,
    required String birthday,
  }) async {
    if (_useWebMemoryStore) {
      return _pickPreferredRow(
        _webStudentsLocal.where(
          (row) => _matchesIdentity(row, nickname, birthday),
        ),
      );
    }

    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);
    final rows = await db.query(
      'students_local',
      where: 'UPPER(nickname) = UPPER(?) AND (birthday = ? OR birthday = ?)',
      whereArgs: [nickname.trim(), birthday.trim(), normalizedBirthday],
      orderBy: 'is_synced DESC, created_at DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> getMostRecentStudentProfile() async {
    if (_useWebMemoryStore) {
      return _pickPreferredRow(_webStudentsLocal);
    }

    final db = await _database();
    final rows = await db.query(
      'students_local',
      orderBy: 'is_synced DESC, created_at DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> saveActiveSession({
    required int? studentId,
    required String nickname,
    required String birthday,
  }) async {
    if (_useWebMemoryStore) {
      _webSession = {
        'id': 1,
        'student_id': studentId,
        'nickname': nickname.trim(),
        'birthday': _normalizeBirthday(birthday),
        'updated_at': DateTime.now().toIso8601String(),
      };
      return;
    }

    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);

    await db.insert(
      'app_session',
      {
        'id': 1,
        'student_id': studentId,
        'nickname': nickname.trim(),
        'birthday': normalizedBirthday,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    if (_useWebMemoryStore) {
      return _webSession == null ? null : Map<String, dynamic>.from(_webSession!);
    }

    final db = await _database();
    final rows = await db.query('app_session', where: 'id = 1', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> clearActiveSession() async {
    if (_useWebMemoryStore) {
      _webSession = null;
      return;
    }

    final db = await _database();
    await db.delete('app_session', where: 'id = 1');
  }

  Future<void> saveSelectedTheme(String themeKey) async {
    if (_useWebMemoryStore) {
      _webSettings['selected_theme'] = themeKey;
      return;
    }

    final db = await _database();
    await db.insert(
      'app_settings',
      {
        'key': 'selected_theme',
        'value': themeKey,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSelectedTheme() async {
    if (_useWebMemoryStore) {
      return _webSettings['selected_theme'];
    }

    final db = await _database();
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['selected_theme'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first['value'] as String?;
  }

  Future<void> saveMusicEnabled(bool enabled) async {
    if (_useWebMemoryStore) {
      _webSettings['music_enabled'] = enabled ? '1' : '0';
      return;
    }

    final db = await _database();
    await db.insert(
      'app_settings',
      {
        'key': 'music_enabled',
        'value': enabled ? '1' : '0',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool?> getMusicEnabled() async {
    if (_useWebMemoryStore) {
      final value = _webSettings['music_enabled'];
      if (value == null) {
        return null;
      }
      return value == '1' || value.toLowerCase() == 'true';
    }

    final db = await _database();
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['music_enabled'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['value'] as String?;
    if (value == null) {
      return null;
    }

    return value == '1' || value.toLowerCase() == 'true';
  }

  Future<void> saveMusicVolume(double volume) async {
    if (_useWebMemoryStore) {
      _webSettings['music_volume'] = volume.clamp(0.0, 1.0).toString();
      return;
    }

    final db = await _database();
    await db.insert(
      'app_settings',
      {
        'key': 'music_volume',
        'value': volume.clamp(0.0, 1.0).toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double?> getMusicVolume() async {
    if (_useWebMemoryStore) {
      final value = _webSettings['music_volume'];
      return value == null ? null : double.tryParse(value);
    }

    final db = await _database();
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['music_volume'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['value'] as String?;
    if (value == null) {
      return null;
    }

    return double.tryParse(value);
  }

  Future<void> saveSfxEnabled(bool enabled) async {
    if (_useWebMemoryStore) {
      _webSettings['sfx_enabled'] = enabled ? '1' : '0';
      return;
    }

    final db = await _database();
    await db.insert(
      'app_settings',
      {
        'key': 'sfx_enabled',
        'value': enabled ? '1' : '0',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool?> getSfxEnabled() async {
    if (_useWebMemoryStore) {
      final value = _webSettings['sfx_enabled'];
      if (value == null) {
        return null;
      }
      return value == '1' || value.toLowerCase() == 'true';
    }

    final db = await _database();
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['sfx_enabled'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['value'] as String?;
    if (value == null) {
      return null;
    }

    return value == '1' || value.toLowerCase() == 'true';
  }

  Future<void> saveSfxVolume(double volume) async {
    if (_useWebMemoryStore) {
      _webSettings['sfx_volume'] = volume.clamp(0.0, 1.0).toString();
      return;
    }

    final db = await _database();
    await db.insert(
      'app_settings',
      {
        'key': 'sfx_volume',
        'value': volume.clamp(0.0, 1.0).toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double?> getSfxVolume() async {
    if (_useWebMemoryStore) {
      final value = _webSettings['sfx_volume'];
      return value == null ? null : double.tryParse(value);
    }

    final db = await _database();
    final rows = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['sfx_volume'],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['value'] as String?;
    if (value == null) {
      return null;
    }

    return double.tryParse(value);
  }

  Future<void> updateLocalStudentProfile({
    required int studentId,
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    if (_useWebMemoryStore) {
      final normalizedBirthday = _normalizeBirthday(birthday);
      for (final row in _webStudentsLocal) {
        if ((row['student_id'] as num?)?.toInt() == studentId) {
          row['first_name'] = _normalizeLowerText(firstName);
          row['last_name'] = _normalizeLowerText(lastName);
          row['nickname'] = _normalizeLowerText(nickname);
          row['birthday'] = normalizedBirthday;
          row['sex'] = sex.trim();
          row['area'] = area == null ? null : _normalizeLowerText(area);
        }
      }
      return;
    }

    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);
    await db.update(
      'students_local',
      {
        'first_name': _normalizeLowerText(firstName),
        'last_name': _normalizeLowerText(lastName),
        'nickname': _normalizeLowerText(nickname),
        'birthday': normalizedBirthday,
        'sex': sex.trim(),
        'area': area == null ? null : _normalizeLowerText(area),
      },
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> queueOfflineProfileUpdate({
    required int studentId,
    required String firstName,
    required String lastName,
    required String nickname,
    required String birthday,
    required String sex,
    String? area,
  }) async {
    if (_useWebMemoryStore) {
      final normalizedBirthday = _normalizeBirthday(birthday);
      final now = DateTime.now().toIso8601String();
      _webPendingProfileUpdates.removeWhere(
        (row) => (row['student_id'] as num?)?.toInt() == studentId,
      );
      _webPendingProfileUpdates.add({
        'id': _nextWebId(_webPendingProfileUpdates),
        'student_id': studentId,
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'birthday': normalizedBirthday,
        'sex': sex,
        'area': area,
        'created_at': now,
      });
      return;
    }

    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);
    final now = DateTime.now().toIso8601String();

    await db.delete(
      'pending_profile_updates',
      where: 'student_id = ?',
      whereArgs: [studentId],
    );

    await db.insert(
      'pending_profile_updates',
      {
        'student_id': studentId,
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'birthday': normalizedBirthday,
        'sex': sex,
        'area': area,
        'created_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> syncPendingRegistrations({
    required RegisterRemoteFn registerRemote,
  }) async {
    if (_useWebMemoryStore) {
      Object? lastError;

      for (final localRow in _webStudentsLocal.where(
        (row) => ((row['is_synced'] as num?)?.toInt() ?? 0) == 0,
      )) {
        final alreadyQueued = _webPendingRegistrations.any(
          (row) => _matchesIdentity(
            row,
            (localRow['nickname'] as String?) ?? '',
            (localRow['birthday'] as String?) ?? '',
          ),
        );
        if (!alreadyQueued) {
          _webPendingRegistrations.add({
            'id': _nextWebId(_webPendingRegistrations),
            'first_name': localRow['first_name'],
            'last_name': localRow['last_name'],
            'nickname': localRow['nickname'],
            'birthday': localRow['birthday'],
            'sex': localRow['sex'],
            'area': localRow['area'],
            'created_at': localRow['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      final pending = _webPendingRegistrations
          .map(Map<String, dynamic>.from)
          .toList()
        ..sort((a, b) =>
            ((a['id'] as num?)?.toInt() ?? 0).compareTo(
              (b['id'] as num?)?.toInt() ?? 0,
            ));

      for (final row in pending) {
        final id = row['id'] as int;
        final rawBirthday = row['birthday'] as String;
        final normalizedBirthday = _normalizeBirthday(rawBirthday);
        try {
          final syncedStudentId = await registerRemote(
            firstName: row['first_name'] as String,
            lastName: row['last_name'] as String,
            nickname: row['nickname'] as String,
            birthday: normalizedBirthday,
            sex: row['sex'] as String,
            area: row['area'] as String?,
          );

          final localRow = _pickPreferredRow(
            _webStudentsLocal.where(
              (entry) => _matchesIdentity(
                entry,
                row['nickname'] as String,
                normalizedBirthday,
              ),
            ),
          );

          final oldStudentId = (localRow?['student_id'] as num?)?.toInt();
          final resolvedStudentId = syncedStudentId ?? oldStudentId;

          for (final entry in _webStudentsLocal) {
            if (_matchesIdentity(
              entry,
              row['nickname'] as String,
              normalizedBirthday,
            )) {
              entry['is_synced'] = 1;
              entry['birthday'] = normalizedBirthday;
              if (resolvedStudentId != null) {
                entry['student_id'] = resolvedStudentId;
              }
            }
          }

          if (resolvedStudentId != null &&
              oldStudentId != null &&
              oldStudentId != resolvedStudentId) {
            for (final scoreRow in _webPendingScores) {
              if ((scoreRow['student_id'] as num?)?.toInt() == oldStudentId) {
                scoreRow['student_id'] = resolvedStudentId;
              }
            }
            for (final progressRow in _webPendingProgress) {
              if ((progressRow['student_id'] as num?)?.toInt() == oldStudentId) {
                progressRow['student_id'] = resolvedStudentId;
              }
            }
            for (final profileRow in _webPendingProfileUpdates) {
              if ((profileRow['student_id'] as num?)?.toInt() == oldStudentId) {
                profileRow['student_id'] = resolvedStudentId;
              }
            }
          }

          _webPendingRegistrations.removeWhere(
            (entry) => (entry['id'] as num?)?.toInt() == id,
          );
        } catch (error) {
          lastError = error;
          break;
        }
      }

      if (lastError != null) {
        throw lastError;
      }
      return;
    }

    final db = await _database();
    Object? lastError;

    // Self-heal queue entries for legacy local accounts that were never enqueued.
    await db.execute('''
      INSERT OR IGNORE INTO pending_registrations (
        first_name,
        last_name,
        nickname,
        birthday,
        sex,
        area,
        created_at
      )
      SELECT
        first_name,
        last_name,
        nickname,
        birthday,
        sex,
        area,
        COALESCE(created_at, CURRENT_TIMESTAMP)
      FROM students_local
      WHERE is_synced = 0
    ''');

    final pending = await db.query(
      'pending_registrations',
      orderBy: 'id ASC',
    );

    for (final row in pending) {
      final id = row['id'] as int;
      final rawBirthday = row['birthday'] as String;
      final normalizedBirthday = _normalizeBirthday(rawBirthday);
      try {
        final syncedStudentId = await registerRemote(
          firstName: row['first_name'] as String,
          lastName: row['last_name'] as String,
          nickname: row['nickname'] as String,
          birthday: normalizedBirthday,
          sex: row['sex'] as String,
          area: row['area'] as String?,
        );

        final localRows = await db.query(
          'students_local',
          columns: ['student_id'],
          where: 'nickname = ? AND (birthday = ? OR birthday = ?)',
          whereArgs: [row['nickname'], rawBirthday, normalizedBirthday],
          limit: 1,
        );

        final oldStudentId = localRows.isEmpty
            ? null
            : (localRows.first['student_id'] as num?)?.toInt();

        final resolvedStudentId = syncedStudentId ?? oldStudentId;

        await db.update(
          'students_local',
          {
            'is_synced': 1,
            'birthday': normalizedBirthday,
            ...?resolvedStudentId == null ? null : {'student_id': resolvedStudentId},
          },
          where: 'nickname = ? AND (birthday = ? OR birthday = ?)',
          whereArgs: [row['nickname'], rawBirthday, normalizedBirthday],
        );

        if (resolvedStudentId != null && oldStudentId != null && oldStudentId != resolvedStudentId) {
          await db.update(
            'pending_scores',
            {'student_id': resolvedStudentId},
            where: 'student_id = ?',
            whereArgs: [oldStudentId],
          );

          await db.update(
            'pending_progress',
            {'student_id': resolvedStudentId},
            where: 'student_id = ?',
            whereArgs: [oldStudentId],
          );

          await db.update(
            'pending_profile_updates',
            {'student_id': resolvedStudentId},
            where: 'student_id = ?',
            whereArgs: [oldStudentId],
          );
        }

        await db.delete(
          'pending_registrations',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (error) {
        // Keep the row in queue; the next online attempt will retry.
        lastError = error;
        break;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  Future<void> syncPendingScores({
    required SubmitScoreRemoteFn submitScoreRemote,
  }) async {
    if (_useWebMemoryStore) {
      Object? lastError;
      final pending = _webPendingScores.map(Map<String, dynamic>.from).toList()
        ..sort((a, b) =>
            ((a['id'] as num?)?.toInt() ?? 0).compareTo(
              (b['id'] as num?)?.toInt() ?? 0,
            ));

      for (final row in pending) {
        final id = row['id'] as int;
        try {
          await submitScoreRemote(
            studentId: (row['student_id'] as num).toInt(),
            grade: row['grade'] as String,
            subject: row['subject'] as String,
            difficulty: row['difficulty'] as String,
            score: (row['score'] as num).toInt(),
            total: (row['total'] as num).toInt(),
            playedAt: row['played_at'] as String,
          );

          _webPendingScores.removeWhere(
            (entry) => (entry['id'] as num?)?.toInt() == id,
          );
        } catch (error) {
          lastError = error;
          break;
        }
      }

      if (lastError != null) {
        throw lastError;
      }
      return;
    }

    final db = await _database();
    final pending = await db.query('pending_scores', orderBy: 'id ASC');
    Object? lastError;

    for (final row in pending) {
      final id = row['id'] as int;
      try {
        await submitScoreRemote(
          studentId: (row['student_id'] as num).toInt(),
          grade: row['grade'] as String,
          subject: row['subject'] as String,
          difficulty: row['difficulty'] as String,
          score: (row['score'] as num).toInt(),
          total: (row['total'] as num).toInt(),
          playedAt: row['played_at'] as String,
        );

        await db.delete(
          'pending_scores',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (error) {
        // Stop at first failure to preserve queue order.
        lastError = error;
        break;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  Future<void> syncPendingProgress({
    required SubmitProgressRemoteFn submitProgressRemote,
  }) async {
    if (_useWebMemoryStore) {
      Object? lastError;
      final pending = _webPendingProgress.map(Map<String, dynamic>.from).toList()
        ..sort((a, b) =>
            ((a['id'] as num?)?.toInt() ?? 0).compareTo(
              (b['id'] as num?)?.toInt() ?? 0,
            ));

      for (final row in pending) {
        final id = row['id'] as int;
        try {
          await submitProgressRemote(
            studentId: (row['student_id'] as num).toInt(),
            grade: row['grade'] as String,
            subject: row['subject'] as String,
            highestDiffPassed: (row['highest_diff_passed'] as num?)?.toInt(),
            totalTimePlayed: (row['total_time_played'] as num).toInt(),
            lastPlayedAt: row['last_played_at'] as String,
          );

          _webPendingProgress.removeWhere(
            (entry) => (entry['id'] as num?)?.toInt() == id,
          );
        } catch (error) {
          lastError = error;
          break;
        }
      }

      if (lastError != null) {
        throw lastError;
      }
      return;
    }

    final db = await _database();
    final pending = await db.query('pending_progress', orderBy: 'id ASC');
    Object? lastError;

    for (final row in pending) {
      final id = row['id'] as int;
      try {
        await submitProgressRemote(
          studentId: (row['student_id'] as num).toInt(),
          grade: row['grade'] as String,
          subject: row['subject'] as String,
          highestDiffPassed: (row['highest_diff_passed'] as num?)?.toInt(),
          totalTimePlayed: (row['total_time_played'] as num).toInt(),
          lastPlayedAt: row['last_played_at'] as String,
        );

        await db.delete(
          'pending_progress',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (error) {
        // Stop at first failure to preserve queue order.
        lastError = error;
        break;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  Future<void> syncPendingProfileUpdates({
    required UpdateProfileRemoteFn updateProfileRemote,
  }) async {
    if (_useWebMemoryStore) {
      Object? lastError;
      final pending = _webPendingProfileUpdates
          .map(Map<String, dynamic>.from)
          .toList()
        ..sort((a, b) =>
            ((a['id'] as num?)?.toInt() ?? 0).compareTo(
              (b['id'] as num?)?.toInt() ?? 0,
            ));

      for (final row in pending) {
        final id = row['id'] as int;
        try {
          await updateProfileRemote(
            studentId: (row['student_id'] as num).toInt(),
            firstName: row['first_name'] as String,
            lastName: row['last_name'] as String,
            nickname: row['nickname'] as String,
            birthday: row['birthday'] as String,
            sex: row['sex'] as String,
            area: row['area'] as String?,
          );

          _webPendingProfileUpdates.removeWhere(
            (entry) => (entry['id'] as num?)?.toInt() == id,
          );
        } catch (error) {
          lastError = error;
          break;
        }
      }

      if (lastError != null) {
        throw lastError;
      }
      return;
    }

    final db = await _database();
    final pending = await db.query('pending_profile_updates', orderBy: 'id ASC');
    Object? lastError;

    for (final row in pending) {
      final id = row['id'] as int;
      try {
        await updateProfileRemote(
          studentId: (row['student_id'] as num).toInt(),
          firstName: row['first_name'] as String,
          lastName: row['last_name'] as String,
          nickname: row['nickname'] as String,
          birthday: row['birthday'] as String,
          sex: row['sex'] as String,
          area: row['area'] as String?,
        );

        await db.delete(
          'pending_profile_updates',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (error) {
        lastError = error;
        break;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingScoresForStudent(int studentId) async {
    if (_useWebMemoryStore) {
      final rows = _webPendingScores
          .where((row) => (row['student_id'] as num?)?.toInt() == studentId)
          .map(Map<String, dynamic>.from)
          .toList()
        ..sort((a, b) {
          final playedCompare = (b['played_at'] as String? ?? '').compareTo(
            a['played_at'] as String? ?? '',
          );
          if (playedCompare != 0) {
            return playedCompare;
          }
          return ((b['id'] as num?)?.toInt() ?? 0).compareTo(
            (a['id'] as num?)?.toInt() ?? 0,
          );
        });
      return rows;
    }

    final db = await _database();
    final rows = await db.query(
      'pending_scores',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'played_at DESC, id DESC',
    );
    return rows;
  }

  Future<List<Map<String, dynamic>>> getPendingProgressForStudent(int studentId) async {
    if (_useWebMemoryStore) {
      final rows = _webPendingProgress
          .where((row) => (row['student_id'] as num?)?.toInt() == studentId)
          .map(Map<String, dynamic>.from)
          .toList()
        ..sort((a, b) {
          final playedCompare =
              (b['last_played_at'] as String? ?? '').compareTo(
                a['last_played_at'] as String? ?? '',
              );
          if (playedCompare != 0) {
            return playedCompare;
          }
          return ((b['id'] as num?)?.toInt() ?? 0).compareTo(
            (a['id'] as num?)?.toInt() ?? 0,
          );
        });
      return rows;
    }

    final db = await _database();
    final rows = await db.query(
      'pending_progress',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'last_played_at DESC, id DESC',
    );
    return rows;
  }
}
