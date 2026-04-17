const { getLeaderboard } = require('../repositories/students.repository');

// @desc    Get leaderboard ranking by total score
// @route   GET /api/leaderboard
// @access  Public
async function listLeaderboard(req, res, next) {
  try {
    const rows = await getLeaderboard();
    return res.status(200).json({ count: rows.length, data: rows });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listLeaderboard,
};
