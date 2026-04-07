const fs = require('fs');
const path = require('path');
const oracledb = require('oracledb');

const REQUIRED_TABLES = [
  'STUDENTTB',
  'SCORETB',
  'SUBJECTTB',
  'GRADELVLTB',
  'DIFFTB',
  'BARANGAYTB',
  'SEXTB',
  'TEACHERTB',
  'CUSTOMTB',
  'ANALYTICSTB',
  'TIMEPLTB',
  'PROGRESSTB',
  'QUESTIONTB',
  'CONTENTVERSIONTB',
  'SYNCLOGTB',
  'AUDITTB',
  'DEVICETB',
  'ADMINTB'
];

async function getExistingRequiredTableCount(connection) {
  const bindPlaceholders = REQUIRED_TABLES.map((_, i) => `:t${i}`).join(', ');
  const binds = {};
  REQUIRED_TABLES.forEach((name, i) => {
    binds[`t${i}`] = name;
  });

  const result = await connection.execute(
    `SELECT COUNT(*) AS CNT
     FROM user_tables
     WHERE table_name IN (${bindPlaceholders})`,
    binds
  );

  return Number(result.rows?.[0]?.CNT || 0);
}

function getKowSqlBootstrapSegment(kowSql) {
  const normalized = kowSql.replace(/\r\n/g, '\n');
  const startIndex = normalized.indexOf('-- 2. SEQUENCES');
  const endIndex = normalized.indexOf('-- 15. VERIFY INSTALLATION');

  if (startIndex < 0 || endIndex < 0 || endIndex <= startIndex) {
    throw new Error('Could not locate bootstrap section markers in KOW.sql');
  }

  return normalized.slice(startIndex, endIndex);
}

function startsSlashTerminatedBlock(trimmedUpperLine) {
  return (
    trimmedUpperLine.startsWith('BEGIN') ||
    trimmedUpperLine.startsWith('DECLARE') ||
    trimmedUpperLine.startsWith('CREATE OR REPLACE PROCEDURE') ||
    trimmedUpperLine.startsWith('CREATE OR REPLACE TRIGGER')
  );
}

function parseSqlStatements(segment) {
  const lines = segment.split('\n');
  const statements = [];

  let buffer = [];
  let slashTerminatedBlock = false;

  for (const rawLine of lines) {
    const line = rawLine;
    const trimmed = line.trim();

    if (!trimmed || trimmed.startsWith('--')) {
      continue;
    }

    const trimmedUpper = trimmed.toUpperCase();

    if (!slashTerminatedBlock && startsSlashTerminatedBlock(trimmedUpper)) {
      slashTerminatedBlock = true;
    }

    if (trimmed === '/') {
      const statement = buffer.join('\n').trim();
      if (statement) {
        statements.push(statement);
      }
      buffer = [];
      slashTerminatedBlock = false;
      continue;
    }

    buffer.push(line);

    if (!slashTerminatedBlock && trimmed.endsWith(';')) {
      let statement = buffer.join('\n').trim();
      statement = statement.replace(/;\s*$/, '');
      if (statement) {
        statements.push(statement);
      }
      buffer = [];
    }
  }

  if (buffer.length > 0) {
    const statement = buffer.join('\n').trim().replace(/;\s*$/, '');
    if (statement) {
      statements.push(statement);
    }
  }

  return statements;
}

function getOracleErrorCode(error) {
  if (typeof error?.errorNum === 'number') {
    return error.errorNum;
  }

  const match = String(error?.message || '').match(/ORA-(\d{5})/);
  if (!match) {
    return null;
  }

  return Number(match[1]);
}

function isIgnorableBootstrapError(statement, error) {
  const code = getOracleErrorCode(error);
  const upper = statement.trim().toUpperCase();

  if ((upper.startsWith('CREATE ') || upper.startsWith('CREATE OR REPLACE ')) && code === 955) {
    return true;
  }

  if (upper.startsWith('INSERT ') && code === 1) {
    return true;
  }

  if ((upper.startsWith('CREATE OR REPLACE SYNONYM') || upper.startsWith('CREATE SYNONYM')) && code === 1031) {
    return true;
  }

  return false;
}

async function bootstrapFromKowSql(connection) {
  const existingCount = await getExistingRequiredTableCount(connection);
  if (existingCount === REQUIRED_TABLES.length) {
    return;
  }

  const sqlPath = path.resolve(__dirname, '..', 'KOW.sql');
  const sqlText = fs.readFileSync(sqlPath, 'utf8');
  const segment = getKowSqlBootstrapSegment(sqlText);
  const statements = parseSqlStatements(segment);

  for (const statement of statements) {
    try {
      await connection.execute(statement);
    } catch (error) {
      if (isIgnorableBootstrapError(statement, error)) {
        continue;
      }
      throw error;
    }
  }

  await connection.commit();
}

async function initialize() {
  await oracledb.createPool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    connectString: process.env.DB_CONNECTION_STRING,
    poolMin: 2,
    poolMax: 10,
    poolIncrement: 2
  });

  let connection;
  try {
    connection = await oracledb.getConnection();
    await bootstrapFromKowSql(connection);
  } finally {
    if (connection) {
      await connection.close();
    }
  }
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
