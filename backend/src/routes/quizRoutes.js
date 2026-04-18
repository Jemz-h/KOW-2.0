const express = require('express');
const router = express.Router();
const quizController = require('../controllers/quizController');

// GET /api/quiz/questions
router.get('/questions', quizController.getQuestions);

// POST /api/quiz/score
router.post('/score', quizController.submitScore);

// GET /api/quiz/scores/:studentId
router.get('/scores/:studentId', quizController.getScores);

module.exports = router;