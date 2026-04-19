const asyncHandler = require('express-async-handler');
const db = require('../config/db');
const UserModel = require('../models/userModel');
const { broadcastToAdmins } = require('../services/wsHub');
const { normalizeQuestionImage, serializeQuestionImage } = require('../utils/questionImage');

async function getSingleValue(sql, binds = {}) {
  const result = await db.execute(sql, binds);
  const row = result.rows[0] || {};
  const firstKey = Object.keys(row)[0];
  return Number(row[firstKey] || 0);
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
  const students = await getSingleValue(`SELECT COUNT(*) AS CNT FROM studentTb`);
  const scores = await getSingleValue(`SELECT COUNT(*) AS CNT FROM scoreTb`);
  const devices = await getSingleValue(`SELECT COUNT(*) AS CNT FROM deviceTb`);
  const avgScore = await getSingleValue(`SELECT COALESCE(AVG(score), 0) AS AVG_SCORE FROM scoreTb`);

  res.status(200).json({
    success: true,
    stats: {
      students,
      scores,
      devices,
      avgScore,
    },
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

  res.status(200).json({
    success: true,
    count: result.rows.length,
    students: result.rows,
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

  const scores = await db.execute(
    `SELECT score_id,
            subject_id,
            gradelvl_id,
            diff_id,
            score,
            max_score,
            passed,
            played_at,
            synced_at,
            device_uuid
     FROM scoreTb
     WHERE stud_id = :studId
     ORDER BY played_at DESC`,
    { studId }
  );

  res.status(200).json({
    success: true,
    student: student.rows[0],
    progress: progress.rows,
    scores: scores.rows,
  });
});

// @desc    List known devices
// @route   GET /api/admin/devices
// @access  Public
const listDevices = asyncHandler(async (req, res) => {
  const result = await db.execute(
    `SELECT d.device_id,
            d.device_uuid,
            d.device_name,
            d.registered_at,
            d.last_synced_at,
            COUNT(DISTINCT sl.stud_id) AS students_on_device
     FROM deviceTb d
     LEFT JOIN syncLogTb sl ON d.device_uuid = sl.device_uuid
     GROUP BY d.device_id, d.device_uuid, d.device_name, d.registered_at, d.last_synced_at
     ORDER BY d.registered_at DESC`
  );

  res.status(200).json({
    success: true,
    count: result.rows.length,
    devices: result.rows,
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
