const { isOnline } = require('./dbMode');
const sqlite = require('./students.sqlite.repository');
const oracle = require('./students.oracle.repository');

function adapter() {
  return isOnline() ? oracle : sqlite;
}

async function createStudent(payload) {
  return adapter().createStudentOracle
    ? adapter().createStudentOracle(payload)
    : adapter().createStudentSqlite(payload);
}

async function findStudentById(studentId) {
  return adapter().findStudentByIdOracle
    ? adapter().findStudentByIdOracle(studentId)
    : adapter().findStudentByIdSqlite(studentId);
}

async function listStudents() {
  return adapter().listStudentsOracle
    ? adapter().listStudentsOracle()
    : adapter().listStudentsSqlite();
}

async function getLeaderboard() {
  return adapter().leaderboardOracle
    ? adapter().leaderboardOracle()
    : adapter().leaderboardSqlite();
}

module.exports = {
  createStudent,
  findStudentById,
  listStudents,
  getLeaderboard,
};
