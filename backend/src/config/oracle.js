const oracledb = require('oracledb');
const { oracle } = require('./env');

let pool;

async function connectOracle() {
  if (pool) return pool;
  pool = await oracledb.createPool({
    user: oracle.user,
    password: oracle.password,
    connectString: oracle.connectString,
    poolMin: 1,
    poolMax: 5,
    poolIncrement: 1,
  });
  return pool;
}

async function withOracleConnection(work) {
  if (!pool) await connectOracle();
  const connection = await pool.getConnection();
  try {
    return await work(connection);
  } finally {
    await connection.close();
  }
}

async function closeOracle() {
  if (pool) {
    await pool.close(0);
    pool = null;
  }
}

module.exports = {
  connectOracle,
  withOracleConnection,
  closeOracle,
};
