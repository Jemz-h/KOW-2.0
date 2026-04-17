const { dbMode } = require('./env');
const { connectOracle, closeOracle } = require('./oracle');
const { connectSqlite, closeSqlite } = require('./sqlite');

async function connectDatabase() {
  if (dbMode === 'online') {
    await connectOracle();
    return;
  }
  connectSqlite();
}

async function closeDatabase() {
  if (dbMode === 'online') {
    await closeOracle();
    return;
  }
  closeSqlite();
}

module.exports = {
  connectDatabase,
  closeDatabase,
};
