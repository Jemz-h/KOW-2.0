require('dotenv').config();

const oracleProvider = require('./providers/oracleProvider');
const sqliteProvider = require('./providers/sqliteProvider');

const configuredClient = (process.env.DB_CLIENT || 'sqlite').toLowerCase();
const allowFallback = (process.env.DB_FALLBACK_SQLITE || 'true').toLowerCase() !== 'false';

let activeClient = configuredClient;
let provider = configuredClient === 'sqlite' ? sqliteProvider : oracleProvider;

function setProvider(clientName) {
  activeClient = clientName;
  provider = clientName === 'sqlite' ? sqliteProvider : oracleProvider;
}

async function initialize() {
  try {
    await provider.initialize();
    console.log(`Database provider initialized: ${activeClient}`);
  } catch (error) {
    console.error(`Error initializing ${activeClient} database provider:`, error.message);

    if (activeClient === 'oracle' && allowFallback) {
      console.warn('Falling back to SQLite provider for offline mode');
      setProvider('sqlite');
      await provider.initialize();
      console.log('Database provider initialized: sqlite (fallback)');
      return;
    }

    throw error;
  }
}

async function execute(sql, binds = [], opts = {}) {
  try {
    return await provider.execute(sql, binds, opts);
  } catch (error) {
    console.error('Database execution error:', error.message);
    throw error;
  }
}

async function close() {
  await provider.close();
}

function isOracle() {
  return activeClient === 'oracle';
}

function isSqlite() {
  return activeClient === 'sqlite';
}

function getDriver() {
  return provider.driver;
}

async function closePoolAndExit() {
  console.log('\nClosing database provider');
  try {
    await close();
    console.log('Database provider closed');
    process.exit(0);
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }
}

process.once('SIGTERM', closePoolAndExit).once('SIGINT', closePoolAndExit);

module.exports = {
  initialize,
  execute,
  close,
  isOracle,
  isSqlite,
  getDriver,
  client: activeClient
};
