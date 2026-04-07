const asyncHandler = require('express-async-handler');
const db = require('../config/db');
const UserModel = require('../models/userModel');
const { broadcastToAdmins } = require('../services/wsHub');

function isTmpId(value) {
  return typeof value === 'string' && value.toUpperCase().startsWith('TMP-');
}

async function writeSyncLog({ deviceUuid, studId, eventType, payload, status }) {
  const payloadText = JSON.stringify(payload || {});

  if (db.isOracle()) {
    await db.execute(
      `INSERT INTO syncLogTb (
         device_uuid,
         stud_id,
         event_type,
         payload,
         received_at,
         status
       )
       VALUES (
         :deviceUuid,
         :studId,
         :eventType,
         :payload,
         SYSDATE,
         :status
       )`,
      {
        deviceUuid,
        studId: studId || null,
        eventType,
        payload: payloadText,
        status,
      },
      { autoCommit: true }
    );
    return;
  }

  await db.execute(
    `INSERT INTO syncLogTb (
       device_uuid,
       stud_id,
       event_type,
       payload,
       received_at,
       status
     )
     VALUES (
       :deviceUuid,
       :studId,
       :eventType,
       :payload,
       CURRENT_TIMESTAMP,
       :status
     )`,
    {
      deviceUuid,
      studId: studId || null,
      eventType,
      payload: payloadText,
      status,
    },
    { autoCommit: true }
  );
}

async function resolveStudentId(rawStudentId, registrationMap) {
  if (rawStudentId === null || rawStudentId === undefined) {
    return null;
  }

  if (typeof rawStudentId === 'number') {
    return rawStudentId;
  }

  const asNumber = Number(rawStudentId);
  if (!Number.isNaN(asNumber) && Number.isFinite(asNumber)) {
    return asNumber;
  }

  if (isTmpId(rawStudentId) && registrationMap.has(rawStudentId)) {
    return registrationMap.get(rawStudentId);
  }

  return null;
}

async function resolveSubjectGradeDiff({ subject, grade, difficulty, subjectId, gradeLevelId, diffId }) {
  if (subjectId && gradeLevelId && diffId) {
    return {
      subjectId: Number(subjectId),
      gradeLevelId: Number(gradeLevelId),
      diffId: Number(diffId),
    };
  }

  const result = await db.execute(
    `SELECT s.subject_id,
            g.gradelvl_id,
            d.diff_id
     FROM subjectTb s
     CROSS JOIN gradelvlTb g
     CROSS JOIN diffTb d
     WHERE UPPER(s.subject) = UPPER(:subject)
       AND UPPER(g.gradelvl) = UPPER(:grade)
       AND UPPER(d.difficulty) = UPPER(:difficulty)`,
    {
      subject,
      grade,
      difficulty,
    }
  );

  if (result.rows.length === 0) {
    return null;
  }

  const row = result.rows[0];
  return {
    subjectId: Number(row.SUBJECT_ID),
    gradeLevelId: Number(row.GRADELVL_ID),
    diffId: Number(row.DIFF_ID),
  };
}

async function upsertProgress({ studentId, subjectId, gradeLevelId, highestDiffPassed, totalTimePlayed, lastPlayedAt }) {
  if (db.isOracle()) {
    await db.execute(
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
           p.total_time_played = NVL(p.total_time_played, 0) + NVL(:totalTimePlayed, 0),
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
           NVL(:totalTimePlayed, 0),
           CASE
             WHEN :lastPlayedAt IS NULL THEN SYSDATE
             ELSE TO_DATE(SUBSTR(REPLACE(:lastPlayedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
           END
         )`,
      {
        studId: studentId,
        subjectId,
        gradeLevelId,
        highestDiffPassed: highestDiffPassed || null,
        totalTimePlayed: totalTimePlayed || 0,
        lastPlayedAt: lastPlayedAt || null,
      },
      { autoCommit: true }
    );
    return;
  }

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
       :studId,
       :subjectId,
       :gradeLevelId,
       COALESCE(:highestDiffPassed, 0),
       COALESCE(:totalTimePlayed, 0),
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
    {
      studId: studentId,
      subjectId,
      gradeLevelId,
      highestDiffPassed: highestDiffPassed || null,
      totalTimePlayed: totalTimePlayed || 0,
      lastPlayedAt: lastPlayedAt || null,
    },
    { autoCommit: true }
  );
}

async function insertScore({ studentId, subjectId, gradeLevelId, diffId, score, total, playedAt, deviceUuid }) {
  const maxScore = Number(total) > 0 ? Number(total) : 10;
  const scoreValue = Number(score);
  const passed = scoreValue / maxScore >= 0.7 ? 1 : 0;

  if (db.isOracle()) {
    const duplicate = await db.execute(
      `SELECT COUNT(*) AS CNT
       FROM scoreTb
       WHERE stud_id = :studentId
         AND subject_id = :subjectId
         AND gradelvl_id = :gradeLevelId
         AND diff_id = :diffId
         AND played_at = TO_DATE(SUBSTR(REPLACE(:playedAt, 'T', ' '), 1, 19), 'YYYY-MM-DD HH24:MI:SS')
         AND (:deviceUuid IS NULL OR NVL(device_uuid, '__NONE__') = NVL(:deviceUuid, '__NONE__'))`,
      {
        studentId,
        subjectId,
        gradeLevelId,
        diffId,
        playedAt,
        deviceUuid: deviceUuid || null,
      }
    );

    if (Number(duplicate.rows?.[0]?.CNT || 0) > 0) {
      return { duplicate: true, passed };
    }

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
        subjectId,
        gradeLevelId,
        diffId,
        score: scoreValue,
        maxScore,
        passed,
        playedAt: playedAt || null,
        deviceUuid: deviceUuid || null,
      },
      { autoCommit: true }
    );

    return { duplicate: false, passed };
  }

  const playedAtValue = playedAt || new Date().toISOString();
  const duplicate = await db.execute(
    `SELECT COUNT(*) AS CNT
     FROM scoreTb
     WHERE stud_id = :studentId
       AND subject_id = :subjectId
       AND gradelvl_id = :gradeLevelId
       AND diff_id = :diffId
       AND played_at = :playedAt
       AND (:deviceUuid IS NULL OR COALESCE(device_uuid, '__NONE__') = COALESCE(:deviceUuid, '__NONE__'))`,
    {
      studentId,
      subjectId,
      gradeLevelId,
      diffId,
      playedAt: playedAtValue,
      deviceUuid: deviceUuid || null,
    }
  );

  if (Number(duplicate.rows?.[0]?.CNT || 0) > 0) {
    return { duplicate: true, passed };
  }

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
      subjectId,
      gradeLevelId,
      diffId,
      score: scoreValue,
      maxScore,
      passed,
      playedAt: playedAtValue,
      deviceUuid: deviceUuid || null,
    },
    { autoCommit: true }
  );

  return { duplicate: false, passed };
}

// @desc    Batch sync endpoint
// @route   POST /api/sync
// @access  Public
const syncBatch = asyncHandler(async (req, res) => {
  const body = req.body || {};

  const deviceUuid = body.deviceUuid || body.device_uuid || body.device_id || req.auth?.deviceUuid || null;

  let registrations = Array.isArray(body.registrations) ? body.registrations : [];
  let scores = Array.isArray(body.scores) ? body.scores : [];
  let progress = Array.isArray(body.progress) ? body.progress : [];

  if (Array.isArray(body.batches)) {
    const normalizedRegistrations = [];
    const normalizedScores = [];
    const normalizedProgress = [];

    for (const batch of body.batches) {
      const batchStudId = batch?.stud_id || batch?.studId || null;
      const events = Array.isArray(batch?.events) ? batch.events : [];

      for (const event of events) {
        const eventType = event?.event_type || event?.eventType;
        const payload = { ...(event?.payload || {}) };

        if (batchStudId && payload.studentId === undefined && payload.stud_id === undefined) {
          payload.studentId = batchStudId;
        }

        if (eventType === 'register') {
          normalizedRegistrations.push({
            firstName: payload.first_name || payload.firstName,
            lastName: payload.last_name || payload.lastName,
            nickname: payload.nickname,
            birthday: payload.birthday,
            sex: payload.sex || payload.sex_id,
            teacherId: payload.teacher_id || payload.teacherId,
            area: payload.area,
            tmpLocalId: payload.tmp_local_id || payload.tmpLocalId || batchStudId,
          });
          continue;
        }

        if (eventType === 'score') {
          normalizedScores.push({
            studentId: payload.studentId || payload.stud_id || batchStudId,
            subjectId: payload.subject_id || payload.subjectId,
            gradeLevelId: payload.gradelvl_id || payload.gradeLevelId,
            diffId: payload.diff_id || payload.diffId,
            score: payload.score,
            total: payload.max_score || payload.total,
            played_at: payload.played_at || payload.playedAt,
            subject: payload.subject,
            grade: payload.grade,
            difficulty: payload.difficulty,
          });
          continue;
        }

        if (eventType === 'progress' || eventType === 'timeplay') {
          normalizedProgress.push({
            studentId: payload.studentId || payload.stud_id || batchStudId,
            subjectId: payload.subject_id || payload.subjectId,
            gradeLevelId: payload.gradelvl_id || payload.gradeLevelId,
            highest_diff_passed: payload.highest_diff_passed || payload.highestDiffPassed || payload.diff_id,
            total_time_played: payload.total_time_played || payload.time_played || payload.timePlayed || 0,
            last_played_at: payload.last_played_at || payload.played_at || payload.session_date || payload.lastPlayedAt,
            subject: payload.subject,
            grade: payload.grade,
            difficulty: payload.difficulty || (eventType === 'timeplay' ? 'Easy' : undefined),
          });
        }
      }
    }

    registrations = normalizedRegistrations;
    scores = normalizedScores;
    progress = normalizedProgress;
  }

  if (!deviceUuid) {
    return res.status(400).json({ success: false, error: 'deviceUuid is required' });
  }

  const registrationMap = new Map();
  const createdStudents = [];
  const acceptedScores = [];
  const acceptedProgress = [];
  const failures = [];

  for (const entry of registrations) {
    try {
      const {
        firstName,
        lastName,
        nickname,
        birthday,
        sex,
        area,
        teacherId,
        tmpLocalId,
      } = entry;

      if (!firstName || !lastName || !nickname || !birthday) {
        throw new Error('registration missing required fields');
      }

      let studentId;
      try {
        studentId = await UserModel.createUser({
          firstName,
          lastName,
          nickname,
          birthday,
          sex: sex || null,
          area: area || null,
          teacherId: teacherId || null,
          deviceUuid,
          tmpLocalId: tmpLocalId || null,
        });
      } catch (error) {
        const existing = await UserModel.findUserByNicknameAndBirthday(nickname, birthday);
        if (!existing?.STUDENT_ID) {
          throw error;
        }
        studentId = Number(existing.STUDENT_ID);
      }

      if (tmpLocalId && isTmpId(tmpLocalId)) {
        registrationMap.set(tmpLocalId, studentId);
      }

      createdStudents.push({
        tmpLocalId: tmpLocalId || null,
        studentId,
      });

      await writeSyncLog({
        deviceUuid,
        studId: studentId,
        eventType: 'register',
        payload: entry,
        status: 'processed',
      });
    } catch (error) {
      failures.push({ type: 'register', payload: entry, error: error.message });
      await writeSyncLog({
        deviceUuid,
        studId: null,
        eventType: 'register',
        payload: entry,
        status: 'failed',
      });
    }
  }

  for (const entry of scores) {
    try {
      const studentId = await resolveStudentId(entry.studentId || entry.stud_id, registrationMap);
      if (!studentId) {
        throw new Error('score has unresolved studentId');
      }

      const mapping = await resolveSubjectGradeDiff({
        subject: entry.subject,
        grade: entry.grade,
        difficulty: entry.difficulty,
        subjectId: entry.subjectId || entry.subject_id,
        gradeLevelId: entry.gradeLevelId || entry.gradelvl_id,
        diffId: entry.diffId || entry.diff_id,
      });

      if (!mapping) {
        throw new Error('score has unresolved subject/grade/difficulty');
      }

      const result = await insertScore({
        studentId,
        subjectId: mapping.subjectId,
        gradeLevelId: mapping.gradeLevelId,
        diffId: mapping.diffId,
        score: entry.score,
        total: entry.total || entry.max_score,
        playedAt: entry.playedAt || entry.played_at,
        deviceUuid,
      });

      if (!result.duplicate) {
        await upsertProgress({
          studentId,
          subjectId: mapping.subjectId,
          gradeLevelId: mapping.gradeLevelId,
          highestDiffPassed: result.passed ? mapping.diffId : null,
          totalTimePlayed: 0,
          lastPlayedAt: entry.playedAt || entry.played_at || null,
        });
      }

      acceptedScores.push({
        studentId,
        duplicate: result.duplicate,
      });

      await writeSyncLog({
        deviceUuid,
        studId: studentId,
        eventType: 'score',
        payload: entry,
        status: result.duplicate ? 'duplicate' : 'processed',
      });
    } catch (error) {
      failures.push({ type: 'score', payload: entry, error: error.message });
      await writeSyncLog({
        deviceUuid,
        studId: null,
        eventType: 'score',
        payload: entry,
        status: 'failed',
      });
    }
  }

  for (const entry of progress) {
    try {
      const studentId = await resolveStudentId(entry.studentId || entry.stud_id, registrationMap);
      if (!studentId) {
        throw new Error('progress has unresolved studentId');
      }

      const mapping = await resolveSubjectGradeDiff({
        subject: entry.subject,
        grade: entry.grade,
        difficulty: entry.difficulty || 'Easy',
        subjectId: entry.subjectId || entry.subject_id,
        gradeLevelId: entry.gradeLevelId || entry.gradelvl_id,
        diffId: entry.highestDiffPassed || entry.highest_diff_passed || entry.diffId || entry.diff_id || 1,
      });

      if (!mapping) {
        throw new Error('progress has unresolved subject/grade');
      }

      await upsertProgress({
        studentId,
        subjectId: mapping.subjectId,
        gradeLevelId: mapping.gradeLevelId,
        highestDiffPassed: entry.highestDiffPassed || entry.highest_diff_passed || null,
        totalTimePlayed: entry.totalTimePlayed || entry.total_time_played || entry.timeSpent || 0,
        lastPlayedAt: entry.lastPlayedAt || entry.last_played_at || null,
      });

      acceptedProgress.push({ studentId });

      await writeSyncLog({
        deviceUuid,
        studId: studentId,
        eventType: 'progress',
        payload: entry,
        status: 'processed',
      });
    } catch (error) {
      failures.push({ type: 'progress', payload: entry, error: error.message });
      await writeSyncLog({
        deviceUuid,
        studId: null,
        eventType: 'progress',
        payload: entry,
        status: 'failed',
      });
    }
  }

  if (db.isOracle()) {
    await db.execute(
      `UPDATE deviceTb
       SET last_synced_at = SYSDATE
       WHERE device_uuid = :deviceUuid`,
      { deviceUuid },
      { autoCommit: true }
    );
  } else {
    await db.execute(
      `UPDATE deviceTb
       SET last_synced_at = CURRENT_TIMESTAMP
       WHERE device_uuid = :deviceUuid`,
      { deviceUuid },
      { autoCommit: true }
    );
  }

  const studIds = [
    ...new Set([
      ...createdStudents.map((s) => s.studentId),
      ...acceptedScores.map((s) => s.studentId),
      ...acceptedProgress.map((s) => s.studentId),
    ].filter((value) => value !== null && value !== undefined)),
  ].map((value) => `STU-${value}`);

  broadcastToAdmins({
    type: 'sync_complete',
    device_id: deviceUuid,
    device_name: null,
    stud_ids: studIds,
    event_count: registrations.length + scores.length + progress.length,
    synced_at: new Date().toISOString(),
  });

  for (const mapping of createdStudents) {
    if (mapping.studentId) {
      broadcastToAdmins({
        type: 'student_registered',
        stud_id: `STU-${mapping.studentId}`,
        nickname: null,
        gradelvl: null,
        registered_via: 'offline',
      });
    }
  }

  return res.status(200).json({
    success: true,
    synced_at: Math.floor(Date.now() / 1000),
    id_mappings: createdStudents
      .filter((entry) => entry.tmpLocalId)
      .map((entry) => ({
        tmp_id: entry.tmpLocalId,
        real_id: `STU-${entry.studentId}`,
      })),
    errors: failures,
    summary: {
      registered: createdStudents.length,
      scores: acceptedScores.length,
      progress: acceptedProgress.length,
      failed: failures.length,
    },
    mappings: createdStudents,
    failures,
  });
});

module.exports = {
  syncBatch,
};
