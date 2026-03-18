const oracledb = require('oracledb');
const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Create or update progress
// @route   POST /api/progress
// @access  Public
const saveProgress = asyncHandler(async (req, res) => {
  const { userID, levelID, score, completionStatus, timeSpent } = req.body;

  if (!userID || !levelID) {
    res.status(400);
    throw new Error('Please provide userID and levelID');
  }

  const result = await db.execute(
    `INSERT INTO User_Progress (userID, levelID, score, completionStatus, timeSpent, dateCompleted) 
     VALUES (:userID, :levelID, :score, :completionStatus, :timeSpent, CURRENT_TIMESTAMP)
     RETURNING progressID INTO :progressID`,
    {
      userID,
      levelID,
      score: score || 0,
      completionStatus,
      timeSpent,
      progressID: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    },
    { autoCommit: true }
  );

  res.status(201).json({ 
    success: true,
    message: 'Progress saved successfully',
    data: { progressID: result.outBinds.progressID[0] }
  });
});

// @desc    Get user progress
// @route   GET /api/progress/user/:userId
// @access  Public
const getUserProgress = asyncHandler(async (req, res) => {
  const { userId } = req.params;
  const result = await db.execute(
    `SELECT * FROM User_Progress WHERE userID = :userId ORDER BY dateCompleted DESC`,
    [userId]
  );
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

module.exports = { saveProgress, getUserProgress };

