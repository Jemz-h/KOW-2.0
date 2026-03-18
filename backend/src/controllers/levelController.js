const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Get all levels
// @route   GET /api/levels
// @access  Public
const getLevels = asyncHandler(async (req, res) => {
  const result = await db.execute(`SELECT * FROM Level_Table`);
  
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
    `SELECT * FROM Level_Table WHERE gradeID = :gradeId`, 
    [gradeId]
  );
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

module.exports = { getLevels, getLevelsByGrade };

