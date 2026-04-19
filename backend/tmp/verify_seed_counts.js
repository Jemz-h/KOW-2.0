const Database = require('better-sqlite3');
const db = new Database('c:/Users/Administrator/Desktop/2E KOW/KOW-True/assets/seed/kow_offline.db', { readonly: true });

const total = db.prepare('SELECT COUNT(*) AS c FROM questionTb').get().c;
const byGradeSubject = db
  .prepare(`
    SELECT UPPER(g.gradelvl) AS grade,
           UPPER(s.subject) AS subject,
           UPPER(d.difficulty) AS difficulty,
           COUNT(*) AS count
    FROM questionTb q
    JOIN gradelvlTb g ON g.gradelvl_id = q.gradelvl_id
    JOIN subjectTb s ON s.subject_id = q.subject_id
    JOIN diffTb d ON d.diff_id = q.diff_id
    GROUP BY grade, subject, difficulty
    ORDER BY grade, subject, difficulty
  `)
  .all();

console.log('asset_total_questions=' + total);
console.table(byGradeSubject);

db.close();
