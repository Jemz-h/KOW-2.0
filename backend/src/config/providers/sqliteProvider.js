const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3');
const { open } = require('sqlite');

let sqliteDb;

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

    CREATE TABLE IF NOT EXISTS teacherTb (
      teacher_id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS studentTb (
      stud_id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      nickname TEXT NOT NULL,
      birthday TEXT NOT NULL,
      sex_id INTEGER,
      teacher_id INTEGER,
      barangay_id INTEGER DEFAULT 1,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
      device_origin TEXT,
      tmp_local_id TEXT,
      UNIQUE(nickname, birthday),
      FOREIGN KEY (sex_id) REFERENCES sexTb(sex_id),
      FOREIGN KEY (teacher_id) REFERENCES teacherTb(teacher_id),
      FOREIGN KEY (barangay_id) REFERENCES barangayTb(barangay_id)
    );

    CREATE TABLE IF NOT EXISTS questionTb (
      question_id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject_id INTEGER NOT NULL,
      gradelvl_id INTEGER NOT NULL,
      diff_id INTEGER NOT NULL,
      question_txt TEXT NOT NULL,
      option_a TEXT NOT NULL,
      option_b TEXT NOT NULL,
      option_c TEXT NOT NULL,
      option_d TEXT NOT NULL,
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
      FOREIGN KEY (stud_id) REFERENCES studentTb(stud_id)
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
      FOREIGN KEY (stud_id) REFERENCES studentTb(stud_id)
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
  `);
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
