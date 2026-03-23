const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Get all active levels
// @route   GET /api/levels
// @access  Public
const getLevels = asyncHandler(async (req, res) => {
  const result = await db.execute(`
    SELECT lt.*, g.gradeNumber, g.gradeName, d.difficultyName, s.subjectName
    FROM Level_Table lt
    JOIN Grade g ON lt.gradeID = g.gradeID
    JOIN Difficulty d ON lt.difficultyID = d.difficultyID
    JOIN Subject s ON g.subjectID = s.subjectID
    ORDER BY g.gradeNumber, d.difficultyID, lt.levelNumber
  `);
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

// @desc    Get levels by gradeID
// @desc    Get levels by gradeID
// @route   GET /api/levels/grade/:gradeId
// @access  Public
const getLevelsByGrade = asyncHandler(async (req, res) => {
  const { gradeId } = req.params;
  const result = await db.execute(
    `SELECT lt.*, d.difficultyName, g.gradeName
     FROM Level_Table lt
     JOIN Difficulty d ON lt.difficultyID = d.difficultyID
     JOIN Grade g ON lt.gradeID = g.gradeID
     WHERE lt.gradeID = :gradeId
     ORDER BY lt.levelNumber`, 
    [gradeId]
  );
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

module.exports = { getLevels, getLevelsByGrade };

