const asyncHandler = require('express-async-handler');
const db = require('../config/db');
const UserModel = require('../models/userModel');
const { broadcastToAdmins } = require('../services/wsHub');
const { normalizeQuestionImage, serializeQuestionImage } = require('../utils/questionImage');
const { normalizeDateOnly, normalizeTimestamp } = require('../utils/dateTime');

async function getSingleValue(sql, binds = {}) {
  const result = await db.execute(sql, binds);
  const row = result.rows[0] || {};
  const firstKey = Object.keys(row)[0];
  return Number(row[firstKey] || 0);
}

function getRowValue(row, key) {
  return row?.[key] ?? row?.[key.toUpperCase()] ?? row?.[key.toLowerCase()] ?? null;
}

function toNumber(value, fallback = 0) {
  const numericValue = Number(value);
  return Number.isFinite(numericValue) ? numericValue : fallback;
}

function toText(value, fallback = '') {
  if (value === undefined || value === null) {
    return fallback;
  }

  const text = String(value).trim();
  return text || fallback;
}

function calculateAge(birthday) {
  const normalizedBirthday = normalizeDateOnly(birthday);
  if (!normalizedBirthday) {
    return 0;
  }

  const [year, month, day] = normalizedBirthday.split('-').map(Number);
  if (![year, month, day].every(Number.isFinite)) {
    return 0;
  }

  const today = new Date();
  let age = today.getFullYear() - year;
  const hasBirthdayPassed =
    today.getMonth() + 1 > month ||
    ((today.getMonth() + 1) === month && today.getDate() >= day);

  if (!hasBirthdayPassed) {
    age -= 1;
  }

  return Math.max(age, 0);
}

function gradeLevelFromAge(age) {
  if (age >= 6) {
    return 'Binhi';
  }

  if (age >= 3) {
    return 'Punla';
  }

  return '';
}

function proficiencyFromAverage(avgScore) {
  if (avgScore >= 9) {
    return 'Excelling';
  }

  if (avgScore >= 7) {
    return 'On track';
  }

  if (avgScore >= 5) {
    return 'Needs support';
  }

  return 'Needs significant support';
}

async function bumpContentVersion(note) {
  if (db.isOracle()) {
    await db.execute(
      `INSERT INTO contentVersionTb (version_tag, changed_by, changed_at, change_note)
       VALUES (
         'v' || TO_CHAR(seq_content_ver.NEXTVAL),
         NULL,
         SYSDATE,
         :note
       )`,
      { note: note || null },
      { autoCommit: true }
    );
    const latest = await db.execute(
      `SELECT version_tag, changed_at
       FROM contentVersionTb
       ORDER BY version_id DESC
       FETCH FIRST 1 ROWS ONLY`
    );

    const versionTag = latest.rows[0]?.VERSION_TAG || null;
    const changedAt = latest.rows[0]?.CHANGED_AT || null;

    broadcastToAdmins({
      type: 'content_updated',
      version_tag: versionTag,
      changed_by: 'admin',
      changed_at: changedAt,
      change_note: note || null,
    });

    return;
  }

  const next = await db.execute(
    `SELECT COALESCE(MAX(version_id), 0) + 1 AS NEXT_ID
     FROM contentVersionTb`
  );
  const nextId = Number(next.rows[0]?.NEXT_ID || 1);

  await db.execute(
    `INSERT INTO contentVersionTb (version_id, version_tag, updated_at, updated_by)
     VALUES (:versionId, :versionTag, CURRENT_TIMESTAMP, :updatedBy)`,
    {
      versionId: nextId,
      versionTag: `v${nextId}`,
      updatedBy: note || 'system',
    },
    { autoCommit: true }
  );

  broadcastToAdmins({
    type: 'content_updated',
    version_tag: `v${nextId}`,
    changed_by: 'admin',
    changed_at: new Date().toISOString(),
    change_note: note || null,
  });
}

// @desc    Admin dashboard summary
// @route   GET /api/admin/dashboard
// @access  Public
const getDashboard = asyncHandler(async (req, res) => {
  const totalStudents = await getSingleValue(`SELECT COUNT(*) AS CNT FROM studentTb`);
  const totalSessions = await getSingleValue(`SELECT COUNT(*) AS CNT FROM scoreTb`);
  const activeDevices = await getSingleValue(`SELECT COUNT(*) AS CNT FROM deviceTb`);

  const ageGroupProgressResult = await db.execute(
    `SELECT g.gradelvl,
            s.subject,
            COUNT(DISTINCT sc.stud_id) AS active_students,
            ROUND(AVG(sc.score), 2) AS avg_score,
            ROUND(AVG(CASE WHEN sc.passed = 1 THEN 1 ELSE 0 END) * 100, 1) AS pass_rate_pct
     FROM scoreTb sc
     JOIN gradelvlTb g ON sc.gradelvl_id = g.gradelvl_id
     JOIN subjectTb s ON sc.subject_id = s.subject_id
     GROUP BY g.gradelvl, s.subject
     ORDER BY g.gradelvl_id, s.subject_id`
  );

  const syncTimestampColumn = db.isOracle()
    ? `TO_CHAR(d.last_synced_at, 'YYYY-MM-DD HH24:MI:SS')`
    : `strftime('%Y-%m-%d %H:%M:%S', d.last_synced_at)`;
  const recentSyncsResult = await db.execute(
    `SELECT d.device_uuid,
            d.device_name,
            ${syncTimestampColumn} AS last_synced_at,
            COUNT(DISTINCT sl.stud_id) AS students_synced
     FROM deviceTb d
     LEFT JOIN syncLogTb sl ON d.device_uuid = sl.device_uuid
     GROUP BY d.device_uuid, d.device_name, d.last_synced_at`
  );

  const ageGroupProgress = ageGroupProgressResult.rows.map((row) => ({
    gradelvl: toText(getRowValue(row, 'gradelvl')),
    subject: toText(getRowValue(row, 'subject')),
    active_students: toNumber(getRowValue(row, 'active_students')),
    avg_score: toNumber(getRowValue(row, 'avg_score')),
    pass_rate_pct: toNumber(getRowValue(row, 'pass_rate_pct')),
  }));

  const recentSyncs = recentSyncsResult.rows
    .map((row) => ({
      device_uuid: toText(getRowValue(row, 'device_uuid')),
      device_name: toText(getRowValue(row, 'device_name'), 'Unknown Device'),
      last_synced_at: normalizeTimestamp(getRowValue(row, 'last_synced_at')),
      students_synced: toNumber(getRowValue(row, 'students_synced')),
    }))
    .sort((left, right) => right.last_synced_at.localeCompare(left.last_synced_at))
    .slice(0, 8);

  res.status(200).json({
    success: true,
    total_students: totalStudents,
    total_sessions: totalSessions,
    active_devices: activeDevices,
    age_group_progress: ageGroupProgress,
    recent_syncs: recentSyncs,
  });
});

// @desc    List students for admin table
// @route   GET /api/admin/students
// @access  Public
const listStudents = asyncHandler(async (req, res) => {
  const areaParts = await UserModel.getStudentAreaQueryParts('s');
  const result = await db.execute(
    `SELECT s.stud_id,
            s.first_name,
            s.last_name,
            s.nickname,
            ${db.isOracle() ? "TO_CHAR(s.birthday, 'YYYY-MM-DD')" : 'date(s.birthday)'} AS birthday,
            x.sex,
           ${areaParts.areaSelect} AS area,
            s.device_origin,
            s.tmp_local_id,
            s.created_at,
            s.updated_at
     FROM studentTb s
     LEFT JOIN sexTb x ON s.sex_id = x.sex_id
         ${areaParts.joins}
     ORDER BY s.stud_id DESC`
  );

  const scoreStats = await db.execute(
    `SELECT stud_id,
            COUNT(*) AS total_sessions,
            ROUND(AVG(score), 2) AS avg_score
     FROM scoreTb
     GROUP BY stud_id`
  );

  const statsByStudentId = new Map(
    scoreStats.rows.map((row) => [
      toNumber(getRowValue(row, 'stud_id')),
      {
        totalSessions: toNumber(getRowValue(row, 'total_sessions')),
        avgScore: toNumber(getRowValue(row, 'avg_score')),
      },
    ])
  );

  const students = result.rows.map((row) => {
    const studId = toNumber(getRowValue(row, 'stud_id'));
    const birthday = normalizeDateOnly(getRowValue(row, 'birthday'));
    const age = calculateAge(birthday);
    const stats = statsByStudentId.get(studId) || { totalSessions: 0, avgScore: 0 };

    return {
      stud_id: studId,
      nickname: toText(getRowValue(row, 'nickname')),
      first_name: toText(getRowValue(row, 'first_name')),
      last_name: toText(getRowValue(row, 'last_name')),
      age,
      gradelvl: gradeLevelFromAge(age),
      sex: toText(getRowValue(row, 'sex')),
      total_sessions: stats.totalSessions,
      avg_score: stats.avgScore,
      proficiency: proficiencyFromAverage(stats.avgScore),
      birthday,
      area: toText(getRowValue(row, 'area')),
      device_origin: toText(getRowValue(row, 'device_origin')),
      tmp_local_id: toText(getRowValue(row, 'tmp_local_id')),
      created_at: normalizeTimestamp(getRowValue(row, 'created_at')),
      updated_at: normalizeTimestamp(getRowValue(row, 'updated_at')),
    };
  });

  res.status(200).json({
    success: true,
    count: students.length,
    students,
  });
});

// @desc    Get student detail with progress and scores
// @route   GET /api/admin/students/:studId
// @access  Public
const getStudentDetail = asyncHandler(async (req, res) => {
  const { studId } = req.params;
  const areaParts = await UserModel.getStudentAreaQueryParts('s');

  const student = await db.execute(
    `SELECT s.stud_id,
            s.first_name,
            s.last_name,
            s.nickname,
            ${db.isOracle() ? "TO_CHAR(s.birthday, 'YYYY-MM-DD')" : 'date(s.birthday)'} AS birthday,
            x.sex,
           ${areaParts.areaSelect} AS area,
            s.device_origin,
            s.tmp_local_id,
            s.created_at,
            s.updated_at
     FROM studentTb s
     LEFT JOIN sexTb x ON s.sex_id = x.sex_id
         ${areaParts.joins}
     WHERE s.stud_id = :studId`,
    { studId }
  );

  if (student.rows.length === 0) {
    return res.status(404).json({ success: false, error: 'Student not found' });
  }

  const studentRow = student.rows[0];
  const scoreStats = await db.execute(
    `SELECT COUNT(*) AS total_sessions,
            ROUND(AVG(score), 2) AS avg_score
     FROM scoreTb
     WHERE stud_id = :studId`,
    { studId }
  );
  const scoreStatRow = scoreStats.rows[0] || {};
  const birthday = normalizeDateOnly(getRowValue(studentRow, 'birthday'));
  const age = calculateAge(birthday);
  const avgScore = toNumber(getRowValue(scoreStatRow, 'avg_score'));

  const progress = await db.execute(
    `SELECT p.progress_id,
            p.subject_id,
            s.subject,
            p.gradelvl_id,
            g.gradelvl,
            p.highest_diff_passed,
            p.total_time_played,
            p.last_played_at
     FROM progressTb p
     JOIN subjectTb s ON p.subject_id = s.subject_id
     JOIN gradelvlTb g ON p.gradelvl_id = g.gradelvl_id
     WHERE p.stud_id = :studId
     ORDER BY p.subject_id, p.gradelvl_id`,
    { studId }
  );

  const analytics = await db.execute(
    `SELECT sub.subject,
            gl.gradelvl,
            MIN(sc.score) AS lowest_score,
            ROUND(AVG(sc.score), 2) AS average_score,
            MAX(sc.score) AS highest_score,
            COUNT(*) AS total_attempts
     FROM scoreTb sc
     JOIN subjectTb sub ON sc.subject_id = sub.subject_id
     JOIN gradelvlTb gl ON sc.gradelvl_id = gl.gradelvl_id
     WHERE sc.stud_id = :studId
     GROUP BY sub.subject, gl.gradelvl
     ORDER BY gl.gradelvl, sub.subject`,
    { studId }
  );

  const scoreTimestampColumn = db.isOracle()
    ? `TO_CHAR(sc.played_at, 'YYYY-MM-DD HH24:MI:SS')`
    : `strftime('%Y-%m-%d %H:%M:%S', sc.played_at)`;
  const scores = await db.execute(
    `SELECT sub.subject,
            d.difficulty,
            sc.score,
            sc.max_score,
            sc.passed,
            ${scoreTimestampColumn} AS played_at
     FROM scoreTb sc
     JOIN subjectTb sub ON sc.subject_id = sub.subject_id
     JOIN diffTb d ON sc.diff_id = d.diff_id
     WHERE sc.stud_id = :studId
     ORDER BY sc.played_at DESC`,
    { studId }
  );

  const profile = {
    stud_id: toNumber(getRowValue(studentRow, 'stud_id')),
    nickname: toText(getRowValue(studentRow, 'nickname')),
    first_name: toText(getRowValue(studentRow, 'first_name')),
    last_name: toText(getRowValue(studentRow, 'last_name')),
    age,
    gradelvl: gradeLevelFromAge(age),
    sex: toText(getRowValue(studentRow, 'sex')),
    total_sessions: toNumber(getRowValue(scoreStatRow, 'total_sessions')),
    avg_score: avgScore,
    proficiency: proficiencyFromAverage(avgScore),
    birthday,
    area: toText(getRowValue(studentRow, 'area')),
    device_origin: toText(getRowValue(studentRow, 'device_origin')),
    tmp_local_id: toText(getRowValue(studentRow, 'tmp_local_id')),
    created_at: normalizeTimestamp(getRowValue(studentRow, 'created_at')),
    updated_at: normalizeTimestamp(getRowValue(studentRow, 'updated_at')),
  };

  res.status(200).json({
    success: true,
    profile,
    progress: progress.rows.map((row) => ({
      subject: toText(getRowValue(row, 'subject')),
      gradelvl: toText(getRowValue(row, 'gradelvl')),
      highest_diff_passed: toNumber(getRowValue(row, 'highest_diff_passed')),
      total_time_played: toNumber(getRowValue(row, 'total_time_played')),
      last_played_at: normalizeTimestamp(getRowValue(row, 'last_played_at')),
    })),
    analytics: analytics.rows.map((row) => ({
      subject: toText(getRowValue(row, 'subject')),
      gradelvl: toText(getRowValue(row, 'gradelvl')),
      lowest_score: toNumber(getRowValue(row, 'lowest_score')),
      average_score: toNumber(getRowValue(row, 'average_score')),
      highest_score: toNumber(getRowValue(row, 'highest_score')),
      total_attempts: toNumber(getRowValue(row, 'total_attempts')),
    })),
    recent_scores: scores.rows.map((row) => ({
      subject: toText(getRowValue(row, 'subject')),
      difficulty: toText(getRowValue(row, 'difficulty')),
      score: toNumber(getRowValue(row, 'score')),
      max_score: toNumber(getRowValue(row, 'max_score')),
      passed: toNumber(getRowValue(row, 'passed')),
      played_at: normalizeTimestamp(getRowValue(row, 'played_at')),
    })),
  });
});

// @desc    List known devices
// @route   GET /api/admin/devices
// @access  Public
const listDevices = asyncHandler(async (req, res) => {
  const registeredTimestampColumn = db.isOracle()
    ? `TO_CHAR(d.registered_at, 'YYYY-MM-DD HH24:MI:SS')`
    : `strftime('%Y-%m-%d %H:%M:%S', d.registered_at)`;
  const syncedTimestampColumn = db.isOracle()
    ? `TO_CHAR(d.last_synced_at, 'YYYY-MM-DD HH24:MI:SS')`
    : `strftime('%Y-%m-%d %H:%M:%S', d.last_synced_at)`;
  const result = await db.execute(
    `SELECT d.device_id,
            d.device_uuid,
            d.device_name,
            ${registeredTimestampColumn} AS registered_at,
            ${syncedTimestampColumn} AS last_synced_at,
            COUNT(DISTINCT sl.stud_id) AS students_on_device
     FROM deviceTb d
     LEFT JOIN syncLogTb sl ON d.device_uuid = sl.device_uuid
     GROUP BY d.device_id, d.device_uuid, d.device_name, d.registered_at, d.last_synced_at
     ORDER BY d.registered_at DESC`
  );

  const devices = result.rows.map((row) => ({
    device_id: toNumber(getRowValue(row, 'device_id')),
    device_uuid: toText(getRowValue(row, 'device_uuid')),
    device_name: toText(getRowValue(row, 'device_name'), 'Unknown Device'),
    registered_at: normalizeTimestamp(getRowValue(row, 'registered_at')),
    last_synced_at: normalizeTimestamp(getRowValue(row, 'last_synced_at')),
    students_on_device: toNumber(getRowValue(row, 'students_on_device')),
  }));

  res.status(200).json({
    success: true,
    count: devices.length,
    devices,
  });
});

// @desc    List questions with optional filters
// @route   GET /api/admin/questions
// @access  Private
const listQuestions = asyncHandler(async (req, res) => {
  const { subject_id, gradelvl_id, diff_id, is_active } = req.query;

  const filters = [];
  const binds = {};

  if (subject_id !== undefined) {
    filters.push('q.subject_id = :subjectId');
    binds.subjectId = Number(subject_id);
  }
  if (gradelvl_id !== undefined) {
    filters.push('q.gradelvl_id = :gradeLevelId');
    binds.gradeLevelId = Number(gradelvl_id);
  }
  if (diff_id !== undefined) {
    filters.push('q.diff_id = :diffId');
    binds.diffId = Number(diff_id);
  }
  if (is_active !== undefined) {
    filters.push('COALESCE(q.is_active, 1) = :isActive');
    binds.isActive = Number(String(is_active) === '1' || String(is_active).toLowerCase() === 'true' ? 1 : 0);
  }

  const whereClause = filters.length > 0 ? `WHERE ${filters.join(' AND ')}` : '';

  const result = await db.execute(
    `SELECT q.question_id,
            q.subject_id,
            q.gradelvl_id,
            q.diff_id,
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
            q.created_at,
            q.updated_at
     FROM questionTb q
     ${whereClause}
     ORDER BY q.subject_id, q.gradelvl_id, q.diff_id, q.question_id`,
    binds
  );

  const questions = result.rows.map((row) => {
    const normalizedRow = Object.entries(row).reduce((accumulator, [key, value]) => {
      accumulator[key.toUpperCase()] = value;
      return accumulator;
    }, {});
    const imageBlob = serializeQuestionImage(normalizedRow.QUESTION_IMAGE);
    const choiceImageBlobs = [
      serializeQuestionImage(normalizedRow.OPTION_A_IMAGE),
      serializeQuestionImage(normalizedRow.OPTION_B_IMAGE),
      serializeQuestionImage(normalizedRow.OPTION_C_IMAGE),
      serializeQuestionImage(normalizedRow.OPTION_D_IMAGE),
    ];
    return {
      question_id: normalizedRow.QUESTION_ID,
      subject_id: normalizedRow.SUBJECT_ID,
      gradelvl_id: normalizedRow.GRADELVL_ID,
      diff_id: normalizedRow.DIFF_ID,
      question_txt: normalizedRow.QUESTION_TXT,
      imageBlob,
      imagePath: imageBlob,
      option_a: normalizedRow.OPTION_A,
      option_b: normalizedRow.OPTION_B,
      option_c: normalizedRow.OPTION_C,
      option_d: normalizedRow.OPTION_D,
      option_a_image: choiceImageBlobs[0],
      option_b_image: choiceImageBlobs[1],
      option_c_image: choiceImageBlobs[2],
      option_d_image: choiceImageBlobs[3],
      choiceImageBlobs,
      choiceImages: choiceImageBlobs,
      correct_opt: normalizedRow.CORRECT_OPT,
      is_active: normalizedRow.IS_ACTIVE,
      created_at: normalizedRow.CREATED_AT,
      updated_at: normalizedRow.UPDATED_AT,
    };
  });

  res.status(200).json({
    success: true,
    count: questions.length,
    questions,
  });
});

// @desc    Create new question
// @route   POST /api/admin/questions
// @access  Public
const createQuestion = asyncHandler(async (req, res) => {
  const {
    subject,
    grade,
    difficulty,
    subject_id,
    gradelvl_id,
    diff_id,
    prompt,
    question_txt,
    optionA,
    optionB,
    optionC,
    optionD,
    option_a,
    option_b,
    option_c,
    option_d,
    optionAImage,
    optionBImage,
    optionCImage,
    optionDImage,
    option_a_image,
    option_b_image,
    option_c_image,
    option_d_image,
    image_path,
    imageBlob,
    image_blob,
    imageBase64,
    image_base64,
    imagePath,
    question_image,
    correctOpt,
    correct_opt,
  } = req.body;

  const questionText = prompt || question_txt;
  const resolvedImageBlob = normalizeQuestionImage(
    imageBlob || image_blob || imageBase64 || image_base64 || imagePath || image_path || question_image
  );
  const resolvedOptionA = optionA || option_a;
  const resolvedOptionB = optionB || option_b;
  const resolvedOptionC = optionC || option_c;
  const resolvedOptionD = optionD || option_d;
  const resolvedOptionAImage = normalizeQuestionImage(optionAImage || option_a_image);
  const resolvedOptionBImage = normalizeQuestionImage(optionBImage || option_b_image);
  const resolvedOptionCImage = normalizeQuestionImage(optionCImage || option_c_image);
  const resolvedOptionDImage = normalizeQuestionImage(optionDImage || option_d_image);
  const resolvedCorrectOpt = correctOpt || correct_opt;

  if ((!subject && !subject_id) || (!grade && !gradelvl_id) || (!difficulty && !diff_id)
    || !questionText
    || (!resolvedOptionA && !resolvedOptionAImage)
    || (!resolvedOptionB && !resolvedOptionBImage)
    || (!resolvedOptionC && !resolvedOptionCImage)
    || (!resolvedOptionD && !resolvedOptionDImage)
    || !resolvedCorrectOpt) {
    return res.status(400).json({ success: false, error: 'Missing required fields for question creation' });
  }

  let ids;
  if (subject_id && gradelvl_id && diff_id) {
    ids = {
      SUBJECT_ID: Number(subject_id),
      GRADELVL_ID: Number(gradelvl_id),
      DIFF_ID: Number(diff_id),
    };
  } else {
    const mapping = await db.execute(
      `SELECT s.subject_id,
              g.gradelvl_id,
              d.diff_id
       FROM subjectTb s
       CROSS JOIN gradelvlTb g
       CROSS JOIN diffTb d
       WHERE UPPER(s.subject) = UPPER(:subject)
         AND UPPER(g.gradelvl) = UPPER(:grade)
         AND UPPER(d.difficulty) = UPPER(:difficulty)`,
      { subject, grade, difficulty }
    );

    if (mapping.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Subject/grade/difficulty mapping not found' });
    }

    ids = mapping.rows[0];
  }

  if (db.isOracle()) {
    // Check for duplicate question
    const duplicateCheck = await db.execute(
      `SELECT question_id FROM questionTb 
       WHERE subject_id = :subjectId 
       AND gradelvl_id = :gradeLevelId 
       AND diff_id = :diffId 
       AND question_txt = :prompt
       AND option_a = :optionA
       AND option_b = :optionB
       AND option_c = :optionC
       AND option_d = :optionD
       AND correct_opt = :correctOpt`,
      {
        subjectId: ids.SUBJECT_ID,
        gradeLevelId: ids.GRADELVL_ID,
        diffId: ids.DIFF_ID,
        prompt: questionText,
        optionA: resolvedOptionA,
        optionB: resolvedOptionB,
        optionC: resolvedOptionC,
        optionD: resolvedOptionD,
        correctOpt: String(resolvedCorrectOpt).toUpperCase(),
      }
    );

    if (duplicateCheck.rows && duplicateCheck.rows.length > 0) {
      return res.status(409).json({ success: false, error: 'Question already exists' });
    }

    await db.execute(
      `INSERT INTO questionTb (
         subject_id,
         gradelvl_id,
         diff_id,
         question_txt,
         question_image,
         option_a,
         option_b,
         option_c,
         option_d,
         option_a_image,
         option_b_image,
         option_c_image,
         option_d_image,
         correct_opt,
         is_active,
         created_at,
         updated_at
       )
       VALUES (
         :subjectId,
         :gradeLevelId,
         :diffId,
         :prompt,
         :questionImage,
         :optionA,
         :optionB,
         :optionC,
         :optionD,
         :optionAImage,
         :optionBImage,
         :optionCImage,
         :optionDImage,
         :correctOpt,
         1,
         SYSDATE,
         SYSDATE
       )`,
      {
        subjectId: ids.SUBJECT_ID,
        gradeLevelId: ids.GRADELVL_ID,
        diffId: ids.DIFF_ID,
        prompt: questionText,
        questionImage: resolvedImageBlob,
        optionA: resolvedOptionA || ' ',
        optionB: resolvedOptionB || ' ',
        optionC: resolvedOptionC || ' ',
        optionD: resolvedOptionD || ' ',
        optionAImage: resolvedOptionAImage,
        optionBImage: resolvedOptionBImage,
        optionCImage: resolvedOptionCImage,
        optionDImage: resolvedOptionDImage,
        correctOpt: String(resolvedCorrectOpt).toUpperCase(),
      },
      { autoCommit: true }
    );
  } else {
    // Check for duplicate question in SQLite
    const duplicateCheck = await db.execute(
      `SELECT question_id FROM questionTb 
       WHERE subject_id = ? 
       AND gradelvl_id = ? 
       AND diff_id = ? 
       AND question_txt = ?
       AND option_a = ?
       AND option_b = ?
       AND option_c = ?
       AND option_d = ?
       AND correct_opt = ?`,
      [
        ids.SUBJECT_ID,
        ids.GRADELVL_ID,
        ids.DIFF_ID,
        questionText,
        resolvedOptionA,
        resolvedOptionB,
        resolvedOptionC,
        resolvedOptionD,
        String(resolvedCorrectOpt).toUpperCase(),
      ]
    );

    if (duplicateCheck.rows && duplicateCheck.rows.length > 0) {
      return res.status(409).json({ success: false, error: 'Question already exists' });
    }

    await db.execute(
      `INSERT INTO questionTb (
         subject_id,
         gradelvl_id,
         diff_id,
         question_txt,
         question_image,
         option_a,
         option_b,
         option_c,
         option_d,
         option_a_image,
         option_b_image,
         option_c_image,
         option_d_image,
         correct_opt,
         is_active,
         created_at,
         updated_at
       )
       VALUES (
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         ?,
         1,
         CURRENT_TIMESTAMP,
         CURRENT_TIMESTAMP
       )`,
      [
        ids.SUBJECT_ID,
        ids.GRADELVL_ID,
        ids.DIFF_ID,
        questionText,
        resolvedImageBlob,
        resolvedOptionA || '',
        resolvedOptionB || '',
        resolvedOptionC || '',
        resolvedOptionD || '',
        resolvedOptionAImage,
        resolvedOptionBImage,
        resolvedOptionCImage,
        resolvedOptionDImage,
        String(resolvedCorrectOpt).toUpperCase(),
      ],
      { autoCommit: true }
    );
  }

  await bumpContentVersion('question_created');

  res.status(201).json({ success: true, message: 'Question created successfully' });
});

// @desc    Update question
// @route   PUT /api/admin/questions/:questionId
// @access  Public
const updateQuestion = asyncHandler(async (req, res) => {
  const { questionId } = req.params;
  const {
    prompt,
    question_txt,
    imagePath,
    image_path,
    imageBlob,
    image_blob,
    imageBase64,
    image_base64,
    question_image,
    optionA,
    optionB,
    optionC,
    optionD,
    option_a,
    option_b,
    option_c,
    option_d,
    optionAImage,
    optionBImage,
    optionCImage,
    optionDImage,
    option_a_image,
    option_b_image,
    option_c_image,
    option_d_image,
    correctOpt,
    correct_opt,
    isActive,
    is_active,
  } = req.body;

  const resolvedImageBlob = normalizeQuestionImage(
    imageBlob || image_blob || imageBase64 || image_base64 || imagePath || image_path || question_image
  );

  if (db.isOracle()) {
    await db.execute(
      `UPDATE questionTb
       SET question_txt = COALESCE(:prompt, question_txt),
           question_image = COALESCE(:questionImage, question_image),
           option_a = COALESCE(:optionA, option_a),
           option_b = COALESCE(:optionB, option_b),
           option_c = COALESCE(:optionC, option_c),
           option_d = COALESCE(:optionD, option_d),
           option_a_image = COALESCE(:optionAImage, option_a_image),
           option_b_image = COALESCE(:optionBImage, option_b_image),
           option_c_image = COALESCE(:optionCImage, option_c_image),
           option_d_image = COALESCE(:optionDImage, option_d_image),
           correct_opt = COALESCE(:correctOpt, correct_opt),
           is_active = COALESCE(:isActive, is_active),
           updated_at = SYSDATE
       WHERE question_id = :questionId`,
      {
        questionId,
        prompt: prompt || question_txt || null,
        questionImage: resolvedImageBlob,
        optionA: optionA || option_a || null,
        optionB: optionB || option_b || null,
        optionC: optionC || option_c || null,
        optionD: optionD || option_d || null,
        optionAImage: normalizeQuestionImage(optionAImage || option_a_image),
        optionBImage: normalizeQuestionImage(optionBImage || option_b_image),
        optionCImage: normalizeQuestionImage(optionCImage || option_c_image),
        optionDImage: normalizeQuestionImage(optionDImage || option_d_image),
        correctOpt: (correctOpt || correct_opt) ? String(correctOpt || correct_opt).toUpperCase() : null,
        isActive: (isActive === undefined && is_active === undefined)
          ? null
          : Number(((isActive ?? is_active) ? 1 : 0)),
      },
      { autoCommit: true }
    );
  } else {
    await db.execute(
      `UPDATE questionTb
       SET question_txt = COALESCE(:prompt, question_txt),
           question_image = COALESCE(:questionImage, question_image),
           option_a = COALESCE(:optionA, option_a),
           option_b = COALESCE(:optionB, option_b),
           option_c = COALESCE(:optionC, option_c),
           option_d = COALESCE(:optionD, option_d),
           option_a_image = COALESCE(:optionAImage, option_a_image),
           option_b_image = COALESCE(:optionBImage, option_b_image),
           option_c_image = COALESCE(:optionCImage, option_c_image),
           option_d_image = COALESCE(:optionDImage, option_d_image),
           correct_opt = COALESCE(:correctOpt, correct_opt),
           is_active = COALESCE(:isActive, is_active),
           updated_at = CURRENT_TIMESTAMP
       WHERE question_id = :questionId`,
      {
        questionId,
        prompt: prompt || question_txt || null,
        questionImage: resolvedImageBlob,
        optionA: optionA || option_a || null,
        optionB: optionB || option_b || null,
        optionC: optionC || option_c || null,
        optionD: optionD || option_d || null,
        optionAImage: normalizeQuestionImage(optionAImage || option_a_image),
        optionBImage: normalizeQuestionImage(optionBImage || option_b_image),
        optionCImage: normalizeQuestionImage(optionCImage || option_c_image),
        optionDImage: normalizeQuestionImage(optionDImage || option_d_image),
        correctOpt: (correctOpt || correct_opt) ? String(correctOpt || correct_opt).toUpperCase() : null,
        isActive: (isActive === undefined && is_active === undefined)
          ? null
          : Number(((isActive ?? is_active) ? 1 : 0)),
      },
      { autoCommit: true }
    );
  }

  await bumpContentVersion('question_updated');

  res.status(200).json({ success: true, message: 'Question updated successfully' });
});

// @desc    Delete question
// @route   DELETE /api/admin/questions/:questionId
// @access  Public
const deleteQuestion = asyncHandler(async (req, res) => {
  const { questionId } = req.params;

  const result = await db.execute(
    `UPDATE questionTb
     SET is_active = 0,
         updated_at = ${db.isOracle() ? 'SYSDATE' : 'CURRENT_TIMESTAMP'}
     WHERE question_id = :questionId`,
    { questionId },
    { autoCommit: true }
  );

  if (Number(result.rowsAffected || 0) === 0) {
    return res.status(404).json({ success: false, error: 'Question not found' });
  }

  await bumpContentVersion('question_deleted');

  res.status(200).json({ success: true, message: 'Question deleted successfully' });
});

module.exports = {
  getDashboard,
  listStudents,
  getStudentDetail,
  listDevices,
  listQuestions,
  createQuestion,
  updateQuestion,
  deleteQuestion,
};
