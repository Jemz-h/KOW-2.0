<<<<<<< HEAD
const db = require('../config/db');
const asyncHandler = require('express-async-handler');
=======
const {
  upsertProgress,
  getProgressByStudent,
} = require('../repositories/progress.repository');
const { dbMode } = require('../config/env');
>>>>>>> 50596e6deeea80c069a5998050186a37243c272b

// @desc    Create or update progress
// @route   POST /api/progress
// @access  Public
<<<<<<< HEAD
const saveProgress = asyncHandler(async (req, res) => {
  const {
    userID,
    studentId,
    subjectId,
    subject,
    gradeLevelId,
    grade,
    difficultyId,
    highestDiffPassed,
    highest_diff_passed,
    totalTimePlayed,
    total_time_played,
    timeSpent,
    lastPlayedAt,
    last_played_at
  } = req.body;

  const resolvedStudentId = studentId || userID;

  if (!resolvedStudentId) {
    res.status(400);
    throw new Error('Please provide studentId (or userID)');
  }

  const userCheck = await db.execute(
    `SELECT stud_id FROM studentTb WHERE stud_id = :studentId`,
    { studentId: resolvedStudentId }
  );
  
  if (userCheck.rows.length === 0) {
    res.status(404);
    throw new Error(`Student not found with ID of ${resolvedStudentId}`);
  }

  let resolvedSubjectId = subjectId || null;
  let resolvedGradeLevelId = gradeLevelId || null;
  let resolvedDiffId = highestDiffPassed || highest_diff_passed || difficultyId || null;

  if (!resolvedSubjectId && subject) {
    const subjectRes = await db.execute(
      `SELECT subject_id FROM subjectTb WHERE UPPER(subject) = UPPER(:subject)`,
      { subject }
    );
    resolvedSubjectId = subjectRes.rows[0]?.SUBJECT_ID || null;
  }

  if (!resolvedGradeLevelId && grade) {
    const gradeRes = await db.execute(
      `SELECT gradelvl_id FROM gradelvlTb WHERE UPPER(gradelvl) = UPPER(:grade)`,
      { grade }
    );
    resolvedGradeLevelId = gradeRes.rows[0]?.GRADELVL_ID || null;
  }

  if (!resolvedSubjectId || !resolvedGradeLevelId) {
    res.status(400);
    throw new Error('Please provide subject/subjectId and grade/gradeLevelId');
  }

  const binds = {
    studId: resolvedStudentId,
    subjectId: resolvedSubjectId,
    gradeLevelId: resolvedGradeLevelId,
    highestDiffPassed: resolvedDiffId,
    timeToAdd: totalTimePlayed ?? total_time_played ?? timeSpent ?? 0,
    lastPlayedAt: lastPlayedAt || last_played_at || null
  };

  // Idempotency guard: skip exact replay events for the same last_played_at marker.
  if (binds.lastPlayedAt) {
    const duplicateCheckSql = db.isOracle()
      ? `SELECT COUNT(*) AS CNT
         FROM progressTb
         WHERE stud_id = :studId
           AND subject_id = :subjectId
           AND gradelvl_id = :gradeLevelId
           AND last_played_at = TO_DATE(SUBSTR(REPLACE(:lastPlayedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')`
      : `SELECT COUNT(*) AS CNT
         FROM progressTb
         WHERE stud_id = :studId
           AND subject_id = :subjectId
           AND gradelvl_id = :gradeLevelId
           AND last_played_at = :lastPlayedAt`;

    const duplicateCheck = await db.execute(duplicateCheckSql, {
      studId: binds.studId,
      subjectId: binds.subjectId,
      gradeLevelId: binds.gradeLevelId,
      lastPlayedAt: binds.lastPlayedAt
    });

    const duplicateCount = Number(duplicateCheck.rows?.[0]?.CNT || 0);
    if (duplicateCount > 0) {
      return res.status(200).json({
        success: true,
        message: 'Duplicate progress event skipped',
        duplicate: true,
        rowsAffected: 0
      });
    }
  }

  let result;

  if (db.isOracle()) {
    result = await db.execute(
      `MERGE INTO progressTb p
       USING (
         SELECT :studId AS stud_id,
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
             WHEN :highestDiffPassed IS NOT NULL AND :highestDiffPassed > NVL(p.highest_diff_passed, 0)
               THEN :highestDiffPassed
             ELSE p.highest_diff_passed
           END,
           p.total_time_played = NVL(p.total_time_played, 0) + NVL(:timeToAdd, 0),
           p.last_played_at = CASE
             WHEN :lastPlayedAt IS NULL THEN SYSDATE
             ELSE TO_DATE(SUBSTR(REPLACE(:lastPlayedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
           END
       WHEN NOT MATCHED THEN
         INSERT (
           stud_id,
           subject_id,
           gradelvl_id,
           highest_diff_passed,
           total_time_played,
           last_played_at
         )
         VALUES (
           :studId,
           :subjectId,
           :gradeLevelId,
           NVL(:highestDiffPassed, 0),
           NVL(:timeToAdd, 0),
           CASE
             WHEN :lastPlayedAt IS NULL THEN SYSDATE
             ELSE TO_DATE(SUBSTR(REPLACE(:lastPlayedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
           END
         )`,
      binds,
      { autoCommit: true }
    );
  } else {
    result = await db.execute(
      `INSERT INTO progressTb (
         stud_id,
         subject_id,
         gradelvl_id,
         highest_diff_passed,
         total_time_played,
         last_played_at
       )
       VALUES (
         :studId,
         :subjectId,
         :gradeLevelId,
         COALESCE(:highestDiffPassed, 0),
         COALESCE(:timeToAdd, 0),
         COALESCE(:lastPlayedAt, CURRENT_TIMESTAMP)
       )
       ON CONFLICT (stud_id, subject_id, gradelvl_id)
       DO UPDATE SET
         highest_diff_passed = CASE
           WHEN excluded.highest_diff_passed > COALESCE(progressTb.highest_diff_passed, 0)
             THEN excluded.highest_diff_passed
           ELSE progressTb.highest_diff_passed
         END,
         total_time_played = COALESCE(progressTb.total_time_played, 0) + COALESCE(excluded.total_time_played, 0),
         last_played_at = COALESCE(excluded.last_played_at, progressTb.last_played_at)`,
      binds,
      { autoCommit: true }
    );
  }

  res.status(201).json({ 
    success: true,
    message: 'Progress saved successfully',
    rowsAffected: result.rowsAffected
  });
});

// @desc    Get user progress
// @route   GET /api/progress/user/:userId
// @access  Public
const getUserProgress = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  
  const userCheck = await db.execute(
    `SELECT stud_id FROM studentTb WHERE stud_id = :userId`,
    { userId }
  );
  
  if (userCheck.rows.length === 0) {
    res.status(404);
    throw new Error(`Student not found with ID of ${userId}`);
  }
  
  const result = await db.execute(
    `SELECT p.progress_id,
            p.stud_id,
            p.subject_id,
            s.subject,
            p.gradelvl_id,
            g.gradelvl,
            p.highest_diff_passed,
            d.difficulty AS highest_diff_name,
            p.total_time_played,
            p.last_played_at
     FROM progressTb p
     JOIN subjectTb s ON p.subject_id = s.subject_id
     JOIN gradelvlTb g ON p.gradelvl_id = g.gradelvl_id
     LEFT JOIN diffTb d ON p.highest_diff_passed = d.diff_id
     WHERE p.stud_id = :userId
     ORDER BY p.last_played_at DESC`,
    { userId }
  );
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

module.exports = { saveProgress, getUserProgress };

=======
async function createOrUpdateProgress(req, res, next) {
  try {
    const {
      studentId,
      levelId,
      score = 0,
      completed = false,
      subjectId,
      diffId,
    } = req.body;

    if (!studentId || !levelId) {
      return res.status(400).json({
        message: 'studentId and levelId are required.',
      });
    }

    if (dbMode === 'online') {
      const parsedStudentId = Number(studentId);
      const parsedLevelId = Number(levelId);
      if (Number.isNaN(parsedStudentId) || Number.isNaN(parsedLevelId)) {
        return res.status(400).json({
          message: 'studentId and levelId must be numeric in online mode.',
        });
      }
    }

    const numericScore = Number(score);
    if (Number.isNaN(numericScore)) {
      return res.status(400).json({ message: 'score must be numeric.' });
    }

    const data = await upsertProgress({
      studentId: String(studentId),
      levelId: String(levelId),
      score: numericScore,
      completed: Boolean(completed),
      subjectId,
      diffId,
    });

    return res.status(200).json({ message: 'Progress saved.', data });
  } catch (error) {
    return next(error);
  }
}

// @desc    Get progress by student
// @route   GET /api/progress/:studentId
// @access  Public
async function getProgress(req, res, next) {
  try {
    const rows = await getProgressByStudent(String(req.params.studentId));
    return res.status(200).json({ count: rows.length, data: rows });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createOrUpdateProgress,
  getProgress,
};
>>>>>>> 50596e6deeea80c069a5998050186a37243c272b
