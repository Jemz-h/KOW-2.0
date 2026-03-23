const oracledb = require('oracledb');
const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Create or update progress
// @route   POST /api/progress
// @access  Public
const saveProgress = asyncHandler(async (req, res) => {
  const { userID, levelID, score, completionStatus, timeSpent, attemptsCount } = req.body;

  if (!userID || !levelID) {
    res.status(400);
    throw new Error('Please provide userID and levelID');
  }

  // Validate user exists and is active
  const userCheck = await db.execute(
    `SELECT userID FROM Users WHERE userID = :userID AND isDeleted = 0`,
    [userID]
  );
  
  if (userCheck.rows.length === 0) {
    res.status(404);
    throw new Error(`Active user not found with ID of ${userID}`);
  }

  const result = await db.execute(
    `INSERT INTO User_Progress (userID, levelID, score, completionStatus, timeSpent, attemptsCount) 
     VALUES (:userID, :levelID, :score, :completionStatus, :timeSpent, :attemptsCount)
     RETURNING progressID INTO :progressID`,
    {
      userID,
      levelID,
      score: score || 0,
      completionStatus,
      timeSpent,
      attemptsCount: attemptsCount || 1,
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
  
  // Verify user is active
  const userCheck = await db.execute(
    `SELECT userID FROM Users WHERE userID = :userId AND isDeleted = 0`,
    [userId]
  );
  
  if (userCheck.rows.length === 0) {
    res.status(404);
    throw new Error(`Active user not found with ID of ${userId}`);
  }
  
  const result = await db.execute(
    `SELECT up.*, l.levelName, l.maxScore, l.passingScore 
     FROM User_Progress up
     JOIN Level_Table l ON up.levelID = l.levelID
     WHERE up.userID = :userId 
     ORDER BY up.dateCompleted DESC`,
    [userId]
  );
  
  res.status(200).json({
    success: true,
    count: result.rows.length,
    data: result.rows
  });
});

module.exports = { saveProgress, getUserProgress };

