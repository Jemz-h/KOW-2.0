import 'package:path/path.dart' as p;
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

class LocalSyncStore {
  LocalSyncStore._();

  static final LocalSyncStore instance = LocalSyncStore._();

  Database? _db;

  String _normalizeBirthday(String value) {
    final raw = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$').firstMatch(raw);
    if (match == null) {
      return raw;
    }

    final month = int.tryParse(match.group(2) ?? '');
    final day = int.tryParse(match.group(3) ?? '');
    if (month == null || day == null || month < 1 || month > 12 || day < 1 || day > 31) {
      return raw;
    }

    final mm = month.toString().padLeft(2, '0');
    final dd = day.toString().padLeft(2, '0');
    return '${match.group(1)}-$mm-$dd';
  }

  Future<Database> _database() async {
    if (_db != null) return _db!;

    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'kow_app.db');

    _db = await openDatabase(
      dbPath,
      version: 3,
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
      },
    );

    return _db!;
  }

  Future<void> saveSyncedStudent({
    required Student student,
    required String birthday,
  }) async {
    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);
    await db.insert(
      'students_local',
      {
        'student_id': student.studentId,
        'first_name': student.firstName,
        'last_name': student.lastName,
        'nickname': student.nickname,
        'birthday': normalizedBirthday,
        'sex': student.sex,
        'area': student.area,
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
    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);

    await db.insert(
      'students_local',
      {
        'student_id': -DateTime.now().millisecondsSinceEpoch,
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'birthday': normalizedBirthday,
        'sex': sex,
        'area': area,
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
    final db = await _database();
    final rows = await db.query(
      'students_local',
      where: 'student_id = ?',
      whereArgs: [studentId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<Map<String, dynamic>?> getMostRecentStudentProfile() async {
    final db = await _database();
    final rows = await db.query(
      'students_local',
      orderBy: 'is_synced DESC, created_at DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return rows.first;
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
    final db = await _database();
    final normalizedBirthday = _normalizeBirthday(birthday);
    await db.update(
      'students_local',
      {
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'birthday': normalizedBirthday,
        'sex': sex,
        'area': area,
      },
      where: 'student_id = ?',
      whereArgs: [studentId],
    );
  }

  Future<void> syncPendingRegistrations({
    required RegisterRemoteFn registerRemote,
  }) async {
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
}
