const oracledb = require('oracledb');
const db = require('../config/db');
const asyncHandler = require('express-async-handler');

// @desc    Get quiz questions by grade, subject, and difficulty
// @route   GET /api/quiz/questions
// @access  Public
const getQuestions = asyncHandler(async (req, res) => {
  const { gradeId, levelId } = req.query;

  if (!gradeId || !levelId) {
    res.status(400);
    throw new Error('Please provide gradeId and levelId query parameters');
  }

  // Get questions for the level
  const result = await db.execute(`
    SELECT q.questionID, q.questionText, q.questionImageURL, q.points, q.orderNumber,
           qt.typeName, qt.questionTypeID
    FROM Question q
    JOIN QuestionType qt ON q.questionTypeID = qt.questionTypeID
    WHERE q.levelID = :levelId AND q.isDeleted = 0
    ORDER BY q.orderNumber
  `, [levelId]);

  if (result.rows.length === 0) {
    return res.status(404).json({ success: false, message: 'No questions found for this level' });
  }

  // Fetch answer choices for each question
  const questionsWithAnswers = await Promise.all(
    result.rows.map(async (question) => {
      const answersResult = await db.execute(
        `SELECT choiceID, choiceText, isCorrect, orderNumber
         FROM Answer_Choice
         WHERE questionID = :questionID AND isDeleted = 0
         ORDER BY orderNumber`,
        [question.QUESTIONID]
      );
      return {
        ...question,
        answers: answersResult.rows
      };
    })
  );

  res.status(200).json({ 
    success: true, 
    count: questionsWithAnswers.length,
    questions: questionsWithAnswers 
  });
});

// @desc    Submit quiz score for a student
// @route   POST /api/quiz/submit-score
// @access  Public
const submitScore = asyncHandler(async (req, res) => {
  const { userID, levelID, answers, score, timeSpent } = req.body;

  if (!userID || !levelID || !answers || score === undefined) {
    res.status(400);
    throw new Error('Please provide userID, levelID, answers array, and score');
  }

  // Verify user is active
  const userCheck = await db.execute(
    `SELECT userID FROM Users WHERE userID = :userID AND isDeleted = 0`,
    [userID]
  );
  
  if (userCheck.rows.length === 0) {
    res.status(404);
    throw new Error(`Active user not found with ID of ${userID}`);
  }

  // Save progress
  const progressResult = await db.execute(
    `INSERT INTO User_Progress (userID, levelID, score, completionStatus, timeSpent, attemptsCount) 
     VALUES (:userID, :levelID, :score, 'Completed', :timeSpent, 1)
     RETURNING progressID INTO :progressID`,
    {
      userID,
      levelID,
      score,
      timeSpent,
      progressID: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
    },
    { autoCommit: true }
  );

  const progressID = progressResult.outBinds.progressID[0];

  // Save individual answers
  for (const answer of answers) {
    await db.execute(
      `INSERT INTO User_answer (userID, questionID, progressID, submittedAnswer, isCorrect, pointsEarned, timeSpent)
       VALUES (:userID, :questionID, :progressID, :submittedAnswer, :isCorrect, :pointsEarned, :timeSpent)`,
      {
        userID,
        questionID: answer.questionID,
        progressID,
        submittedAnswer: answer.submittedAnswer,
        isCorrect: answer.isCorrect ? 1 : 0,
        pointsEarned: answer.pointsEarned || 0,
        timeSpent: answer.timeSpent || 0
      },
      { autoCommit: true }
    );
  }

  // Update user achievement
  await db.execute(
    `UPDATE Achievement 
     SET totalQuestionsAnswered = totalQuestionsAnswered + :answerCount,
         totalCorrectAnswers = totalCorrectAnswers + :correctCount,
         totalLevelsCompleted = totalLevelsCompleted + 1,
         timeSpent = timeSpent + :timeSpent
     WHERE userID = :userID`,
    {
      userID,
      answerCount: answers.length,
      correctCount: answers.filter(a => a.isCorrect).length,
      timeSpent: timeSpent || 0
    },
    { autoCommit: true }
  );

  res.status(201).json({ 
    success: true, 
    message: 'Score submitted successfully',
    data: { progressID }
  });
});

// @desc    Get all quiz scores for a student
// @route   GET /api/quiz/scores/:studentId
// @access  Public
const getScores = asyncHandler(async (req, res) => {
  const { studentId } = req.params;

  if (!studentId) {
    res.status(400);
    throw new Error('Student ID is required');
  }

  const result = await db.execute(`
    SELECT up.progressID, up.levelID, up.score, up.completionStatus, 
           up.timeSpent, up.dateCompleted, (COUNT(ua.userAnswerID)) as totalAnswers,
           (SUM(CASE WHEN ua.isCorrect = 1 THEN 1 ELSE 0 END)) as correctAnswers
    FROM User_Progress up
    LEFT JOIN User_answer ua ON up.progressID = ua.progressID
    WHERE up.userID = :studentId
    GROUP BY up.progressID, up.levelID, up.score, up.completionStatus, up.timeSpent, up.dateCompleted
    ORDER BY up.dateCompleted DESC
  `, [studentId]);
  
  res.status(200).json({ 
    success: true, 
    count: result.rows.length,
    scores: result.rows 
  });
});

module.exports = { getQuestions, submitScore, getScores };