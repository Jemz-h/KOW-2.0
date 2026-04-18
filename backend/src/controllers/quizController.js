const db = require('../config/db');
const asyncHandler = require('express-async-handler');
const { serializeQuestionImage } = require('../utils/questionImage');

// @desc    Get quiz questions by grade, subject, and difficulty
// @route   GET /api/quiz/questions
// @access  Public
const getQuestions = asyncHandler(async (req, res) => {
  const { grade, subject, difficulty } = req.query;

  if (!grade || !subject) {
    res.status(400);
    throw new Error('Please provide grade and subject query parameters');
  }

  const activeFilter = db.isOracle() ? 'NVL(q.is_active, 1) = 1' : 'COALESCE(q.is_active, 1) = 1';
  const difficultyFilter = difficulty
    ? 'AND UPPER(d.difficulty) = UPPER(:difficulty)'
    : '';
  const result = await db.execute(`
    SELECT q.question_id,
           q.question_txt,
           q.question_image,
           q.option_a,
           q.option_b,
           q.option_c,
           q.option_d,
          q.option_a_image,
          q.option_b_image,
          q.option_c_image,
          q.option_d_image,
           q.correct_opt,
           q.is_active,
           q.updated_at
    FROM questionTb q
    JOIN subjectTb s ON q.subject_id = s.subject_id
    JOIN gradelvlTb g ON q.gradelvl_id = g.gradelvl_id
    JOIN diffTb d ON q.diff_id = d.diff_id
    WHERE UPPER(g.gradelvl) = UPPER(:grade)
      AND UPPER(s.subject) = UPPER(:subject)
      ${difficultyFilter}
      AND ${activeFilter}
    ORDER BY q.question_id
  `, difficulty ? { grade, subject, difficulty } : { grade, subject });

  if (result.rows.length === 0) {
    return res.status(404).json({ success: false, message: 'No questions found for the provided filters' });
  }

  const letterToIndex = { A: 0, B: 1, C: 2, D: 3 };
  const questions = result.rows.map((row) => {
    const normalizedRow = Object.entries(row).reduce((accumulator, [key, value]) => {
      accumulator[key.toUpperCase()] = value;
      return accumulator;
    }, {});
    const correctOpt = String(normalizedRow.CORRECT_OPT || '').toUpperCase();
    const imageBlob = serializeQuestionImage(normalizedRow.QUESTION_IMAGE);
    const choiceImageBlobs = [
      serializeQuestionImage(normalizedRow.OPTION_A_IMAGE),
      serializeQuestionImage(normalizedRow.OPTION_B_IMAGE),
      serializeQuestionImage(normalizedRow.OPTION_C_IMAGE),
      serializeQuestionImage(normalizedRow.OPTION_D_IMAGE),
    ];
    return {
      id: normalizedRow.QUESTION_ID,
      prompt: normalizedRow.QUESTION_TXT,
      imageBlob,
      imagePath: imageBlob,
      funFact: null,
      points: 1,
      choices: [normalizedRow.OPTION_A, normalizedRow.OPTION_B, normalizedRow.OPTION_C, normalizedRow.OPTION_D],
      choiceImageBlobs,
      choiceImages: choiceImageBlobs,
      correctIndex: letterToIndex[correctOpt] ?? 0,
      updatedAt: normalizedRow.UPDATED_AT
    };
  });

  res.status(200).json({ 
    success: true, 
    count: questions.length,
    questions
  });
});

// @desc    Submit quiz score for a student
// @route   POST /api/quiz/score
// @access  Public
const submitScore = asyncHandler(async (req, res) => {
  const {
    studentId,
    grade,
    subject,
    difficulty,
    score,
    total,
    playedAt,
    played_at,
    deviceUuid,
    device_uuid
  } = req.body;

  const playedAtValue = playedAt || played_at || null;
  const deviceUuidValue = deviceUuid || device_uuid || null;

  if (!studentId || !grade || !subject || !difficulty || score === undefined) {
    res.status(400);
    throw new Error('Please provide studentId, grade, subject, difficulty, and score');
  }

  const userCheck = await db.execute(
    `SELECT stud_id FROM studentTb WHERE stud_id = :studentId`,
    { studentId }
  );
  
  if (userCheck.rows.length === 0) {
    res.status(404);
    throw new Error(`Student not found with ID of ${studentId}`);
  }

  const mapping = await db.execute(
    `SELECT g.gradelvl_id, s.subject_id, d.diff_id
     FROM gradelvlTb g
     CROSS JOIN subjectTb s
     CROSS JOIN diffTb d
     WHERE UPPER(g.gradelvl) = UPPER(:grade)
       AND UPPER(s.subject) = UPPER(:subject)
       AND UPPER(d.difficulty) = UPPER(:difficulty)`,
    { grade, subject, difficulty }
  );

  if (mapping.rows.length === 0) {
    res.status(404);
    throw new Error('Grade, subject, or difficulty not found');
  }

  const row = mapping.rows[0];
  const maxScore = Number(total) > 0 ? Number(total) : 10;
  const scoreValue = Number(score);
  const passed = scoreValue / maxScore >= 0.7 ? 1 : 0;

  // Idempotency guard: skip duplicate score events on retry/replay.
  if (playedAtValue) {
    const duplicateCheckSql = db.isOracle()
      ? `SELECT COUNT(*) AS CNT
         FROM scoreTb
         WHERE stud_id = :studentId
           AND subject_id = :subjectId
           AND gradelvl_id = :gradeLevelId
           AND diff_id = :diffId
           AND played_at = TO_DATE(SUBSTR(REPLACE(:playedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
           AND (:deviceUuid IS NULL OR NVL(device_uuid, '__NONE__') = NVL(:deviceUuid, '__NONE__'))`
      : `SELECT COUNT(*) AS CNT
         FROM scoreTb
         WHERE stud_id = :studentId
           AND subject_id = :subjectId
           AND gradelvl_id = :gradeLevelId
           AND diff_id = :diffId
           AND played_at = :playedAt
           AND (:deviceUuid IS NULL OR COALESCE(device_uuid, '__NONE__') = COALESCE(:deviceUuid, '__NONE__'))`;

    const duplicateCheck = await db.execute(
      duplicateCheckSql,
      {
        studentId,
        subjectId: row.SUBJECT_ID,
        gradeLevelId: row.GRADELVL_ID,
        diffId: row.DIFF_ID,
        playedAt: playedAtValue,
        deviceUuid: deviceUuidValue
      }
    );

    const duplicateCount = Number(duplicateCheck.rows?.[0]?.CNT || 0);
    if (duplicateCount > 0) {
      return res.status(200).json({
        success: true,
        message: 'Duplicate score event skipped',
        duplicate: true
      });
    }
  }

  if (db.isOracle()) {
    await db.execute(
      `INSERT INTO scoreTb (
         stud_id,
         subject_id,
         gradelvl_id,
         diff_id,
         score,
         max_score,
         passed,
         played_at,
         device_uuid,
         synced_at
       )
       VALUES (
         :studentId,
         :subjectId,
         :gradeLevelId,
         :diffId,
         :score,
         :maxScore,
         :passed,
         CASE
           WHEN :playedAt IS NULL THEN SYSDATE
           ELSE TO_DATE(SUBSTR(REPLACE(:playedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
         END,
         :deviceUuid,
         SYSDATE
       )`,
      {
        studentId,
        subjectId: row.SUBJECT_ID,
        gradeLevelId: row.GRADELVL_ID,
        diffId: row.DIFF_ID,
        score: scoreValue,
        maxScore,
        passed,
        playedAt: playedAtValue,
        deviceUuid: deviceUuidValue
      },
      { autoCommit: true }
    );

    await db.execute(
      `MERGE INTO progressTb p
       USING (
         SELECT :studentId AS stud_id,
                :subjectId AS subject_id,
                :gradeLevelId AS gradelvl_id
         FROM DUAL
       ) src
       ON (
         p.stud_id = src.stud_id
         AND p.subject_id = src.subject_id
         AND p.gradelvl_id = src.gradelvl_id
       )
       WHEN MATCHED THEN
         UPDATE SET
           p.highest_diff_passed = CASE
             WHEN :passed = 1 AND :diffId > NVL(p.highest_diff_passed, 0)
               THEN :diffId
             ELSE NVL(p.highest_diff_passed, 0)
           END,
           p.last_played_at = CASE
             WHEN :playedAt IS NULL THEN SYSDATE
             ELSE TO_DATE(SUBSTR(REPLACE(:playedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
           END
       WHEN NOT MATCHED THEN
         INSERT (
           progress_id,
           stud_id,
           subject_id,
           gradelvl_id,
           highest_diff_passed,
           total_time_played,
           last_played_at
         )
         VALUES (
           seq_score_id.NEXTVAL,
           :studentId,
           :subjectId,
           :gradeLevelId,
           CASE WHEN :passed = 1 THEN :diffId ELSE 0 END,
           0,
           CASE
             WHEN :playedAt IS NULL THEN SYSDATE
             ELSE TO_DATE(SUBSTR(REPLACE(:playedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
           END
         )`,
      {
        studentId,
        subjectId: row.SUBJECT_ID,
        gradeLevelId: row.GRADELVL_ID,
        diffId: row.DIFF_ID,
        passed,
        playedAt: playedAtValue
      },
      { autoCommit: true }
    );
  } else {
    const sqlitePlayedAtValue = playedAtValue || new Date().toISOString();

    await db.execute(
      `INSERT INTO scoreTb (
         stud_id,
         subject_id,
         gradelvl_id,
         diff_id,
         score,
         max_score,
         passed,
         played_at,
         device_uuid,
         synced_at
       )
       VALUES (
         :studentId,
         :subjectId,
         :gradeLevelId,
         :diffId,
         :score,
         :maxScore,
         :passed,
         :playedAt,
         :deviceUuid,
         CURRENT_TIMESTAMP
       )`,
      {
        studentId,
        subjectId: row.SUBJECT_ID,
        gradeLevelId: row.GRADELVL_ID,
        diffId: row.DIFF_ID,
        score: scoreValue,
        maxScore,
        passed,
        playedAt: sqlitePlayedAtValue,
        deviceUuid: deviceUuidValue
      },
      { autoCommit: true }
    );

    await db.execute(
      `INSERT INTO progressTb (
         stud_id,
         subject_id,
         gradelvl_id,
         highest_diff_passed,
         total_time_played,
         last_played_at
       )
       VALUES (
         :studentId,
         :subjectId,
         :gradeLevelId,
         CASE WHEN :passed = 1 THEN :diffId ELSE 0 END,
         0,
         :playedAt
       )
       ON CONFLICT (stud_id, subject_id, gradelvl_id)
       DO UPDATE SET
         highest_diff_passed = CASE
           WHEN excluded.highest_diff_passed > COALESCE(progressTb.highest_diff_passed, 0)
             THEN excluded.highest_diff_passed
           ELSE progressTb.highest_diff_passed
         END,
         last_played_at = excluded.last_played_at`,
      {
        studentId,
        subjectId: row.SUBJECT_ID,
        gradeLevelId: row.GRADELVL_ID,
        diffId: row.DIFF_ID,
        passed,
        playedAt: sqlitePlayedAtValue
      },
      { autoCommit: true }
    );
  }

  res.status(201).json({ 
    success: true, 
    message: 'Score submitted successfully'
  });
});

// @desc    Get all quiz scores for a student
// @route   GET /api/quiz/scores/:studentId
// @access  Public
const getScores = asyncHandler(async (req, res) => {
  const { studentId } = req.params;

  if (!studentId) {
    res.status(400);
    throw new Error('Student ID is required');
  }

  const result = await db.execute(`
      SELECT sc.score_id,
        sc.score,
        sc.max_score,
        sc.passed,
        sc.played_at,
        sc.synced_at,
        sc.device_uuid,
        sub.subject,
        gl.gradelvl,
        d.difficulty
      FROM scoreTb sc
      JOIN subjectTb sub ON sc.subject_id = sub.subject_id
      JOIN gradelvlTb gl ON sc.gradelvl_id = gl.gradelvl_id
      JOIN diffTb d ON sc.diff_id = d.diff_id
      WHERE sc.stud_id = :studentId
      ORDER BY sc.played_at DESC
    `, { studentId });
  
  res.status(200).json({ 
    success: true, 
    count: result.rows.length,
    scores: result.rows 
  });
});

module.exports = { getQuestions, submitScore, getScores };