const oracledb = require('oracledb');

async function initialize() {
  await oracledb.createPool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECTION_STRING,
    poolMin: 2,
    poolMax: 10,
    poolIncrement: 2
  });
}

async function execute(sql, binds = [], opts = {}) {
  let connection;

  try {
    connection = await oracledb.getConnection();
    const executeOptions = {
      outFormat: oracledb.OUT_FORMAT_OBJECT,
      ...opts
    };

    return await connection.execute(sql, binds, executeOptions);
  } finally {
    if (connection) {
      await connection.close();
    }
  }
}

async function close() {
  try {
    const pool = oracledb.getPool();
    await pool.close(10);
  } catch (error) {
    if (!String(error.message || '').includes('NJS-047')) {
      throw error;
    }
  }
}

module.exports = {
  initialize,
  execute,
  close,
  driver: oracledb
};
