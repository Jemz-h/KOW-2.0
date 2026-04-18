const { dbMode } = require('./env');
const { connectOracle, closeOracle } = require('./oracle');
const { connectSqlite, closeSqlite } = require('./sqlite');
const oracledb = require('oracledb');

function isOracle() {
  return dbMode === 'online';
}

function isSqlite() {
  return !isOracle();
}

function getActiveClient() {
  return isOracle() ? 'oracle' : 'sqlite';
}

function getDriver() {
  return isOracle() ? oracledb : null;
}

async function execute(sql, binds = {}, opts = {}) {
  if (isOracle()) {
    const pool = await connectOracle();
    const connection = await pool.getConnection();
    try {
      return await connection.execute(sql, binds, {
        autoCommit: Boolean(opts.autoCommit),
        outFormat: opts.outFormat || require('oracledb').OUT_FORMAT_OBJECT,
      });
    } finally {
      await connection.close();
    }
  }

  const db = connectSqlite();
  const statement = db.prepare(sql);
  const isSelect = /^\s*select\b/i.test(sql);

  if (isSelect) {
    return {
      rows: statement.all(binds),
      rowsAffected: 0,
    };
  }

  const result = statement.run(binds);
  return {
    rows: [],
    rowsAffected: result.changes,
    lastRowid: result.lastInsertRowid,
  };
}

async function connectDatabase() {
  if (isOracle()) {
    await connectOracle();
    return;
  }
  connectSqlite();
}

async function closeDatabase() {
  if (isOracle()) {
    await closeOracle();
    return;
  }
  closeSqlite();
}

async function initialize() {
  await connectDatabase();
}

async function close() {
  await closeDatabase();
}

module.exports = {
  connectDatabase,
  closeDatabase,
  initialize,
  close,
  execute,
  isOracle,
  isSqlite,
  getDriver,
  getActiveClient,
};
