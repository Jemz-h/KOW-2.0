const { connectSqlite } = require('../config/sqlite');

function upsertProgressSqlite(payload) {
  const db = connectSqlite();
  db.prepare(`
    INSERT INTO student_progress (student_id, level_id, score, completed, updated_at)
    VALUES (@studentId, @levelId, @score, @completed, CURRENT_TIMESTAMP)
    ON CONFLICT(student_id, level_id)
    DO UPDATE SET score = excluded.score,
                  completed = excluded.completed,
                  updated_at = CURRENT_TIMESTAMP
  `).run({
    studentId: payload.studentId,
    levelId: payload.levelId,
    score: payload.score,
    completed: payload.completed ? 1 : 0,
  });

  return {
    studentId: payload.studentId,
    levelId: payload.levelId,
    score: payload.score,
    completed: Boolean(payload.completed),
  };
}

function getProgressByStudentSqlite(studentId) {
  const db = connectSqlite();
  const rows = db.prepare(`
    SELECT student_id AS studentId,
           level_id AS levelId,
           score,
           completed,
           updated_at AS updatedAt
    FROM student_progress
    WHERE student_id = ?
    ORDER BY level_id
  `).all(studentId);

  return rows.map((row) => ({
    ...row,
    completed: Boolean(row.completed),
  }));
}

module.exports = {
  upsertProgressSqlite,
  getProgressByStudentSqlite,
};
