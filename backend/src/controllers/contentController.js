const asyncHandler = require('express-async-handler');
const db = require('../config/db');
const { serializeQuestionImage } = require('../utils/questionImage');

// @desc    Pull active content with version metadata
// @route   GET /api/content
// @access  Public
const getContent = asyncHandler(async (req, res) => {
  const { sinceVersion, version } = req.query;
  const requestedVersion = sinceVersion || version || null;
  const versionTimestampColumn = db.isOracle() ? 'changed_at' : 'updated_at';
  const versionLimitClause = db.isOracle() ? 'FETCH FIRST 1 ROWS ONLY' : 'LIMIT 1';

  const versionResult = await db.execute(
    `SELECT version_tag,
            ${versionTimestampColumn} AS version_ts
     FROM contentVersionTb
     ORDER BY version_id DESC
     ${versionLimitClause}`
  );

  const versionRow = versionResult.rows[0] || null;
  const currentVersion = versionRow?.VERSION_TAG || 'v1';

  if (requestedVersion && String(requestedVersion) === String(currentVersion)) {
    return res.status(200).json({
      success: true,
      up_to_date: true,
      version_tag: currentVersion,
      hasUpdate: false,
      version: {
        tag: currentVersion,
        updatedAt: versionRow?.VERSION_TS || null,
      },
      content: null,
    });
  }

  const activeFilter = db.isOracle() ? 'NVL(q.is_active, 1) = 1' : 'COALESCE(q.is_active, 1) = 1';
  const questionsResult = await db.execute(
    `SELECT q.question_id,
            q.question_txt,
            q.question_image,
            q.option_a,
            q.option_b,
            q.option_c,
            q.option_d,
            q.correct_opt,
            q.is_active,
            q.updated_at,
            s.subject,
            g.gradelvl,
            d.difficulty
     FROM questionTb q
     JOIN subjectTb s ON q.subject_id = s.subject_id
     JOIN gradelvlTb g ON q.gradelvl_id = g.gradelvl_id
     JOIN diffTb d ON q.diff_id = d.diff_id
     WHERE ${activeFilter}
     ORDER BY q.question_id`
  );

  const questions = questionsResult.rows.map((row) => {
    const normalizedRow = Object.entries(row).reduce((accumulator, [key, value]) => {
      accumulator[key.toUpperCase()] = value;
      return accumulator;
    }, {});

    const imageBlob = serializeQuestionImage(normalizedRow.QUESTION_IMAGE);
    return {
      id: normalizedRow.QUESTION_ID,
      prompt: normalizedRow.QUESTION_TXT,
      imageBlob,
      imagePath: imageBlob,
      choices: [normalizedRow.OPTION_A, normalizedRow.OPTION_B, normalizedRow.OPTION_C, normalizedRow.OPTION_D],
      correctOption: normalizedRow.CORRECT_OPT,
      subject: normalizedRow.SUBJECT,
      grade: normalizedRow.GRADELVL,
      difficulty: normalizedRow.DIFFICULTY,
      updatedAt: normalizedRow.UPDATED_AT,
      isActive: normalizedRow.IS_ACTIVE,
    };
  });

  return res.status(200).json({
    success: true,
    up_to_date: false,
    version_tag: currentVersion,
    questions,
    hasUpdate: true,
    version: {
      tag: currentVersion,
      updatedAt: versionRow?.VERSION_TS || null,
    },
    content: {
      questions,
    },
  });
});

module.exports = {
  getContent,
};
