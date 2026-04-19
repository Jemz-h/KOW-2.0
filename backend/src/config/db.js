const { dbMode } = require('./env');
const { connectOracle, closeOracle } = require('./oracle');
const sqliteProvider = require('./providers/sqliteProvider');
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

  return sqliteProvider.execute(sql, binds, opts);
}

async function connectDatabase() {
  if (isOracle()) {
    await connectOracle();
    return;
  }
  await sqliteProvider.initialize();
}

async function closeDatabase() {
  if (isOracle()) {
    await closeOracle();
    return;
  }
  await sqliteProvider.close();
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
