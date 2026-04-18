const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

const rawDbMode = (
  process.env.DB_MODE ||
  process.env.DB_CLIENT ||
  'offline'
).toLowerCase();

function normalizeDbMode(mode) {
  if (mode === 'online' || mode === 'oracle') {
    return 'online';
  }
  if (mode === 'offline' || mode === 'sqlite') {
    return 'offline';
  }
  return 'offline';
}

const resolvedDbMode = normalizeDbMode(rawDbMode);

const resolvedJwtSecret =
  process.env.JWT_SECRET ||
  process.env.TOKEN_SECRET ||
  'dev_secret_change_me';

module.exports = {
  port: Number(process.env.PORT || 5000),
  dbMode: resolvedDbMode,
  jwtSecret: resolvedJwtSecret,
  oracle: {
    user: process.env.ORACLE_USER || process.env.DB_USER,
    password: process.env.ORACLE_PASSWORD || process.env.DB_PASSWORD,
    connectString: process.env.ORACLE_CONNECT_STRING || process.env.DB_CONNECTION_STRING,
  },
  sqlitePath: (process.env.SQLITE_PATH || process.env.SQLITE_DB_PATH)
    ? path.resolve(process.cwd(), process.env.SQLITE_PATH || process.env.SQLITE_DB_PATH)
    : path.resolve(process.cwd(), 'src/db/sqlite/kow_offline.db'),
};
