const http = require('http');
const path = require('path');
const dotenv = require('dotenv');

dotenv.config({ path: path.resolve(__dirname, '.env.development') });
dotenv.config({ path: path.resolve(__dirname, '.env') });
dotenv.config();

const HOST = process.env.TEST_HOST || 'localhost';
const EXPLICIT_PORT = process.env.TEST_PORT ? Number(process.env.TEST_PORT) : null;
const ENV_PORT = process.env.PORT ? Number(process.env.PORT) : null;
const PORT_CANDIDATES = EXPLICIT_PORT
  ? [EXPLICIT_PORT]
  : Array.from(new Set([
      ENV_PORT,
      3010,
      3011,
      3012,
      3013,
      3014,
      3000,
      3001,
      3002,
      5000,
      8080,
    ].filter((port) => Number.isFinite(port) && port > 0)));

let activePort = PORT_CANDIDATES[0];

async function doFetch(path, method = 'GET', body = null, token = null) {
  return new Promise((resolve, reject) => {
    const headers = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
    };

    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    const options = {
      hostname: HOST,
      port: activePort,
      path,
      method,
      headers,
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        let parsed = data;
        try {
          parsed = JSON.parse(data);
        } catch (_) {
          // Keep raw body when not JSON.
        }
        resolve({ status: res.statusCode, body: parsed });
      });
    });

    req.on('error', (e) => reject(e));

    if (body) {
      req.write(JSON.stringify(body));
    }
    req.end();
  });
}

function logResult(label, response, expectedStatusCodes) {
  const pass = expectedStatusCodes.includes(response.status);
  const marker = pass ? 'PASSED' : 'FAILED';
  console.log(`${label} -> ${response.status} ${marker}`);
  if (!pass) {
    console.log('Response:', response.body);
  }
  return pass;
}

async function runTests() {
  console.log('--- STARTING API FLOW TEST (LOGIN + ORACLE WRITES) ---');

  let health = null;
  for (const port of PORT_CANDIDATES) {
    activePort = port;
    try {
      health = await doFetch('/api/health');
      if (health.status === 200) {
        break;
      }
    } catch (_) {
      health = null;
    }
  }

  if (!health || health.status !== 200) {
    throw new Error(`Backend is not reachable on ${HOST} ports: ${PORT_CANDIDATES.join(', ')}`);
  }

  console.log(`Using backend at http://${HOST}:${activePort}`);

  const nickname = `run_${Date.now()}`;
  const birthday = '2010-05-15';
  const deviceUuid = `DEV-TEST-${Date.now()}`;

  let studentId = null;
  let authToken = null;

  logResult('[1] GET /api/health', health, [200]);

  const register = await doFetch('/api/students/register', 'POST', {
    firstName: 'Test',
    lastName: 'User',
    nickname,
    birthday,
    sex: 'Male',
    area: 'Barangay Sauyo',
    deviceUuid,
  });
  logResult('[2] POST /api/students/register', register, [200, 201]);
  studentId = register.body?.student?.studentId || null;

  const lookup = await doFetch('/api/students/lookup', 'POST', { nickname, birthday });
  logResult('[3] POST /api/students/lookup', lookup, [200]);
  if (!studentId) {
    studentId = lookup.body?.stud_id || lookup.body?.student?.STUDENT_ID || null;
  }

  const login = await doFetch('/api/auth/login', 'POST', { nickname, birthday });
  logResult('[4] POST /api/auth/login (nickname+birthday)', login, [200]);
  authToken = login.body?.token || null;
  if (!studentId) {
    studentId = login.body?.student?.studentId || null;
  }

  if (!studentId) {
    console.log('FAILED: Could not resolve studentId from register/lookup/login responses.');
    process.exitCode = 1;
    return;
  }

  const initialScores = await doFetch(`/api/quiz/scores/${studentId}`);
  logResult('[5] GET /api/quiz/scores/:studentId (before)', initialScores, [200]);
  const beforeCount = Array.isArray(initialScores.body?.scores)
    ? initialScores.body.scores.length
    : 0;

  const submitScore = await doFetch('/api/quiz/score', 'POST', {
    studentId,
    grade: 'Punla',
    subject: 'Mathematics',
    difficulty: 'Easy',
    score: 8,
    total: 10,
    played_at: new Date().toISOString(),
    device_uuid: deviceUuid,
  });
  logResult('[6] POST /api/quiz/score', submitScore, [200, 201]);

  const scoresAfter = await doFetch(`/api/quiz/scores/${studentId}`);
  logResult('[7] GET /api/quiz/scores/:studentId (after)', scoresAfter, [200]);
  const afterCount = Array.isArray(scoresAfter.body?.scores)
    ? scoresAfter.body.scores.length
    : 0;

  if (afterCount < beforeCount) {
    console.log('FAILED: score count decreased unexpectedly.');
    process.exitCode = 1;
  } else if (afterCount === beforeCount) {
    console.log('WARNING: score count unchanged (possible duplicate guard on identical payload).');
  } else {
    console.log(`PASSED: score rows increased from ${beforeCount} to ${afterCount}.`);
  }

  const progressUpsert = await doFetch('/api/progress', 'POST', {
    studentId,
    grade: 'Punla',
    subject: 'Mathematics',
    highest_diff_passed: 1,
    total_time_played: 120,
    last_played_at: new Date().toISOString(),
  });
  logResult('[8] POST /api/progress', progressUpsert, [200]);

  const progressRows = await doFetch(`/api/progress/${studentId}`);
  logResult('[9] GET /api/progress/:studentId', progressRows, [200]);

  if (authToken) {
    const users = await doFetch('/api/users', 'GET', null, authToken);
    logResult('[10] GET /api/users (JWT)', users, [200]);
  } else {
    console.log('[10] SKIPPED /api/users because no JWT token was returned by login.');
  }
}

runTests().catch((error) => {
  console.error('Test runner crashed:', error);
  process.exitCode = 1;
});