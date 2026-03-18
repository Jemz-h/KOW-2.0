const oracledb = require('oracledb');
require('dotenv').config();

async function initialize() {
  try {
    await oracledb.createPool({
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      connectString: process.env.DB_CONNECTION_STRING,
      poolMin: 2,
      poolMax: 10,
      poolIncrement: 2
    });
    console.log('Oracle Database pool created successfully');
  } catch (err) {
    console.error('Error creating Oracle Database pool:', err.message);
    process.exit(1); // Fail fast if db connection fails on startup
  }
}

/**
 * Utility function to execute a SQL statement. 
 * This abstracts away connection management across all controllers.
 * 
 * @param {string} sql - The raw SQL statement
 * @param {Array|Object} binds - Bind variables for the statement
 * @param {Object} opts - Additional oracledb execution options
 * @returns {Promise<Object>} The execution result
 */
async function execute(sql, binds = [], opts = {}) {
  let connection;
  try {
    connection = await oracledb.getConnection();
    opts.outFormat = oracledb.OUT_FORMAT_OBJECT; // Consistently return objects, not arrays of arrays
    
    const result = await connection.execute(sql, binds, opts);
    return result;
  } catch (err) {
    console.error('Database execution error:', err.message);
    throw err; // Re-throw to be caught by the route's error handler
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error('Error closing connection:', err.message);
      }
    }
  }
}

async function closePoolAndExit() {
  console.log('\nClosing Database pool');
  try {
    await oracledb.getPool().close(10);
    console.log('Pool closed');
    process.exit(0);
  } catch (err) {
    console.error(err.message);
    process.exit(1);
  }
}

process.once('SIGTERM', closePoolAndExit).once('SIGINT', closePoolAndExit);

module.exports = { initialize, execute };
