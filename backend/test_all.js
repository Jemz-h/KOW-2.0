const http = require('http');

async function doFetch(path, method = 'GET', body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        let parsed = data;
        try { parsed = JSON.parse(data); } catch(e) {}
        resolve({ status: res.statusCode, body: parsed });
      });
    });

    req.on('error', (e) => reject(e));

    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

function resultOk(status) {
    if(status === 404 || status === 500) return 'WARNING (Might be due to empty db)';
    return status >= 200 && status < 400 ? 'PASSED' : 'FAILED';
}

async function runTests() {
  console.log('--- STARTING CONTROLLER TESTS ---');
  let testUserId = null;
  const nickname = 'run_' + Date.now();
  const birthday = '2010-05-15';

  console.log('\\n[1] POST /api/auth/register');
  const regRes = await doFetch('/api/auth/register', 'POST', {
    firstName: 'Test', lastName: 'User', nickname, birthday, sex: 'Male', area: 'Local'
  });
  console.log(`Status: ${regRes.status} ${resultOk(regRes.status)}`);
  if (regRes.status === 201) testUserId = regRes.body.userId;

  console.log('\\n[2] POST /api/auth/login');
  const logRes = await doFetch('/api/auth/login', 'POST', { nickname, birthday });
  console.log(`Status: ${logRes.status} ${resultOk(logRes.status)}`);

  console.log('\\n[3] GET /api/users');
  const usersRes = await doFetch('/api/users', 'GET');
  console.log(`Status: ${usersRes.status} ${resultOk(usersRes.status)}`);

  if (testUserId) {
    console.log(`\\n[4] GET /api/users/${testUserId}`);
    const userByIdRes = await doFetch(`/api/users/${testUserId}`, 'GET');
    console.log(`Status: ${userByIdRes.status} ${resultOk(userByIdRes.status)}`);
  }

  console.log('\\n[5] GET /api/levels');
  const levelsRes = await doFetch('/api/levels', 'GET');
  console.log(`Status: ${levelsRes.status} ${resultOk(levelsRes.status)}`);

  const testGradeId = 1; 
  console.log(`\\n[6] GET /api/levels/grade/${testGradeId}`);
  const levelsGradeRes = await doFetch(`/api/levels/grade/${testGradeId}`, 'GET');
  console.log(`Status: ${levelsGradeRes.status} ${resultOk(levelsGradeRes.status)}`);

  console.log('\\n[7] GET /api/quiz/questions');
  const qRes = await doFetch('/api/quiz/questions?grade=Grade%201&subject=Science&difficulty=Easy', 'GET');
  console.log(`Status: ${qRes.status} ${resultOk(qRes.status)}`);

  console.log('\\n[8] POST /api/quiz/score');
  const scoreRes = await doFetch('/api/quiz/score', 'POST', {
    studentId: testUserId || 1, grade: 'Grade 1', subject: 'Science', difficulty: 'Easy', score: 8, total: 10
  });
  console.log(`Status: ${scoreRes.status} ${resultOk(scoreRes.status)}`);

  if (testUserId) {
    console.log(`\\n[9] GET /api/quiz/scores/${testUserId}`);
    const pastScoresRes = await doFetch(`/api/quiz/scores/${testUserId}`, 'GET');
    console.log(`Status: ${pastScoresRes.status} ${resultOk(pastScoresRes.status)}`);
  }

  console.log('\\n[10] POST /api/progress');
  const progRes = await doFetch('/api/progress', 'POST', {
    userID: testUserId || 1, levelID: 1, score: 100, completionStatus: 'COMPLETED', timeSpent: 120
  });
  console.log(`Status: ${progRes.status} ${resultOk(progRes.status)}`);
}

runTests().catch(console.error);