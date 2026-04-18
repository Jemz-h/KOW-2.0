const { connectSqlite } = require('../config/sqlite');

function unlockAchievementSqlite(payload) {
  const db = connectSqlite();
  db.prepare(`
    INSERT INTO student_achievements (student_id, achievement_code, title, unlocked_at)
    VALUES (@studentId, @achievementCode, @title, CURRENT_TIMESTAMP)
    ON CONFLICT(student_id, achievement_code)
    DO UPDATE SET title = excluded.title
  `).run(payload);

  return {
    studentId: payload.studentId,
    achievementCode: payload.achievementCode,
    title: payload.title,
  };
}

function getAchievementsByStudentSqlite(studentId) {
  const db = connectSqlite();
  return db.prepare(`
    SELECT student_id AS studentId,
           achievement_code AS achievementCode,
           title,
           unlocked_at AS unlockedAt
    FROM student_achievements
    WHERE student_id = ?
    ORDER BY unlocked_at DESC
  `).all(studentId);
}

module.exports = {
  unlockAchievementSqlite,
  getAchievementsByStudentSqlite,
};
