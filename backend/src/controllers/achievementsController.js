const {
  unlockAchievement,
  getAchievementsByStudent,
} = require('../repositories/achievements.repository');
const { dbMode } = require('../config/env');

// @desc    Unlock or update a student achievement
// @route   POST /api/achievements
// @access  Public
async function createOrUpdateAchievement(req, res, next) {
  try {
    const { studentId, achievementCode, title } = req.body;

    if (!studentId || !achievementCode || !title) {
      return res.status(400).json({
        message: 'studentId, achievementCode, and title are required.',
      });
    }

    if (dbMode === 'online' && Number.isNaN(Number(studentId))) {
      return res.status(400).json({
        message: 'studentId must be numeric in online mode.',
      });
    }

    const data = await unlockAchievement({
      studentId: String(studentId),
      achievementCode: String(achievementCode),
      title: String(title),
    });

    return res.status(200).json({ message: 'Achievement saved.', data });
  } catch (error) {
    return next(error);
  }
}

// @desc    Get achievements by student
// @route   GET /api/achievements/:studentId
// @access  Public
async function getAchievements(req, res, next) {
  try {
    const rows = await getAchievementsByStudent(String(req.params.studentId));
    return res.status(200).json({ count: rows.length, data: rows });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  createOrUpdateAchievement,
  getAchievements,
};
