const {
  upsertProgress,
  getProgressByStudent,
} = require('../repositories/progress.repository');
const { dbMode } = require('../config/env');

// @desc    Create or update progress
// @route   POST /api/progress
// @access  Public
async function createOrUpdateProgress(req, res, next) {
  try {
    const {
      studentId,
      levelId,
      score = 0,
      completed = false,
      subjectId,
      diffId,
    } = req.body;

    if (!studentId || !levelId) {
      return res.status(400).json({
        message: 'studentId and levelId are required.',
      });
    }

    if (dbMode === 'online') {
      const parsedStudentId = Number(studentId);
      const parsedLevelId = Number(levelId);
      if (Number.isNaN(parsedStudentId) || Number.isNaN(parsedLevelId)) {
        return res.status(400).json({
          message: 'studentId and levelId must be numeric in online mode.',
        });
      }
    }

    const numericScore = Number(score);
    if (Number.isNaN(numericScore)) {
      return res.status(400).json({ message: 'score must be numeric.' });
    }

    const data = await upsertProgress({
      studentId: String(studentId),
      levelId: String(levelId),
      score: numericScore,
      completed: Boolean(completed),
      subjectId,
      diffId,
    });

    return res.status(200).json({ message: 'Progress saved.', data });
  } catch (error) {
    return next(error);
  }
}

// @desc    Get progress by student
// @route   GET /api/progress/:studentId
// @access  Public
async function getProgress(req, res, next) {
  try {
    const rows = await getProgressByStudent(String(req.params.studentId));
    return res.status(200).json({ count: rows.length, data: rows });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createOrUpdateProgress,
  getProgress,
};
