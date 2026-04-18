const { connectSqlite } = require('../config/sqlite');

function createStudentSqlite(payload) {
  const db = connectSqlite();
  const stmt = db.prepare(`
    INSERT INTO students (
      student_id, first_name, last_name, nickname, area, birthday, sex, password_hash
    ) VALUES (
      @studentId, @firstName, @lastName, @nickname, @area, @birthday, @sex, @passwordHash
    )
  `);
  stmt.run(payload);
  return findStudentByIdSqlite(payload.studentId);
}

function findStudentByIdSqlite(studentId) {
  const db = connectSqlite();
  const stmt = db.prepare(`
    SELECT student_id AS studentId,
           first_name AS firstName,
           last_name AS lastName,
           nickname,
           area,
           birthday,
           sex,
           password_hash AS passwordHash,
           created_at AS createdAt
    FROM students
    WHERE student_id = ?
  `);
  return stmt.get(studentId) || null;
}

function listStudentsSqlite() {
  const db = connectSqlite();
  const stmt = db.prepare(`
    SELECT student_id AS studentId,
           first_name AS firstName,
           last_name AS lastName,
           nickname,
           area,
           birthday,
           sex,
           created_at AS createdAt
    FROM students
    ORDER BY created_at DESC
  `);
  return stmt.all();
}

function leaderboardSqlite() {
  const db = connectSqlite();
  const stmt = db.prepare(`
    SELECT s.student_id AS studentId,
           s.first_name AS firstName,
           s.last_name AS lastName,
           COALESCE(SUM(p.score), 0) AS totalScore
    FROM students s
    LEFT JOIN student_progress p ON p.student_id = s.student_id
    GROUP BY s.student_id, s.first_name, s.last_name
    ORDER BY totalScore DESC, s.first_name ASC
    LIMIT 20
  `);
  return stmt.all();
}

module.exports = {
  createStudentSqlite,
  findStudentByIdSqlite,
  listStudentsSqlite,
  leaderboardSqlite,
};
