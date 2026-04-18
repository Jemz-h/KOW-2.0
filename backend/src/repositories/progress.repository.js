const { isOnline } = require('./dbMode');
const sqlite = require('./progress.sqlite.repository');
const oracle = require('./progress.oracle.repository');

async function upsertProgress(payload) {
  return isOnline()
    ? oracle.upsertProgressOracle(payload)
    : sqlite.upsertProgressSqlite(payload);
}

async function getProgressByStudent(studentId) {
  return isOnline()
    ? oracle.getProgressByStudentOracle(studentId)
    : sqlite.getProgressByStudentSqlite(studentId);
}

module.exports = {
  upsertProgress,
  getProgressByStudent,
};
