const {
  upsertProgress,
} = require('../repositories/progress.repository');
const { dbMode } = require('../config/env');
const db = require('../config/db');
const { broadcastToAdmins } = require('../services/wsHub');
const { normalizeTimestamp } = require('../utils/dateTime');

async function insertTimePlayed({ studentId, subjectId, totalTimePlayed, sessionDate, deviceUuid = null }) {
  if (!totalTimePlayed || Number(totalTimePlayed) <= 0) {
    return;
  }

  if (db.isOracle()) {
    await db.execute(
      `INSERT INTO timeplTb (
         timeplay_id,
         stud_id,
         subject_id,
         time_played,
         session_date,
         device_uuid
       )
       VALUES (
         seq_timeplay_id.NEXTVAL,
         :studentId,
         :subjectId,
         :timePlayed,
         TO_DATE(:sessionDate, 'YYYY-MM-DD HH24:MI:SS'),
         :deviceUuid
       )`,
      {
        studentId,
        subjectId,
        timePlayed: Number(totalTimePlayed),
        sessionDate,
        deviceUuid,
      },
      { autoCommit: true }
    );
    return;
  }

  await db.execute(
    `INSERT INTO timeplTb (
       stud_id,
       subject_id,
       time_played,
       session_date,
       device_uuid
     )
     VALUES (
       :studentId,
       :subjectId,
       :timePlayed,
       :sessionDate,
       :deviceUuid
     )`,
    {
      studentId,
      subjectId,
      timePlayed: Number(totalTimePlayed),
      sessionDate,
      deviceUuid,
    },
    { autoCommit: true }
  );
}

// @desc    Create or update progress
// @route   POST /api/progress
// @access  Public
async function createOrUpdateProgress(req, res, next) {
  try {
    const {
      studentId,
      grade,
      subject,
      highest_diff_passed,
      total_time_played,
      last_played_at,
      levelId,
      score = 0,
      completed = false,
      subjectId,
      diffId,
    } = req.body;

    if (!studentId) {
      return res.status(400).json({
        message: 'studentId is required.',
      });
    }

    const hasNamePayload =
      grade !== undefined ||
      subject !== undefined ||
      highest_diff_passed !== undefined ||
      total_time_played !== undefined ||
      last_played_at !== undefined;

    if (hasNamePayload) {
      if (!grade || !subject) {
        return res.status(400).json({
          message: 'grade and subject are required when using progress payload by names.',
        });
      }

      const mapping = await db.execute(
        `SELECT g.gradelvl_id,
                s.subject_id
         FROM gradelvlTb g
         CROSS JOIN subjectTb s
         WHERE UPPER(g.gradelvl) = UPPER(:grade)
           AND UPPER(s.subject) = UPPER(:subject)`,
        {
          grade: String(grade),
          subject: String(subject),
        }
      );

      if (!mapping.rows.length) {
        return res.status(404).json({
          message: 'grade or subject not found.',
        });
      }

      const mapRow = mapping.rows[0];
      const mappedGradeLevelId = Number(mapRow.GRADELVL_ID ?? mapRow.gradelvl_id);
      const mappedSubjectId = Number(mapRow.SUBJECT_ID ?? mapRow.subject_id);
      const numericStudentId = Number(studentId);
      const highestDiffPassed = Math.max(
        0,
        Number(highest_diff_passed ?? diffId ?? 0) || 0
      );
      const totalTimePlayed = Math.max(
        0,
        Number(total_time_played ?? 0) || 0
      );
      const playedAt = normalizeTimestamp(last_played_at, new Date());

      if (db.isOracle()) {
        await db.execute(
          `MERGE INTO progressTb p
           USING (
             SELECT :studentId AS stud_id,
                    :subjectId AS subject_id,
                    :gradeLevelId AS gradelvl_id,
                    :highestDiffPassed AS highest_diff_passed,
                    :totalTimePlayed AS total_time_played,
                    :playedAt AS played_at
             FROM DUAL
           ) src
           ON (
             p.stud_id = src.stud_id
             AND p.subject_id = src.subject_id
             AND p.gradelvl_id = src.gradelvl_id
           )
           WHEN MATCHED THEN
             UPDATE SET
               p.highest_diff_passed = GREATEST(NVL(p.highest_diff_passed, 0), src.highest_diff_passed),
               p.total_time_played = NVL(p.total_time_played, 0) + NVL(src.total_time_played, 0),
               p.last_played_at = TO_DATE(src.played_at, 'YYYY-MM-DD HH24:MI:SS')
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
               src.stud_id,
               src.subject_id,
               src.gradelvl_id,
               src.highest_diff_passed,
               src.total_time_played,
               TO_DATE(src.played_at, 'YYYY-MM-DD HH24:MI:SS')
             )`,
          {
            studentId: numericStudentId,
            subjectId: mappedSubjectId,
            gradeLevelId: mappedGradeLevelId,
            highestDiffPassed,
            totalTimePlayed,
            playedAt,
          },
          { autoCommit: true }
        );
      } else {
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
             :highestDiffPassed,
             :totalTimePlayed,
             :playedAt
           )
           ON CONFLICT (stud_id, subject_id, gradelvl_id)
           DO UPDATE SET
             highest_diff_passed = CASE
               WHEN excluded.highest_diff_passed > COALESCE(progressTb.highest_diff_passed, 0)
                 THEN excluded.highest_diff_passed
               ELSE progressTb.highest_diff_passed
             END,
             total_time_played = COALESCE(progressTb.total_time_played, 0) + COALESCE(excluded.total_time_played, 0),
             last_played_at = excluded.last_played_at`,
          {
            studentId: numericStudentId,
            subjectId: mappedSubjectId,
            gradeLevelId: mappedGradeLevelId,
            highestDiffPassed,
            totalTimePlayed,
            playedAt,
          },
          { autoCommit: true }
        );
      }

      await insertTimePlayed({
        studentId: numericStudentId,
        subjectId: mappedSubjectId,
        totalTimePlayed,
        sessionDate: playedAt,
      });

      broadcastToAdmins({
        type: 'progress_updated',
        student_id: numericStudentId,
        grade: String(grade),
        subject: String(subject),
        highest_diff_passed: highestDiffPassed,
        total_time_played: totalTimePlayed,
        last_played_at: playedAt,
      });

      return res.status(200).json({
        message: 'Progress saved.',
        data: {
          studentId: numericStudentId,
          grade,
          subject,
          highest_diff_passed: highestDiffPassed,
          total_time_played: totalTimePlayed,
          last_played_at: playedAt,
        },
      });
    }

    if (!levelId) {
      return res.status(400).json({
        message: 'levelId is required for legacy progress payload.',
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
    const completedExpr = db.isOracle()
      ? 'CASE WHEN NVL(p.highest_diff_passed, 0) > 0 THEN 1 ELSE 0 END'
      : 'CASE WHEN COALESCE(p.highest_diff_passed, 0) > 0 THEN 1 ELSE 0 END';

    const lastPlayedAtColumn = db.isOracle()
      ? `TO_CHAR(p.last_played_at, 'YYYY-MM-DD HH24:MI:SS')`
      : `strftime('%Y-%m-%d %H:%M:%S', p.last_played_at)`;
    const rows = await db.execute(
      `SELECT p.stud_id,
              p.subject_id,
              p.gradelvl_id,
              p.highest_diff_passed,
              p.total_time_played,
              ${lastPlayedAtColumn} AS last_played_at,
              s.subject,
              g.gradelvl,
              ${completedExpr} AS completed
       FROM progressTb p
       JOIN subjectTb s ON p.subject_id = s.subject_id
       JOIN gradelvlTb g ON p.gradelvl_id = g.gradelvl_id
       WHERE p.stud_id = :studentId
       ORDER BY p.last_played_at DESC`,
      { studentId: Number(req.params.studentId) }
    );
    const data = rows.rows.map((row) => ({
      stud_id: Number(row.STUD_ID ?? row.stud_id ?? 0),
      subject_id: Number(row.SUBJECT_ID ?? row.subject_id ?? 0),
      gradelvl_id: Number(row.GRADELVL_ID ?? row.gradelvl_id ?? 0),
      highest_diff_passed: Number(row.HIGHEST_DIFF_PASSED ?? row.highest_diff_passed ?? 0),
      total_time_played: Number(row.TOTAL_TIME_PLAYED ?? row.total_time_played ?? 0),
      last_played_at: normalizeTimestamp(row.LAST_PLAYED_AT ?? row.last_played_at),
      subject: row.SUBJECT ?? row.subject ?? '',
      gradelvl: row.GRADELVL ?? row.gradelvl ?? '',
      completed: Number(row.COMPLETED ?? row.completed ?? 0),
    }));
    return res.status(200).json({ count: data.length, data });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createOrUpdateProgress,
  getProgress,
};
