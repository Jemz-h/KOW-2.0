const fs = require('fs');
const path = require('path');
const oracledb = require('oracledb');

const REQUIRED_TABLES = [
  'STUDENTTB',
  'SCORETB',
  'SUBJECTTB',
  'GRADELVLTB',
  'DIFFTB',
  'AREATB',
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

const AREA_SEED_VALUES = [
  [1, 'LAW STREET'],
  [2, 'KIMCO VILLAGE'],
  [3, 'WALING-WALING STREET'],
  [4, 'VICTORIA SUBDIVISION'],
  [5, 'SAMPAGUITA STREET'],
  [6, 'DRJ VILLAGE'],
  [7, 'LOWER SAUYO'],
  [8, 'SPAZIO BERNARDO CONDOMINIUM'],
  [9, 'VICTORIA STREET'],
  [10, 'RICHLAND SUBDIVISION'],
  [11, 'PASCUAL STREET'],
  [12, 'GREENVILLE SUBDIVISION'],
  [13, 'TEODORO COMPOUND'],
  [14, 'DEL NACIA VILLE 4'],
  [15, 'AREA 85'],
  [16, 'NIA VILLAGE'],
  [17, 'AREA 99'],
  [18, 'OCEAN PARK'],
  [19, 'AREA 135'],
  [20, 'GREENVIEW ROYALE'],
  [21, 'BISTEKVILLE 15'],
  [22, 'GREENVIEW EXECUTIVE'],
  [23, 'MARIAN EXTENSION'],
  [24, 'BIR VILLAGE'],
  [25, 'MARIAN SUBDIVISION'],
  [26, 'VICTORIAN HEIGHTS'],
  [27, 'MOZART EXTENSION'],
  [28, 'VILLA HERMANO 1'],
  [29, 'COMMERCIO'],
  [30, 'VILLA HERMANO 2'],
  [31, 'UPPER GULOD'],
  [32, 'PRIVADA HOMES'],
  [33, 'LOWER GULOD'],
  [34, 'MERRY HOMES'],
  [35, 'AREA 169'],
  [36, 'ATHERTON'],
  [37, 'AREA 160-168'],
  [38, 'LAGKITAN'],
  [39, 'DEL MUNDO COMPOUND'],
  [40, 'HERMINIGILDO COMPOUND'],
  [41, 'MABUHAY COMPOUND'],
  [42, 'AREA 5A'],
  [43, 'AREA 5B'],
  [44, 'AREA 6A'],
  [45, 'NAVAL'],
  [46, 'VILLA ROSARIO'],
  [47, 'LIPTON STREET'],
  [48, 'OLD CABUYAO'],
  [49, 'BALUYOT 1'],
  [50, 'BALUYOT 2A'],
  [51, 'BALUYOT 2B'],
  [52, 'MONTINOLA'],
  [53, 'BALUYOT PARK'],
  [54, 'PAPELAN'],
  [55, 'DAANG NAWASA']
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

async function tableExists(connection, tableName) {
  const result = await connection.execute(
    `SELECT COUNT(*) AS CNT
     FROM user_tables
     WHERE table_name = :tableName`,
    { tableName },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  return Number(result.rows?.[0]?.CNT || 0) > 0;
}

async function columnExists(connection, tableName, columnName) {
  const result = await connection.execute(
    `SELECT COUNT(*) AS CNT
     FROM user_tab_columns
     WHERE table_name = :tableName
       AND column_name = :columnName`,
    { tableName, columnName },
    { outFormat: oracledb.OUT_FORMAT_OBJECT }
  );

  return Number(result.rows?.[0]?.CNT || 0) > 0;
}

async function ensureAreaCompatibility(connection) {
  const areaTableExists = await tableExists(connection, 'AREATB');
  if (!areaTableExists) {
    await connection.execute(
      `CREATE TABLE areaTb (
         area_id NUMBER(5) PRIMARY KEY,
         area_nm VARCHAR2(60) NOT NULL
       )`
    );

    for (const [areaId, areaName] of AREA_SEED_VALUES) {
      await connection.execute(
        `INSERT INTO areaTb (area_id, area_nm)
         SELECT :areaId, :areaName
         FROM DUAL
         WHERE NOT EXISTS (
           SELECT 1 FROM areaTb WHERE area_id = :areaId
         )`,
        { areaId, areaName },
        { autoCommit: false }
      );
    }
  }

  const studentAreaColumnExists = await columnExists(connection, 'STUDENTTB', 'AREA_ID');
  if (!studentAreaColumnExists) {
    await connection.execute(
      `ALTER TABLE studentTb ADD (area_id NUMBER(5) DEFAULT 1)`
    );
    await connection.execute(
      `UPDATE studentTb
       SET area_id = 1
       WHERE area_id IS NULL`
    );
  }

  await connection.commit();
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
    await ensureAreaCompatibility(connection);
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
