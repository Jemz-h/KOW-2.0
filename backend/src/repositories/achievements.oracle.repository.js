const oracledb = require('oracledb');
const { withOracleConnection } = require('../config/oracle');

async function unlockAchievementOracle(payload) {
  await withOracleConnection((connection) =>
    connection.execute(
      `
      INSERT INTO syncLogTb (sync_id, device_uuid, stud_id, event_type, payload, received_at, status)
      VALUES (
        seq_sync_id.NEXTVAL,
        :deviceUuid,
        :studId,
        'achievement',
        :payload,
        SYSDATE,
        'processed'
      )
      `,
      {
        deviceUuid: payload.deviceUuid || 'API',
        studId: Number(payload.studentId),
        payload: `${payload.achievementCode}|${payload.title}`,
      },
      { autoCommit: true }
    )
  );

  return {
    studentId: payload.studentId,
    achievementCode: payload.achievementCode,
    title: payload.title,
  };
}

async function getAchievementsByStudentOracle(studentId) {
  return withOracleConnection(async (connection) => {
    const result = await connection.execute(
      `
      SELECT TO_CHAR(stud_id) AS "studentId",
             payload AS "payload",
             TO_CHAR(received_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS "unlockedAt"
      FROM syncLogTb
      WHERE stud_id = :studentId
        AND event_type = 'achievement'
      ORDER BY received_at DESC
      `,
      { studentId: Number(studentId) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    return (result.rows || []).map((row) => {
      const raw = row.payload || '';
      const sep = raw.indexOf('|');
      const achievementCode = sep >= 0 ? raw.slice(0, sep) : raw;
      const title = sep >= 0 ? raw.slice(sep + 1) : raw;

      return {
        studentId: row.studentId,
        achievementCode,
        title,
        unlockedAt: row.unlockedAt,
      };
    });
  });
}

module.exports = {
  unlockAchievementOracle,
  getAchievementsByStudentOracle,
};
