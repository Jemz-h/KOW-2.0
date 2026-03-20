const QuizModel = require('../models/quizModel');

exports.getQuestions = async (req, res, next) => {
  try {
    const { grade, subject, difficulty } = req.query;

    if (!grade || !subject || !difficulty) {
      return res.status(400).json({ error: 'Grade, subject, and difficulty are required parameters' });
    }

    const questions = await QuizModel.getQuestions(grade, subject, difficulty);
    
    res.json({ success: true, questions });
  } catch (error) {
    next(error);
  }
};

exports.submitScore = async (req, res, next) => {
  try {
    const { studentId, grade, subject, difficulty, score, total } = req.body;

    if (!studentId || !grade || !subject || !difficulty || score === undefined || total === undefined) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    await QuizModel.submitScore(studentId, grade, subject, difficulty, score, total);
    
    res.status(201).json({ success: true, message: 'Score submitted successfully' });
  } catch (error) {
    if (error.message.includes('Level not found')) {
      return res.status(404).json({ error: error.message });
    }
    next(error);
  }
};

exports.getScores = async (req, res, next) => {
  try {
    const { studentId } = req.params;

    if (!studentId) {
      return res.status(400).json({ error: 'Student ID is required' });
    }

    const scores = await QuizModel.getScores(studentId);
    res.json({ success: true, scores });
  } catch (error) {
    next(error);
  }
};