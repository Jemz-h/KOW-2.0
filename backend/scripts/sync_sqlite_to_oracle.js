/*
  One-time data bridge: backend SQLite fallback -> Oracle

  Usage:
    node scripts/sync_sqlite_to_oracle.js

  Required env vars:
    ORACLE_USER / DB_USER
    ORACLE_PASSWORD / DB_PASSWORD
    ORACLE_CONNECTION_STRING / DB_CONNECTION_STRING

  Optional env vars:
    SQLITE_DB_PATH (default: ./data/kow_offline.db)
*/

const path = require('path');
const oracledb = require('oracledb');
const sqlite3 = require('sqlite3');
const { open } = require('sqlite');
require('dotenv').config();

function requireEnv(primary, fallback) {
  const value = process.env[primary] || process.env[fallback];
  if (!value) {
    throw new Error(`Missing environment variable: ${primary} (or ${fallback})`);
  }
  return value;
}

function normalizeBirthday(value) {
  if (!value) return null;
  const raw = String(value).trim();
  const match = raw.match(/^(\d{4})-(\d{1,2})-(\d{1,2})$/);
  if (!match) {
    return raw.length >= 10 ? raw.slice(0, 10) : raw;
  }

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);

  if (month < 1 || month > 12 || day < 1 || day > 31) {
    return raw;
  }

  return `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

function normalizeDateTime(value) {
  if (!value) return null;
  const raw = String(value).trim().replace('T', ' ');
  return raw.length >= 19 ? raw.slice(0, 19) : raw;
}

async function ensureOracleStudent(connection, studentRow) {
  const birthday = normalizeBirthday(studentRow.birthday);
  const findResult = await connection.execute(
    `SELECT stud_id
     FROM studentTb
     WHERE nickname = :nickname
       AND TRUNC(birthday) = TO_DATE(:birthday, 'YYYY-MM-DD')`,
    {
      nickname: studentRow.nickname,
      birthday,
    },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  if (findResult.rows.length > 0) {
    const existingStudId = Number(findResult.rows[0].STUD_ID);

    await connection.execute(
      `UPDATE studentTb
       SET first_name = :firstName,
           last_name = :lastName,
           nickname = :nickname,
           birthday = TO_DATE(:birthday, 'YYYY-MM-DD'),
           sex_id = NVL(:sexId, sex_id),
           teacher_id = NVL(:teacherId, teacher_id),
             area_id = NVL(:areaId, area_id),
           device_origin = NVL(:deviceOrigin, device_origin),
           tmp_local_id = NVL(:tmpLocalId, tmp_local_id),
           updated_at = SYSTIMESTAMP
       WHERE stud_id = :studId`,
      {
        studId: existingStudId,
        firstName: studentRow.first_name,
        lastName: studentRow.last_name,
        nickname: studentRow.nickname,
        birthday,
        sexId: studentRow.sex_id || null,
        teacherId: studentRow.teacher_id || null,
        areaId: studentRow.area_id || studentRow.barangay_id || null,
        deviceOrigin: studentRow.device_origin || null,
        tmpLocalId: studentRow.tmp_local_id || null,
      },
      { autoCommit: false }
    );

    return existingStudId;
  }

  const insertResult = await connection.execute(
    `INSERT INTO studentTb (
       first_name,
       last_name,
       nickname,
       birthday,
       sex_id,
       teacher_id,
       area_id,
       barangay_id,
       device_origin,
       tmp_local_id
     ) VALUES (
       :firstName,
       :lastName,
       :nickname,
       TO_DATE(:birthday, 'YYYY-MM-DD'),
       :sexId,
       :teacherId,
       :areaId,
       :barangayId,
       :deviceOrigin,
       :tmpLocalId
     )
     RETURNING stud_id INTO :outId`,
    {
      firstName: studentRow.first_name,
      lastName: studentRow.last_name,
      nickname: studentRow.nickname,
      birthday,
      sexId: studentRow.sex_id || null,
      teacherId: studentRow.teacher_id || null,
      areaId: studentRow.area_id || studentRow.barangay_id || 1,
      barangayId: studentRow.barangay_id || 1,
      deviceOrigin: studentRow.device_origin || null,
      tmpLocalId: studentRow.tmp_local_id || null,
      outId: { dir: oracledb.BIND_OUT, type: oracledb.NUMBER },
    },
    { autoCommit: false }
  );

  return Number(insertResult.outBinds.outId[0]);
}

async function scoreExists(connection, params) {
  const result = await connection.execute(
    `SELECT COUNT(*) AS CNT
     FROM scoreTb
     WHERE stud_id = :studId
       AND subject_id = :subjectId
       AND gradelvl_id = :gradeLevelId
       AND diff_id = :diffId
       AND played_at = TO_DATE(:playedAt, 'YYYY-MM-DD HH24:MI:SS')
       AND (:deviceUuid IS NULL OR NVL(device_uuid, '__NONE__') = NVL(:deviceUuid, '__NONE__'))`,
    params,
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  return Number(result.rows[0].CNT || 0) > 0;
}

async function rebuildProgressFromScores(connection, importedStudentIds) {
  for (const studId of importedStudentIds) {
    await connection.execute(
      `MERGE INTO progressTb p
       USING (
         SELECT stud_id,
                subject_id,
                gradelvl_id,
                MAX(CASE WHEN passed = 1 THEN diff_id ELSE 0 END) AS highest_diff_passed,
                MAX(played_at) AS last_played_at
         FROM scoreTb
         WHERE stud_id = :studId
         GROUP BY stud_id, subject_id, gradelvl_id
       ) src
       ON (
         p.stud_id = src.stud_id
         AND p.subject_id = src.subject_id
         AND p.gradelvl_id = src.gradelvl_id
       )
       WHEN MATCHED THEN UPDATE SET
         p.highest_diff_passed = GREATEST(NVL(p.highest_diff_passed, 0), NVL(src.highest_diff_passed, 0)),
         p.last_played_at = CASE
           WHEN p.last_played_at IS NULL THEN src.last_played_at
           WHEN src.last_played_at > p.last_played_at THEN src.last_played_at
           ELSE p.last_played_at
         END
       WHEN NOT MATCHED THEN INSERT (
         progress_id,
         stud_id,
         subject_id,
         gradelvl_id,
         highest_diff_passed,
         total_time_played,
         last_played_at
       ) VALUES (
         seq_score_id.NEXTVAL,
         src.stud_id,
         src.subject_id,
         src.gradelvl_id,
         NVL(src.highest_diff_passed, 0),
         0,
         src.last_played_at
       )`,
      { studId },
      { autoCommit: false }
    );
  }
}

async function main() {
  const oracleUser = requireEnv('ORACLE_USER', 'DB_USER');
  const oraclePassword = requireEnv('ORACLE_PASSWORD', 'DB_PASSWORD');
  const oracleConnectionString = requireEnv('ORACLE_CONNECTION_STRING', 'DB_CONNECTION_STRING');
  const sqliteDbPath = process.env.SQLITE_DB_PATH || path.resolve(__dirname, '..', 'data', 'kow_offline.db');

  console.log(`Opening SQLite: ${sqliteDbPath}`);
  const sqliteDb = await open({
    filename: sqliteDbPath,
    driver: sqlite3.Database,
  });

  console.log('Connecting Oracle...');
  const oracleConnection = await oracledb.getConnection({
    user: oracleUser,
    password: oraclePassword,
    connectString: oracleConnectionString,
  });

  let insertedStudents = 0;
  let insertedScores = 0;
  let skippedScores = 0;

  try {
    const students = await sqliteDb.all(
      `SELECT stud_id,
              first_name,
              last_name,
              nickname,
              birthday,
              sex_id,
              teacher_id,
              area_id,
              barangay_id,
              device_origin,
              tmp_local_id
       FROM studentTb
       ORDER BY stud_id ASC`
    );

    const studentIdMap = new Map();
    const importedStudentIds = new Set();

    for (const student of students) {
      const oracleStudId = await ensureOracleStudent(oracleConnection, student);
      studentIdMap.set(Number(student.stud_id), oracleStudId);
      importedStudentIds.add(oracleStudId);
      insertedStudents += 1;
    }

    const scores = await sqliteDb.all(
      `SELECT score_id,
              stud_id,
              subject_id,
              gradelvl_id,
              diff_id,
              score,
              max_score,
              passed,
              played_at,
              device_uuid
       FROM scoreTb
       ORDER BY score_id ASC`
    );

    for (const score of scores) {
      const mappedStudId = studentIdMap.get(Number(score.stud_id));
      if (!mappedStudId) {
        continue;
      }

      const playedAt = normalizeDateTime(score.played_at);
      if (!playedAt) {
        continue;
      }

      const params = {
        studId: mappedStudId,
        subjectId: Number(score.subject_id),
        gradeLevelId: Number(score.gradelvl_id),
        diffId: Number(score.diff_id),
        playedAt,
        deviceUuid: score.device_uuid || null,
      };

      const exists = await scoreExists(oracleConnection, params);
      if (exists) {
        skippedScores += 1;
        continue;
      }

      await oracleConnection.execute(
        `INSERT INTO scoreTb (
           score_id,
           stud_id,
           subject_id,
           gradelvl_id,
           diff_id,
           score,
           max_score,
           passed,
           played_at,
           synced_at,
           device_uuid
         ) VALUES (
           seq_score_id.NEXTVAL,
           :studId,
           :subjectId,
           :gradeLevelId,
           :diffId,
           :scoreValue,
           :maxScore,
           :passed,
           TO_DATE(:playedAt, 'YYYY-MM-DD HH24:MI:SS'),
           SYSDATE,
           :deviceUuid
         )`,
        {
          studId: mappedStudId,
          subjectId: Number(score.subject_id),
          gradeLevelId: Number(score.gradelvl_id),
          diffId: Number(score.diff_id),
          scoreValue: Number(score.score),
          maxScore: Number(score.max_score || 10),
          passed: Number(score.passed || 0),
          playedAt,
          deviceUuid: score.device_uuid || null,
        },
        { autoCommit: false }
      );

      insertedScores += 1;
    }

    await rebuildProgressFromScores(oracleConnection, importedStudentIds);
    await oracleConnection.commit();

    console.log('SQLite -> Oracle sync complete.');
    console.log(`Students processed: ${insertedStudents}`);
    console.log(`Scores inserted:   ${insertedScores}`);
    console.log(`Scores skipped:    ${skippedScores}`);
  } finally {
    await sqliteDb.close();
    await oracleConnection.close();
  }
}

main().catch((error) => {
  console.error('SQLite -> Oracle sync failed:', error.message);
  process.exit(1);
});
