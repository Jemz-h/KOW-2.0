/**
 * setup_backend.js
 * Run once with: node setup_backend.js
 * Creates the backend/ directory tree, writes all source files, then prompts to npm install.
 */
const fs   = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, 'backend');

function write(rel, content) {
  const full = path.join(ROOT, rel);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, content, 'utf8');
  console.log('  created:', path.join('backend', rel));
}

// ─────────────────────────────────────────────────────────
// package.json
// ─────────────────────────────────────────────────────────
write('package.json', JSON.stringify({
  name: 'kow-backend',
  version: '1.0.0',
  description: 'Karunungan On Wheels – Node.js / Oracle backend',
  main: 'server.js',
  scripts: { start: 'node server.js', dev: 'nodemon server.js' },
  dependencies: {
    cors: '^2.8.5',
    dotenv: '^16.4.5',
    express: '^4.19.2',
    oracledb: '^6.5.0',
  },
  devDependencies: { nodemon: '^3.1.4' },
}, null, 2));

// ─────────────────────────────────────────────────────────
// .env.example
// ─────────────────────────────────────────────────────────
write('.env.example', `# Copy this file to .env and fill in your Oracle credentials
DB_USER=kow_user
DB_PASSWORD=your_password
DB_CONNECT_STRING=localhost:1521/XEPDB1
PORT=3000
`);

// ─────────────────────────────────────────────────────────
// .gitignore
// ─────────────────────────────────────────────────────────
write('.gitignore', `node_modules/
.env
`);

// ─────────────────────────────────────────────────────────
// config/db.js
// ─────────────────────────────────────────────────────────
write('config/db.js', `const oracledb = require('oracledb');

// Use OBJECT output format for convenience
oracledb.outFormat = oracledb.OUT_FORMAT_OBJECT;

let pool;

async function initPool() {
  if (pool) return pool;
  pool = await oracledb.createPool({
    user          : process.env.DB_USER,
    password      : process.env.DB_PASSWORD,
    connectString : process.env.DB_CONNECT_STRING,
    poolMin       : 2,
    poolMax       : 10,
    poolIncrement : 1,
  });
  console.log('Oracle connection pool created');
  return pool;
}

async function getConnection() {
  if (!pool) await initPool();
  return pool.getConnection();
}

module.exports = { initPool, getConnection };
`);

// ─────────────────────────────────────────────────────────
// middleware/errorHandler.js
// ─────────────────────────────────────────────────────────
write('middleware/errorHandler.js', `// Central error handler – always release Oracle connections
function errorHandler(err, req, res, next) {
  if (req.dbConn) {
    req.dbConn.close().catch(() => {});
  }
  console.error(err);
  res.status(err.status || 500).json({ error: err.message || 'Internal server error' });
}

module.exports = errorHandler;
`);

// ─────────────────────────────────────────────────────────
// routes/auth.js  – register & login
// ─────────────────────────────────────────────────────────
write('routes/auth.js', `const express = require('express');
const { getConnection } = require('../config/db');

const router = express.Router();

/**
 * POST /api/auth/register
 * Body: { firstName, lastName, nickname, birthday, sex, area }
 */
router.post('/register', async (req, res, next) => {
  const { firstName, lastName, nickname, birthday, sex, area } = req.body;

  if (!firstName || !lastName || !nickname || !birthday || !sex) {
    return res.status(400).json({ error: 'All required fields must be provided.' });
  }

  let conn;
  try {
    conn = await getConnection();

    // Check for duplicate nickname
    const dup = await conn.execute(
      'SELECT COUNT(*) AS cnt FROM kow_students WHERE LOWER(nickname) = LOWER(:1)',
      [nickname],
    );
    if (dup.rows[0].CNT > 0) {
      return res.status(409).json({ error: 'Nickname already taken.' });
    }

    await conn.execute(
      \`INSERT INTO kow_students
         (first_name, last_name, nickname, birthday, sex, area, created_at)
       VALUES (:1, :2, :3, TO_DATE(:4, 'MM/DD/YYYY'), :5, :6, SYSDATE)\`,
      [firstName, lastName, nickname, birthday, sex, area ?? null],
      { autoCommit: true },
    );

    return res.status(201).json({ message: 'Student registered successfully.' });
  } catch (err) {
    next(err);
  } finally {
    if (conn) await conn.close();
  }
});

/**
 * POST /api/auth/login
 * Body: { nickname, birthday }  – birthday is the password
 */
router.post('/login', async (req, res, next) => {
  const { nickname, birthday } = req.body;

  if (!nickname || !birthday) {
    return res.status(400).json({ error: 'Nickname and birthday are required.' });
  }

  let conn;
  try {
    conn = await getConnection();

    const result = await conn.execute(
      \`SELECT student_id, first_name, last_name, nickname, sex, area, total_score
         FROM kow_students
        WHERE LOWER(nickname) = LOWER(:1)
          AND TO_CHAR(birthday, 'MM/DD/YYYY') = :2\`,
      [nickname, birthday],
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid nickname or birthday.' });
    }

    return res.json({ student: result.rows[0] });
  } catch (err) {
    next(err);
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
`);

// ─────────────────────────────────────────────────────────
// routes/quiz.js  – questions & score submission
// ─────────────────────────────────────────────────────────
write('routes/quiz.js', `const express = require('express');
const { getConnection } = require('../config/db');

const router = express.Router();

/**
 * GET /api/quiz/questions?grade=PUNLA&subject=MATH&difficulty=EASY
 */
router.get('/questions', async (req, res, next) => {
  const { grade, subject, difficulty } = req.query;
  if (!grade || !subject || !difficulty) {
    return res.status(400).json({ error: 'grade, subject, and difficulty are required.' });
  }

  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      \`SELECT question_id, question_number, image_path, prompt,
              word_type, sub_prompt, fun_fact,
              choice_a, choice_b, choice_c, choice_d, correct_index
         FROM kow_questions
        WHERE grade = :1 AND subject = :2 AND difficulty = :3
        ORDER BY question_number\`,
      [grade, subject, difficulty],
    );
    return res.json({ questions: result.rows });
  } catch (err) {
    next(err);
  } finally {
    if (conn) await conn.close();
  }
});

/**
 * POST /api/quiz/score
 * Body: { studentId, grade, subject, difficulty, score, total }
 */
router.post('/score', async (req, res, next) => {
  const { studentId, grade, subject, difficulty, score, total } = req.body;
  if (!studentId || !grade || !subject || !difficulty || score == null || !total) {
    return res.status(400).json({ error: 'All score fields are required.' });
  }

  let conn;
  try {
    conn = await getConnection();

    await conn.execute(
      \`INSERT INTO kow_scores
         (student_id, grade, subject, difficulty, score, total, taken_at)
       VALUES (:1, :2, :3, :4, :5, :6, SYSDATE)\`,
      [studentId, grade, subject, difficulty, score, total],
      { autoCommit: true },
    );

    // Update cumulative total_score on the student record
    await conn.execute(
      'UPDATE kow_students SET total_score = total_score + :1 WHERE student_id = :2',
      [score, studentId],
      { autoCommit: true },
    );

    return res.status(201).json({ message: 'Score saved.' });
  } catch (err) {
    next(err);
  } finally {
    if (conn) await conn.close();
  }
});

/**
 * GET /api/quiz/scores/:studentId
 */
router.get('/scores/:studentId', async (req, res, next) => {
  let conn;
  try {
    conn = await getConnection();
    const result = await conn.execute(
      \`SELECT grade, subject, difficulty, score, total,
              TO_CHAR(taken_at, 'YYYY-MM-DD HH24:MI:SS') AS taken_at
         FROM kow_scores
        WHERE student_id = :1
        ORDER BY taken_at DESC\`,
      [req.params.studentId],
    );
    return res.json({ scores: result.rows });
  } catch (err) {
    next(err);
  } finally {
    if (conn) await conn.close();
  }
});

module.exports = router;
`);

// ─────────────────────────────────────────────────────────
// server.js
// ─────────────────────────────────────────────────────────
write('server.js', `require('dotenv').config();
const express      = require('express');
const cors         = require('cors');
const { initPool } = require('./config/db');
const authRoutes   = require('./routes/auth');
const quizRoutes   = require('./routes/quiz');
const errorHandler = require('./middleware/errorHandler');

const app  = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ── Routes ─────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/quiz', quizRoutes);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// ── Error handler (must be last) ───────────────────────
app.use(errorHandler);

// ── Start ──────────────────────────────────────────────
initPool()
  .then(() => {
    app.listen(PORT, () => console.log(\`KOW backend running on port \${PORT}\`));
  })
  .catch(err => {
    console.error('Failed to initialize Oracle pool:', err);
    process.exit(1);
  });
`);

// ─────────────────────────────────────────────────────────
// sql/schema.sql
// ─────────────────────────────────────────────────────────
write('sql/schema.sql', `-- ============================================================
-- KOW Oracle Schema
-- Run as the kow_user (or a DBA) after creating the schema user
-- ============================================================

-- Students table
CREATE TABLE kow_students (
  student_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name  VARCHAR2(100)  NOT NULL,
  last_name   VARCHAR2(100)  NOT NULL,
  nickname    VARCHAR2(80)   NOT NULL UNIQUE,
  birthday    DATE           NOT NULL,
  sex         VARCHAR2(10)   NOT NULL,
  area        VARCHAR2(200),
  total_score NUMBER         DEFAULT 0,
  created_at  DATE           DEFAULT SYSDATE
);

-- Questions table
CREATE TABLE kow_questions (
  question_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  grade           VARCHAR2(20)  NOT NULL,  -- PUNLA, BINHI
  subject         VARCHAR2(20)  NOT NULL,  -- MATH, SCIENCE, READING, WRITING
  difficulty      VARCHAR2(10)  NOT NULL,  -- EASY, AVERAGE, HARD
  question_number VARCHAR2(20)  NOT NULL,
  image_path      VARCHAR2(300),
  prompt          VARCHAR2(500),
  word_type       VARCHAR2(100),
  sub_prompt      VARCHAR2(500),
  fun_fact        VARCHAR2(500) NOT NULL,
  choice_a        VARCHAR2(200) NOT NULL,
  choice_b        VARCHAR2(200) NOT NULL,
  choice_c        VARCHAR2(200) NOT NULL,
  choice_d        VARCHAR2(200) NOT NULL,
  correct_index   NUMBER(1)     NOT NULL   -- 0=A, 1=B, 2=C, 3=D
);

-- Scores table
CREATE TABLE kow_scores (
  score_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  student_id  NUMBER        NOT NULL REFERENCES kow_students(student_id),
  grade       VARCHAR2(20)  NOT NULL,
  subject     VARCHAR2(20)  NOT NULL,
  difficulty  VARCHAR2(10)  NOT NULL,
  score       NUMBER        NOT NULL,
  total       NUMBER        NOT NULL,
  taken_at    DATE          DEFAULT SYSDATE
);

-- ── Seed: sample questions ─────────────────────────────
INSERT INTO kow_questions
  (grade, subject, difficulty, question_number, image_path, prompt, fun_fact,
   choice_a, choice_b, choice_c, choice_d, correct_index)
VALUES
  ('PUNLA','SCIENCE','EASY','QUESTION 1',
   'assets/grade_select/sun.png', 'WHAT''S IN THE PICTURE?',
   'THE SUN IS THE CENTER OF OUR SOLAR SYSTEM.',
   'MOON','DOG','SUN','CAT', 2);

INSERT INTO kow_questions
  (grade, subject, difficulty, question_number, image_path, prompt, fun_fact,
   choice_a, choice_b, choice_c, choice_d, correct_index)
VALUES
  ('PUNLA','SCIENCE','EASY','QUESTION 2',
   'assets/grade_select/moon.png', 'WHAT''S IN THE PICTURE?',
   'THE MOON ORBITS THE EARTH EVERY 27 DAYS.',
   'SUN','MOON','STAR','CAT', 1);

INSERT INTO kow_questions
  (grade, subject, difficulty, question_number, prompt, word_type, sub_prompt, fun_fact,
   choice_a, choice_b, choice_c, choice_d, correct_index)
VALUES
  ('PUNLA','READING','AVERAGE','QUESTION 1',
   'FEELING OR SHOWING PLEASURE OR CONTENTMENT.',
   '- ADJECTIVE -',
   'WHAT IS THE WORD DESCRIBED IN THE STATEMENT?',
   'AN ADJECTIVE IS A DESCRIBING OR MODIFYING A WORD.',
   'HAPPY','SURPRISE','SAD','SLEEPY', 0);

COMMIT;
`);

// ─────────────────────────────────────────────────────────
// README.md for backend
// ─────────────────────────────────────────────────────────
write('README.md', `# KOW Backend

Node.js + Express REST API backed by Oracle Database.

## Setup

\`\`\`bash
cd backend
cp .env.example .env        # fill in your Oracle credentials
npm install
npm run dev                  # development (nodemon)
npm start                    # production
\`\`\`

## Environment variables

| Variable          | Example                   | Description           |
|-------------------|---------------------------|-----------------------|
| DB_USER           | kow_user                  | Oracle schema user    |
| DB_PASSWORD       | secret                    | Oracle password       |
| DB_CONNECT_STRING | localhost:1521/XEPDB1     | Easy Connect string   |
| PORT              | 3000                      | HTTP port             |

## Endpoints

| Method | Path                          | Description              |
|--------|-------------------------------|--------------------------|
| POST   | /api/auth/register            | Register a new student   |
| POST   | /api/auth/login               | Login (nickname+birthday)|
| GET    | /api/quiz/questions           | Fetch questions          |
| POST   | /api/quiz/score               | Submit quiz score        |
| GET    | /api/quiz/scores/:studentId   | Get student scores       |
| GET    | /health                       | Health check             |
`);

console.log('\n✅  Backend files created under backend/');
console.log('Next steps:');
console.log('  1. cd backend');
console.log('  2. cp .env.example .env   (fill in Oracle credentials)');
console.log('  3. npm install');
console.log('  4. Run sql/schema.sql against your Oracle DB');
console.log('  5. npm run dev');
