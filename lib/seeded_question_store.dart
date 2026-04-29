import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SeededQuestionStore {
  SeededQuestionStore._();

  static final SeededQuestionStore instance = SeededQuestionStore._();

  static const List<String> _bundledAssetPaths = <String>[
    'assets/seed/kow_offline.db',
    'backend/data/kow_offline.db',
  ];
  static const String _runtimeDbName = 'kow_seeded_questions.db';

  Database? _db;
  bool _failedToInit = false;
  Set<String>? _questionColumns;

  Future<Database?> _openReadOnlyDb() async {
    if (_db != null) {
      return _db;
    }
    if (_failedToInit) {
      return null;
    }

    try {
      final dbDir = await getDatabasesPath();
      final dbPath = p.join(dbDir, _runtimeDbName);
      final dbFile = File(dbPath);

      // Always refresh from bundled asset so updated APK content replaces
      // any stale seeded DB from older installs.
      ByteData? data;
      for (final assetPath in _bundledAssetPaths) {
        try {
          data = await rootBundle.load(assetPath);
          break;
        } catch (_) {
          // Try the next candidate path.
        }
      }
      if (data == null) {
        throw StateError('No bundled seeded DB asset found.');
      }

      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await dbFile.parent.create(recursive: true);
      await dbFile.writeAsBytes(bytes, flush: true);

      _db = await openDatabase(dbPath, readOnly: true);
      return _db;
    } catch (_) {
      _failedToInit = true;
      return null;
    }
  }

  Future<Set<String>> _loadQuestionColumns(Database db) async {
    if (_questionColumns != null) {
      return _questionColumns!;
    }

    final rows = await db.rawQuery('PRAGMA table_info(questionTb)');
    _questionColumns = rows
        .map((row) => (row['name'] ?? '').toString().trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
    return _questionColumns!;
  }

  String? _blobToBase64(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Uint8List) {
      return value.isEmpty ? null : base64Encode(value);
    }

    if (value is List<int>) {
      return value.isEmpty ? null : base64Encode(Uint8List.fromList(value));
    }

    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    if (text.startsWith('data:')) {
      final commaIndex = text.indexOf(',');
      if (commaIndex >= 0 && commaIndex < text.length - 1) {
        return text.substring(commaIndex + 1).trim();
      }
    }

    return text;
  }

  Future<String?> _loadBlobColumnAsBase64(
    Database db,
    int questionId,
    String columnName,
  ) async {
    try {
      final rows = await db.rawQuery(
        'SELECT $columnName FROM questionTb WHERE question_id = ? LIMIT 1',
        <Object>[questionId],
      );

      if (rows.isEmpty) {
        return null;
      }

      return _blobToBase64(rows.first[columnName]);
    } catch (_) {
      // If an image cell is too large or unreadable, keep quiz playable.
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getQuestions({
    required String grade,
    required String subject,
    String? difficulty,
  }) async {
    final db = await _openReadOnlyDb();
    if (db == null) {
      return const <Map<String, dynamic>>[];
    }

    final columns = await _loadQuestionColumns(db);
    final hasQuestionImage = columns.contains('question_image');
    final hasOptionAImage = columns.contains('option_a_image');
    final hasOptionBImage = columns.contains('option_b_image');
    final hasOptionCImage = columns.contains('option_c_image');
    final hasOptionDImage = columns.contains('option_d_image');

    final normalizedGrade = grade.trim().toUpperCase();
    final normalizedSubject = subject.trim().toUpperCase();
    final normalizedDifficulty = difficulty?.trim().toUpperCase();

    List<String> subjectAliases(String value) {
      switch (value) {
        case 'ENGLISH':
        case 'READING':
          return const <String>['ENGLISH', 'READING'];
        case 'FILIPINO':
          return const <String>['FILIPINO'];
        case 'WRITING':
          return const <String>['WRITING'];
        case 'MATHEMATICS':
        case 'MATH':
          return const <String>['MATHEMATICS', 'MATH'];
        case 'SCIENCE':
          return const <String>['SCIENCE'];
        default:
          return <String>[value];
      }
    }

    final subjectList = subjectAliases(normalizedSubject);
    final subjectPlaceholders = List.filled(subjectList.length, '?').join(', ');

    final where = StringBuffer(
      'UPPER(g.gradelvl) = ? AND UPPER(s.subject) IN ($subjectPlaceholders)',
    );
    final args = <Object>[normalizedGrade, ...subjectList];

    if (normalizedDifficulty != null && normalizedDifficulty.isNotEmpty) {
      where.write(' AND UPPER(d.difficulty) = ?');
      args.add(normalizedDifficulty);
    }

    final rows = await db.rawQuery('''
      SELECT q.question_id,
             q.question_txt,
             q.option_a,
             q.option_b,
             q.option_c,
             q.option_d,
             q.correct_opt
      FROM questionTb q
      JOIN subjectTb s ON q.subject_id = s.subject_id
      JOIN gradelvlTb g ON q.gradelvl_id = g.gradelvl_id
      JOIN diffTb d ON q.diff_id = d.diff_id
      WHERE ${where.toString()}
      ORDER BY q.question_id
      ''', args);

    if (rows.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    const letterToIndex = <String, int>{'A': 0, 'B': 1, 'C': 2, 'D': 3};

    final result = <Map<String, dynamic>>[];

    for (final row in rows) {
      final questionId = (row['question_id'] as num?)?.toInt();
      if (questionId == null) {
        continue;
      }

      final imageBlob = hasQuestionImage
          ? await _loadBlobColumnAsBase64(db, questionId, 'question_image')
          : null;

      final choiceImageBlobs = <String?>[
        hasOptionAImage
            ? await _loadBlobColumnAsBase64(db, questionId, 'option_a_image')
            : null,
        hasOptionBImage
            ? await _loadBlobColumnAsBase64(db, questionId, 'option_b_image')
            : null,
        hasOptionCImage
            ? await _loadBlobColumnAsBase64(db, questionId, 'option_c_image')
            : null,
        hasOptionDImage
            ? await _loadBlobColumnAsBase64(db, questionId, 'option_d_image')
            : null,
      ];
      final hasAnyChoiceImage = choiceImageBlobs.any((entry) => entry != null);

      final correctOpt = (row['correct_opt'] ?? '')
          .toString()
          .trim()
          .toUpperCase();

      result.add(<String, dynamic>{
        'id': questionId,
        'prompt': (row['question_txt'] ?? '').toString(),
        'imageBlob': imageBlob,
        'imagePath': imageBlob,
        'funFact': null,
        'points': 1,
        'choices': <String>[
          (row['option_a'] ?? '').toString(),
          (row['option_b'] ?? '').toString(),
          (row['option_c'] ?? '').toString(),
          (row['option_d'] ?? '').toString(),
        ],
        'choiceImageBlobs': hasAnyChoiceImage ? choiceImageBlobs : null,
        'choiceImages': hasAnyChoiceImage ? choiceImageBlobs : null,
        'correctIndex': letterToIndex[correctOpt] ?? 0,
      });
    }

    return result;
  }
}
