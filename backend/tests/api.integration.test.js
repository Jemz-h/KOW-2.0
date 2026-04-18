const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const path = require('node:path');
const fs = require('node:fs');

const testDbPath = path.resolve(__dirname, '..', 'data', 'kow_test.db');
process.env.NODE_ENV = 'test';
process.env.DB_CLIENT = 'sqlite';
process.env.DB_FALLBACK_SQLITE = 'false';
process.env.SQLITE_DB_PATH = testDbPath;
process.env.ADMIN_SEED_PASSWORD = 'admin123';
process.env.TOKEN_SECRET = 'kow-test-secret';

const db = require('../src/config/db');
const { createApp } = require('../src/app');

let server;
let baseUrl;

async function request(method, route, body, token) {
  const response = await fetch(`${baseUrl}${route}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });

  let json = null;
  try {
    json = await response.json();
  } catch (_) {
    json = null;
  }

  return { status: response.status, json };
}

test.before(async () => {
  fs.mkdirSync(path.dirname(testDbPath), { recursive: true });
  if (fs.existsSync(testDbPath)) {
    fs.unlinkSync(testDbPath);
  }

  await db.initialize();
  const app = createApp();

  server = http.createServer(app);
  await new Promise((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();
  baseUrl = `http://127.0.0.1:${address.port}`;
});

test.after(async () => {
  if (server) {
    await new Promise((resolve, reject) => {
      server.close((error) => (error ? reject(error) : resolve()));
    });
  }
  await db.close();
  if (fs.existsSync(testDbPath)) {
    fs.unlinkSync(testDbPath);
  }
});

test('device registration returns device token', async () => {
  const res = await request('POST', '/api/auth/device/register', {
    device_uuid: 'DEV-TEST-001',
    device_name: 'Integration Test Device',
  });

  assert.equal(res.status, 200);
  assert.equal(res.json?.success, true);
  assert.equal(typeof res.json?.token, 'string');
  assert.equal(res.json?.device?.deviceUuid, 'DEV-TEST-001');
});

test('admin login accepts seeded admin credentials', async () => {
  const res = await request('POST', '/api/auth/admin/login', {
    username: 'admin',
    password: 'admin123',
  });

  assert.equal(res.status, 200);
  assert.equal(res.json?.success, true);
  assert.equal(typeof res.json?.token, 'string');
  assert.equal(res.json?.role, 'admin');
});

test('content endpoint returns version contract fields', async () => {
  const deviceAuth = await request('POST', '/api/auth/device/register', {
    device_uuid: 'DEV-TEST-002',
    device_name: 'Content Contract Device',
  });

  const token = deviceAuth.json?.token;
  assert.ok(token);

  const initial = await request('GET', '/api/content', undefined, token);
  assert.equal(initial.status, 200);
  assert.equal(typeof initial.json?.version_tag, 'string');
  assert.equal(typeof initial.json?.up_to_date, 'boolean');

  const sinceVersion = initial.json?.version_tag;
  const followUp = await request('GET', `/api/content?sinceVersion=${encodeURIComponent(sinceVersion)}`, undefined, token);

  assert.equal(followUp.status, 200);
  assert.equal(followUp.json?.success, true);
  assert.equal(followUp.json?.up_to_date, true);
  assert.equal(followUp.json?.version_tag, sinceVersion);
});

test('sync endpoint processes offline registration and returns temp-id mapping', async () => {
  const deviceAuth = await request('POST', '/api/auth/device/register', {
    device_uuid: 'DEV-TEST-REG-001',
    device_name: 'Offline Registration Device',
  });

  const token = deviceAuth.json?.token;
  assert.ok(token);

  const tmpStudId = 'TMP-OFFLINE-001';
  const syncBody = {
    device_id: 'DEV-TEST-REG-001',
    batches: [
      {
        stud_id: tmpStudId,
        events: [
          {
            event_type: 'register',
            payload: {
              first_name: 'Offline',
              last_name: 'Student',
              nickname: 'offline_student_nick',
              birthday: '2013-02-03',
              sex: 'Female',
              tmp_local_id: tmpStudId,
            },
          },
        ],
      },
    ],
  };

  const syncRes = await request('POST', '/api/sync', syncBody, token);
  assert.equal(syncRes.status, 200);
  assert.equal(syncRes.json?.success, true);

  const mappings = syncRes.json?.id_mappings || [];
  assert.equal(Array.isArray(mappings), true);
  assert.equal(mappings.length, 1);
  assert.equal(mappings[0]?.tmp_id, tmpStudId);
  assert.equal(typeof mappings[0]?.real_id, 'string');

  const studentLookup = await db.execute(
    `SELECT stud_id
     FROM studentTb
     WHERE nickname = :nickname
       AND birthday = :birthday`,
    {
      nickname: 'offline_student_nick',
      birthday: '2013-02-03',
    }
  );

  assert.equal(studentLookup.rows.length, 1);
});

test('sync endpoint is idempotent for duplicate score replay', async () => {
  const deviceAuth = await request('POST', '/api/auth/device/register', {
    device_uuid: 'DEV-TEST-003',
    device_name: 'Sync Replay Device',
  });

  const token = deviceAuth.json?.token;
  assert.ok(token);

  const studId = 'TMP-12345';
  const playedAt = '2026-04-07T10:00:00.000Z';

  const syncBody = {
    device_id: 'DEV-TEST-003',
    batches: [
      {
        stud_id: studId,
        events: [
          {
            event_type: 'register',
            payload: {
              first_name: 'Replay',
              last_name: 'Tester',
              nickname: 'replay_nick',
              birthday: '2011-03-04',
              sex: 'Male',
              tmp_local_id: studId,
            },
          },
          {
            event_type: 'score',
            payload: {
              subject: 'Mathematics',
              grade: 'Punla',
              difficulty: 'Easy',
              score: 8,
              max_score: 10,
              played_at: playedAt,
            },
          },
        ],
      },
    ],
  };

  const firstSync = await request('POST', '/api/sync', syncBody, token);
  assert.equal(firstSync.status, 200);
  assert.equal(firstSync.json?.success, true);

  const mappings = firstSync.json?.id_mappings || [];
  assert.equal(mappings.length, 1);
  assert.equal(mappings[0]?.tmp_id, studId);

  const mappedRealId = String(mappings[0]?.real_id || '').replace('STU-', '');
  const mappedRealNumericId = Number(mappedRealId);
  assert.equal(Number.isNaN(mappedRealNumericId), false);

  const secondSync = await request('POST', '/api/sync', syncBody, token);
  assert.equal(secondSync.status, 200);
  assert.equal(secondSync.json?.success, true);

  const countRes = await db.execute(
    `SELECT COUNT(*) AS CNT
     FROM scoreTb
     WHERE played_at = :playedAt
       AND device_uuid = :deviceUuid`,
    {
      playedAt,
      deviceUuid: 'DEV-TEST-003',
    }
  );

  const scoreCount = Number(countRes.rows[0]?.CNT || 0);
  assert.equal(scoreCount, 1);

  const mappedCountRes = await db.execute(
    `SELECT COUNT(*) AS CNT
     FROM scoreTb
     WHERE stud_id = :studId
       AND played_at = :playedAt
       AND device_uuid = :deviceUuid`,
    {
      studId: mappedRealNumericId,
      playedAt,
      deviceUuid: 'DEV-TEST-003',
    }
  );

  const mappedScoreCount = Number(mappedCountRes.rows[0]?.CNT || 0);
  assert.equal(mappedScoreCount, 1);
});

test('progress endpoint is idempotent for duplicate last_played_at events', async () => {
  const deviceAuth = await request('POST', '/api/auth/device/register', {
    device_uuid: 'DEV-TEST-004',
    device_name: 'Progress Replay Device',
  });
  const token = deviceAuth.json?.token;
  assert.ok(token);

  const register = await request('POST', '/api/students/register', {
    firstName: 'Progress',
    lastName: 'Tester',
    nickname: 'progress_nick',
    birthday: '2012-06-07',
    sex: 'Male',
    device_uuid: 'DEV-TEST-004',
  }, token);
  assert.equal(register.status, 201);

  const studentId = register.json?.student?.studentId;
  assert.equal(typeof studentId, 'number');

  const payload = {
    studentId,
    subject: 'Mathematics',
    grade: 'Punla',
    highest_diff_passed: 1,
    total_time_played: 120,
    last_played_at: '2026-04-07T11:00:00.000Z',
  };

  const first = await request('POST', '/api/progress', payload);
  assert.equal(first.status, 201);

  const second = await request('POST', '/api/progress', payload);
  assert.equal(second.status, 200);
  assert.equal(second.json?.duplicate, true);

  const progressRow = await db.execute(
    `SELECT COUNT(*) AS CNT,
            COALESCE(SUM(total_time_played), 0) AS TOTAL_TIME
     FROM progressTb
     WHERE stud_id = :studentId
       AND subject_id = 1
       AND gradelvl_id = 1`,
    { studentId }
  );

  const count = Number(progressRow.rows[0]?.CNT || 0);
  const totalTime = Number(progressRow.rows[0]?.TOTAL_TIME || 0);

  assert.equal(count, 1);
  assert.equal(totalTime, 120);
});
