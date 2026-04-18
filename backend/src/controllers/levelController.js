const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Get all active levels
// @route   GET /api/levels
// @access  Public
const getLevels = asyncHandler(async (req, res) => {
  const result = await db.execute(`
    SELECT g.gradelvl_id,
           g.gradelvl,
           g.age_min,
           g.age_max,
           s.subject_id,
           s.subject,
           d.diff_id,
           d.difficulty
    FROM gradelvlTb g
    CROSS JOIN subjectTb s
    CROSS JOIN diffTb d
    ORDER BY g.gradelvl_id, s.subject_id, d.diff_id
  `);
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

// @desc    Get levels by gradeID
// @route   GET /api/levels/grade/:gradeId
// @access  Public
const getLevelsByGrade = asyncHandler(async (req, res) => {
  const { gradeId } = req.params;
  const result = await db.execute(
    `SELECT g.gradelvl_id,
            g.gradelvl,
            g.age_min,
            g.age_max,
            s.subject_id,
            s.subject,
            d.diff_id,
            d.difficulty
     FROM gradelvlTb g
     CROSS JOIN subjectTb s
     CROSS JOIN diffTb d
     WHERE g.gradelvl_id = :gradeId
     ORDER BY s.subject_id, d.diff_id`,
    { gradeId }
  );
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

module.exports = { getLevels, getLevelsByGrade };

