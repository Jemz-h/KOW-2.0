const path = require('path');
const dotenv = require('dotenv');

dotenv.config();

module.exports = {
  port: Number(process.env.PORT || 5000),
  dbMode: (process.env.DB_MODE || 'offline').toLowerCase(),
  jwtSecret: process.env.JWT_SECRET || 'dev_secret_change_me',
  oracle: {
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectString: process.env.ORACLE_CONNECT_STRING,
  },
  sqlitePath: process.env.SQLITE_PATH
    ? path.resolve(process.cwd(), process.env.SQLITE_PATH)
    : path.resolve(process.cwd(), 'src/db/sqlite/kow_offline.db'),
};
