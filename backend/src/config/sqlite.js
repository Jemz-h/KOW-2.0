const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');
const { sqlitePath } = require('./env');

let db;

function connectSqlite() {
  if (db) return db;
  fs.mkdirSync(path.dirname(sqlitePath), { recursive: true });
  db = new Database(sqlitePath);
  db.pragma('journal_mode = WAL');
  db.exec(`
    CREATE TABLE IF NOT EXISTS students (
      student_id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      nickname TEXT,
      area TEXT,
      birthday TEXT,
      sex TEXT,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS student_progress (
      student_id TEXT NOT NULL,
      level_id TEXT NOT NULL,
      score INTEGER NOT NULL DEFAULT 0,
      completed INTEGER NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (student_id, level_id),
      FOREIGN KEY (student_id) REFERENCES students(student_id)
    );

    CREATE TABLE IF NOT EXISTS student_achievements (
      student_id TEXT NOT NULL,
      achievement_code TEXT NOT NULL,
      title TEXT NOT NULL,
      unlocked_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (student_id, achievement_code),
      FOREIGN KEY (student_id) REFERENCES students(student_id)
    );
  `);
  return db;
}

function closeSqlite() {
  if (db) {
    db.close();
    db = null;
  }
}

module.exports = {
  connectSqlite,
  closeSqlite,
};
