const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Get quiz questions by grade, subject, and difficulty
// @route   GET /api/quiz/questions
// @access  Public
const getQuestions = asyncHandler(async (req, res) => {
  const { grade, subject, difficulty } = req.query;

  if (!grade || !subject || !difficulty) {
    res.status(400);
    throw new Error('Please provide grade, subject, and difficulty query parameters');
  }

  const activeFilter = db.isOracle() ? 'NVL(q.is_active, 1) = 1' : 'COALESCE(q.is_active, 1) = 1';
  const result = await db.execute(`
    SELECT q.question_id,
           q.question_txt,
           q.option_a,
           q.option_b,
           q.option_c,
           q.option_d,
           q.correct_opt,
           q.is_active,
           q.updated_at
    FROM questionTb q
    JOIN subjectTb s ON q.subject_id = s.subject_id
    JOIN gradelvlTb g ON q.gradelvl_id = g.gradelvl_id
    JOIN diffTb d ON q.diff_id = d.diff_id
    WHERE UPPER(g.gradelvl) = UPPER(:grade)
      AND UPPER(s.subject) = UPPER(:subject)
      AND UPPER(d.difficulty) = UPPER(:difficulty)
      AND ${activeFilter}
    ORDER BY q.question_id
  `, { grade, subject, difficulty });

  if (result.rows.length === 0) {
    return res.status(404).json({ success: false, message: 'No questions found for the provided filters' });
  }

  const letterToIndex = { A: 0, B: 1, C: 2, D: 3 };
  const questions = result.rows.map((row) => {
    const correctOpt = String(row.CORRECT_OPT || '').toUpperCase();
    return {
      id: row.QUESTION_ID,
      prompt: row.QUESTION_TXT,
      imagePath: null,
      funFact: null,
      points: 1,
      choices: [row.OPTION_A, row.OPTION_B, row.OPTION_C, row.OPTION_D],
      correctIndex: letterToIndex[correctOpt] ?? 0,
      updatedAt: row.UPDATED_AT
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
  const { studentId, grade, subject, difficulty, score, total, playedAt, deviceUuid } = req.body;

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

  if (db.isOracle()) {
    await db.execute(
      `BEGIN
         sp_upload_score(
           p_stud_id      => :studentId,
           p_subject_id   => :subjectId,
           p_gradelvl_id  => :gradeLevelId,
           p_diff_id      => :diffId,
           p_score        => :score,
           p_max_score    => :maxScore,
           p_passed       => :passed,
           p_played_at    => CASE
                               WHEN :playedAt IS NULL THEN SYSDATE
                               ELSE TO_DATE(SUBSTR(REPLACE(:playedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
                             END,
           p_device_uuid  => :deviceUuid
         );
         sp_refresh_analytics(
           p_stud_id      => :studentId,
           p_subject_id   => :subjectId,
           p_gradelvl_id  => :gradeLevelId
         );
       END;`,
      {
        studentId,
        subjectId: row.SUBJECT_ID,
        gradeLevelId: row.GRADELVL_ID,
        diffId: row.DIFF_ID,
        score: scoreValue,
        maxScore,
        passed,
        playedAt: playedAt || null,
        deviceUuid: deviceUuid || null
      },
      { autoCommit: true }
    );
  } else {
    const playedAtValue = playedAt || new Date().toISOString();

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
        playedAt: playedAtValue,
        deviceUuid: deviceUuid || null
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
        playedAt: playedAtValue
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