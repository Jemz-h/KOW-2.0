const oracledb = require('oracledb');
const { withOracleConnection } = require('../config/oracle');

async function upsertProgressOracle(payload) {
  await withOracleConnection((connection) =>
    connection.execute(
      `
      MERGE INTO progressTb p
      USING (
        SELECT :studId AS stud_id,
               :subjectId AS subject_id,
               :gradeLevelId AS gradelvl_id,
               :highestDiffPassed AS highest_diff_passed,
               :score AS score
        FROM dual
      ) incoming
      ON (p.stud_id = incoming.stud_id
          AND p.subject_id = incoming.subject_id
          AND p.gradelvl_id = incoming.gradelvl_id)
      WHEN MATCHED THEN
        UPDATE SET p.highest_diff_passed = GREATEST(NVL(p.highest_diff_passed, 0), incoming.highest_diff_passed),
                   p.last_played_at = SYSDATE
      WHEN NOT MATCHED THEN
        INSERT (progress_id, stud_id, subject_id, gradelvl_id, highest_diff_passed, last_played_at)
        VALUES (seq_score_id.NEXTVAL, incoming.stud_id, incoming.subject_id, incoming.gradelvl_id, incoming.highest_diff_passed, SYSDATE)
      `,
      {
        studId: Number(payload.studentId),
        subjectId: Number(payload.subjectId || 1),
        gradeLevelId: Number(payload.levelId),
        highestDiffPassed: payload.completed ? Number(payload.diffId || 1) : 0,
        score: payload.score,
      },
      { autoCommit: true }
    )
  );

  return {
    studentId: payload.studentId,
    levelId: payload.levelId,
    score: payload.score,
    completed: Boolean(payload.completed),
  };
}

async function getProgressByStudentOracle(studentId) {
  return withOracleConnection(async (connection) => {
    const result = await connection.execute(
      `
      SELECT TO_CHAR(stud_id) AS "studentId",
             TO_CHAR(gradelvl_id) AS "levelId",
             subject_id AS "subjectId",
             highest_diff_passed AS "diffId",
             CASE WHEN highest_diff_passed > 0 THEN 1 ELSE 0 END AS "completed",
             TO_CHAR(last_played_at, 'YYYY-MM-DD"T"HH24:MI:SS') AS "updatedAt"
      FROM progressTb
      WHERE stud_id = :studentId
      ORDER BY gradelvl_id
      `,
      { studentId: Number(studentId) },
      { outFormat: oracledb.OUT_FORMAT_OBJECT }
    );

    return (result.rows || []).map((row) => ({
      ...row,
      score: 0,
      completed: Boolean(row.completed),
    }));
  });
}

module.exports = {
  upsertProgressOracle,
  getProgressByStudentOracle,
};
