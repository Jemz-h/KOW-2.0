const { isOnline } = require('./dbMode');
const sqlite = require('./achievements.sqlite.repository');
const oracle = require('./achievements.oracle.repository');

async function unlockAchievement(payload) {
  return isOnline()
    ? oracle.unlockAchievementOracle(payload)
    : sqlite.unlockAchievementSqlite(payload);
}

async function getAchievementsByStudent(studentId) {
  return isOnline()
    ? oracle.getAchievementsByStudentOracle(studentId)
    : sqlite.getAchievementsByStudentSqlite(studentId);
}

module.exports = {
  unlockAchievement,
  getAchievementsByStudent,
};
