const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sqlite3 = require('sqlite3');
const { open } = require('sqlite');

let sqliteDb;

function sha256(value) {
  return crypto.createHash('sha256').update(String(value)).digest('hex');
}

function toSqliteNamedBinds(sql, binds) {
  if (!binds || Array.isArray(binds)) {
    return { sql, binds };
  }

  const mappedBinds = {};
  const mappedSql = sql.replace(/:([a-zA-Z_][a-zA-Z0-9_]*)/g, (_, name) => {
    const key = `$${name}`;
    mappedBinds[key] = Object.prototype.hasOwnProperty.call(binds, name)
      ? binds[name]
      : null;
    return key;
  });

  return { sql: mappedSql, binds: mappedBinds };
}

function normalizeRows(rows) {
  return rows.map((row) => {
    const normalized = {};
    for (const [key, value] of Object.entries(row)) {
      normalized[key.toUpperCase()] = value;
    }
    return normalized;
  });
}

async function bootstrapSchema() {
  const defaultAdminHash = `sha256$${sha256(process.env.ADMIN_SEED_PASSWORD || 'admin123')}`;

  await sqliteDb.exec(`
    PRAGMA foreign_keys = ON;

    CREATE TABLE IF NOT EXISTS sexTb (
      sex_id INTEGER PRIMARY KEY,
      sex TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS diffTb (
      diff_id INTEGER PRIMARY KEY,
      difficulty TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS gradelvlTb (
      gradelvl_id INTEGER PRIMARY KEY,
      gradelvl TEXT NOT NULL,
      age_min INTEGER,
      age_max INTEGER
    );

    CREATE TABLE IF NOT EXISTS subjectTb (
      subject_id INTEGER PRIMARY KEY,
      subject TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS barangayTb (
      barangay_id INTEGER PRIMARY KEY,
      barangay_nm TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS areaTb (
      area_id INTEGER PRIMARY KEY,
      area_nm TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS teacherTb (
      teacher_id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS adminTb (
      admin_id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'admin',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      last_login_at TEXT
    );

    CREATE TABLE IF NOT EXISTS deviceTb (
      device_id INTEGER PRIMARY KEY AUTOINCREMENT,
      device_uuid TEXT NOT NULL UNIQUE,
      device_name TEXT,
      registered_at TEXT DEFAULT CURRENT_TIMESTAMP,
      last_synced_at TEXT
    );

    CREATE TABLE IF NOT EXISTS studentTb (
      stud_id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      nickname TEXT NOT NULL,
      birthday TEXT NOT NULL,
      sex_id INTEGER,
      teacher_id INTEGER,
      area_id INTEGER DEFAULT 1,
      barangay_id INTEGER DEFAULT 1,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      device_origin TEXT,
      tmp_local_id TEXT,
      UNIQUE(nickname, birthday),
      FOREIGN KEY (sex_id) REFERENCES sexTb(sex_id),
      FOREIGN KEY (teacher_id) REFERENCES teacherTb(teacher_id),
      FOREIGN KEY (area_id) REFERENCES areaTb(area_id),
      FOREIGN KEY (barangay_id) REFERENCES barangayTb(barangay_id)
    );

    CREATE TABLE IF NOT EXISTS questionTb (
      question_id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject_id INTEGER NOT NULL,
      gradelvl_id INTEGER NOT NULL,
      diff_id INTEGER NOT NULL,
      question_txt TEXT NOT NULL,
      question_image BLOB,
      option_a TEXT NOT NULL,
      option_b TEXT NOT NULL,
      option_c TEXT NOT NULL,
      option_d TEXT NOT NULL,
      option_a_image BLOB,
      option_b_image BLOB,
      option_c_image BLOB,
      option_d_image BLOB,
      correct_opt TEXT NOT NULL,
      is_active INTEGER DEFAULT 1,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS scoreTb (
      score_id INTEGER PRIMARY KEY AUTOINCREMENT,
      stud_id INTEGER NOT NULL,
      subject_id INTEGER NOT NULL,
      gradelvl_id INTEGER NOT NULL,
      diff_id INTEGER NOT NULL,
      score REAL NOT NULL,
      max_score REAL DEFAULT 10,
      passed INTEGER DEFAULT 0,
      played_at TEXT NOT NULL,
      synced_at TEXT DEFAULT CURRENT_TIMESTAMP,
      device_uuid TEXT,
      FOREIGN KEY (stud_id) REFERENCES studentTb(stud_id),
      FOREIGN KEY (subject_id) REFERENCES subjectTb(subject_id),
      FOREIGN KEY (gradelvl_id) REFERENCES gradelvlTb(gradelvl_id),
      FOREIGN KEY (diff_id) REFERENCES diffTb(diff_id)
    );

    CREATE TABLE IF NOT EXISTS progressTb (
      progress_id INTEGER PRIMARY KEY AUTOINCREMENT,
      stud_id INTEGER NOT NULL,
      subject_id INTEGER NOT NULL,
      gradelvl_id INTEGER NOT NULL,
      highest_diff_passed INTEGER DEFAULT 0,
      total_time_played INTEGER DEFAULT 0,
      last_played_at TEXT,
      UNIQUE (stud_id, subject_id, gradelvl_id),
      FOREIGN KEY (stud_id) REFERENCES studentTb(stud_id),
      FOREIGN KEY (subject_id) REFERENCES subjectTb(subject_id),
      FOREIGN KEY (gradelvl_id) REFERENCES gradelvlTb(gradelvl_id),
      FOREIGN KEY (highest_diff_passed) REFERENCES diffTb(diff_id)
    );

    CREATE TABLE IF NOT EXISTS contentVersionTb (
      version_id INTEGER PRIMARY KEY AUTOINCREMENT,
      version_tag TEXT NOT NULL,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_by TEXT
    );

    CREATE TABLE IF NOT EXISTS syncLogTb (
      sync_id INTEGER PRIMARY KEY AUTOINCREMENT,
      stud_id INTEGER,
      device_uuid TEXT,
      action TEXT,
      event_type TEXT,
      payload TEXT,
      payload_hash TEXT,
      synced_at TEXT DEFAULT CURRENT_TIMESTAMP,
      received_at TEXT DEFAULT CURRENT_TIMESTAMP,
      status TEXT DEFAULT 'processed'
    );
  `);

  await sqliteDb.exec(`
    INSERT OR IGNORE INTO sexTb (sex_id, sex) VALUES (1, 'Male');
    INSERT OR IGNORE INTO sexTb (sex_id, sex) VALUES (2, 'Female');

    INSERT OR IGNORE INTO diffTb (diff_id, difficulty) VALUES (1, 'Easy');
    INSERT OR IGNORE INTO diffTb (diff_id, difficulty) VALUES (2, 'Average');
    INSERT OR IGNORE INTO diffTb (diff_id, difficulty) VALUES (3, 'Hard');

    INSERT OR IGNORE INTO gradelvlTb (gradelvl_id, gradelvl, age_min, age_max) VALUES (1, 'Punla', 3, 5);
    INSERT OR IGNORE INTO gradelvlTb (gradelvl_id, gradelvl, age_min, age_max) VALUES (2, 'Binhi', 6, 8);

    INSERT OR IGNORE INTO subjectTb (subject_id, subject) VALUES (1, 'Mathematics');
    INSERT OR IGNORE INTO subjectTb (subject_id, subject) VALUES (2, 'Science');
    INSERT OR IGNORE INTO subjectTb (subject_id, subject) VALUES (3, 'Filipino');
    INSERT OR IGNORE INTO subjectTb (subject_id, subject) VALUES (4, 'English');

    INSERT OR IGNORE INTO barangayTb (barangay_id, barangay_nm) VALUES (1, 'Barangay Sauyo');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (1, 'LAW STREET');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (2, 'KIMCO VILLAGE');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (3, 'WALING-WALING STREET');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (4, 'VICTORIA SUBDIVISION');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (5, 'SAMPAGUITA STREET');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (6, 'DRJ VILLAGE');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (7, 'LOWER SAUYO');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (8, 'SPAZIO BERNARDO CONDOMINIUM');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (9, 'VICTORIA STREET');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (10, 'RICHLAND SUBDIVISION');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (11, 'PASCUAL STREET');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (12, 'GREENVILLE SUBDIVISION');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (13, 'TEODORO COMPOUND');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (14, 'DEL NACIA VILLE 4');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (15, 'AREA 85');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (16, 'NIA VILLAGE');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (17, 'AREA 99');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (18, 'OCEAN PARK');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (19, 'AREA 135');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (20, 'GREENVIEW ROYALE');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (21, 'BISTEKVILLE 15');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (22, 'GREENVIEW EXECUTIVE');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (23, 'MARIAN EXTENSION');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (24, 'BIR VILLAGE');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (25, 'MARIAN SUBDIVISION');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (26, 'VICTORIAN HEIGHTS');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (27, 'MOZART EXTENSION');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (28, 'VILLA HERMANO 1');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (29, 'COMMERCIO');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (30, 'VILLA HERMANO 2');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (31, 'UPPER GULOD');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (32, 'PRIVADA HOMES');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (33, 'LOWER GULOD');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (34, 'MERRY HOMES');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (35, 'AREA 169');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (36, 'ATHERTON');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (37, 'AREA 160-168');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (38, 'LAGKITAN');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (39, 'DEL MUNDO COMPOUND');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (40, 'HERMINIGILDO COMPOUND');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (41, 'MABUHAY COMPOUND');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (42, 'AREA 5A');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (43, 'AREA 5B');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (44, 'AREA 6A');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (45, 'NAVAL');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (46, 'VILLA ROSARIO');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (47, 'LIPTON STREET');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (48, 'OLD CABUYAO');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (49, 'BALUYOT 1');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (50, 'BALUYOT 2A');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (51, 'BALUYOT 2B');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (52, 'MONTINOLA');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (53, 'BALUYOT PARK');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (54, 'PAPELAN');
    INSERT OR IGNORE INTO areaTb (area_id, area_nm) VALUES (55, 'DAANG NAWASA');

    INSERT OR IGNORE INTO contentVersionTb (version_id, version_tag, updated_by)
    VALUES (1, 'v1', 'system');

    -- Sample questions (Mathematics, Punla, Easy)
    INSERT OR IGNORE INTO questionTb (subject_id, gradelvl_id, diff_id, question_txt, question_image, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (1, 1, 1, 'What is 1 + 1?', NULL, '1', '2', '3', '4', 'B');

    INSERT OR IGNORE INTO questionTb (subject_id, gradelvl_id, diff_id, question_txt, question_image, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (1, 1, 1, 'How many fingers on one hand?', NULL, '3', '4', '5', '6', 'C');

    -- Sample questions (English, Punla, Easy)
    INSERT OR IGNORE INTO questionTb (subject_id, gradelvl_id, diff_id, question_txt, question_image, option_a, option_b, option_c, option_d, correct_opt)
    VALUES (4, 1, 1, 'What color is the sky?', NULL, 'Red', 'Green', 'Blue', 'Yellow', 'C');
  `);

  const studentColumns = await sqliteDb.all(`PRAGMA table_info(studentTb)`);
  const hasAreaId = studentColumns.some((column) => column.name === 'area_id');
  if (!hasAreaId) {
    await sqliteDb.exec(`ALTER TABLE studentTb ADD COLUMN area_id INTEGER DEFAULT 1`);
  }

  const questionColumns = await sqliteDb.all(`PRAGMA table_info(questionTb)`);
  const questionImageColumn = questionColumns.find((column) => column.name === 'question_image');
  if (!questionImageColumn) {
    await sqliteDb.exec(`ALTER TABLE questionTb ADD COLUMN question_image BLOB`);
  } else if (String(questionImageColumn.type || '').toUpperCase() !== 'BLOB') {
    await sqliteDb.exec(`
      BEGIN TRANSACTION;
      ALTER TABLE questionTb RENAME TO questionTb_old;
      CREATE TABLE questionTb (
        question_id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        gradelvl_id INTEGER NOT NULL,
        diff_id INTEGER NOT NULL,
        question_txt TEXT NOT NULL,
        question_image BLOB,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        option_a_image BLOB,
        option_b_image BLOB,
        option_c_image BLOB,
        option_d_image BLOB,
        correct_opt TEXT NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      );
      INSERT INTO questionTb (
        question_id,
        subject_id,
        gradelvl_id,
        diff_id,
        question_txt,
        question_image,
        option_a,
        option_b,
        option_c,
        option_d,
        option_a_image,
        option_b_image,
        option_c_image,
        option_d_image,
        correct_opt,
        is_active,
        created_at,
        updated_at
      )
      SELECT
        question_id,
        subject_id,
        gradelvl_id,
        diff_id,
        question_txt,
        CAST(question_image AS BLOB),
        option_a,
        option_b,
        option_c,
        option_d,
        NULL,
        NULL,
        NULL,
        NULL,
        correct_opt,
        is_active,
        created_at,
        updated_at
      FROM questionTb_old;
      DROP TABLE questionTb_old;
      COMMIT;
    `);
  }

  const optionAImageColumn = questionColumns.find((column) => column.name === 'option_a_image');
  if (!optionAImageColumn) {
    await sqliteDb.exec(`ALTER TABLE questionTb ADD COLUMN option_a_image BLOB`);
  }
  const optionBImageColumn = questionColumns.find((column) => column.name === 'option_b_image');
  if (!optionBImageColumn) {
    await sqliteDb.exec(`ALTER TABLE questionTb ADD COLUMN option_b_image BLOB`);
  }
  const optionCImageColumn = questionColumns.find((column) => column.name === 'option_c_image');
  if (!optionCImageColumn) {
    await sqliteDb.exec(`ALTER TABLE questionTb ADD COLUMN option_c_image BLOB`);
  }
  const optionDImageColumn = questionColumns.find((column) => column.name === 'option_d_image');
  if (!optionDImageColumn) {
    await sqliteDb.exec(`ALTER TABLE questionTb ADD COLUMN option_d_image BLOB`);
  }

  await sqliteDb.run(
    `INSERT OR IGNORE INTO adminTb (admin_id, username, password_hash, role)
     VALUES (1, 'admin', :defaultAdminHash, 'admin')`,
    {
      ':defaultAdminHash': defaultAdminHash,
    }
  );

  await sqliteDb.run(
    `UPDATE adminTb
     SET password_hash = :defaultAdminHash
     WHERE username = 'admin' AND (password_hash IS NULL OR password_hash = '')`,
    {
      ':defaultAdminHash': defaultAdminHash,
    }
  );
}

async function initialize() {
  const dbPath = process.env.SQLITE_DB_PATH
    || path.resolve(__dirname, '..', '..', '..', 'data', 'kow_offline.db');

  fs.mkdirSync(path.dirname(dbPath), { recursive: true });

  sqliteDb = await open({
    filename: dbPath,
    driver: sqlite3.Database
  });

  await bootstrapSchema();
}

async function execute(sql, binds = [], opts = {}) {
  if (!sqliteDb) {
    throw new Error('SQLite database is not initialized');
  }

  const { sql: mappedSql, binds: mappedBinds } = toSqliteNamedBinds(sql, binds);
  const statement = mappedSql.trim().toUpperCase();

  if (statement.startsWith('SELECT')) {
    const rows = await sqliteDb.all(mappedSql, mappedBinds);
    return { rows: normalizeRows(rows), rowsAffected: 0 };
  }

  const result = await sqliteDb.run(mappedSql, mappedBinds);

  if (opts.returning === 'lastId') {
    return { rows: [], rowsAffected: result.changes || 0, outBinds: { outId: [result.lastID] } };
  }

  return {
    rows: [],
    rowsAffected: result.changes || 0,
    lastRowid: result.lastID
  };
}

async function close() {
  if (sqliteDb) {
    await sqliteDb.close();
    sqliteDb = null;
  }
}

module.exports = {
  initialize,
  execute,
  close,
  driver: null
};
